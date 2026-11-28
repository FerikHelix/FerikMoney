import 'package:drift/drift.dart';

import '../../dates/date_keys.dart';
import '../../models/models.dart';
import '../../money/rupiah.dart';
import '../database.dart';
import '../errors.dart';
import '../tables.dart';

part 'debt_dao.g.dart';

@DriftAccessor(tables: [DebtEntries, DebtPayments, Transactions, Wallets])
class DebtDao extends DatabaseAccessor<AppDatabase> with _$DebtDaoMixin {
  DebtDao(super.db);

  Stream<List<DebtStatus>> watchStatuses() async* {
    yield await loadStatuses();
    await for (final _ in db.tableUpdates(
      TableUpdateQuery.onAllTables([debtEntries, debtPayments, transactions]),
    )) {
      yield await loadStatuses();
    }
  }

  Future<List<DebtStatus>> loadStatuses() async {
    final entries =
        await (select(debtEntries)..orderBy([
              (e) => OrderingTerm.desc(e.startDate),
              (e) => OrderingTerm.desc(e.id),
            ]))
            .get();
    final payments = await (select(
      debtPayments,
    )..orderBy([(p) => OrderingTerm.asc(p.date)])).get();
    final grouped = <int, List<DebtPayment>>{};
    for (final payment in payments) {
      grouped.putIfAbsent(payment.debtId, () => []).add(payment);
    }
    final today = todayKey();
    return [
      for (final entry in entries)
        _statusFor(entry, grouped[entry.id] ?? const [], today: today),
    ];
  }

  Future<DebtStatus?> statusById(int id) async {
    final entry = await (select(
      debtEntries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (entry == null) {
      return null;
    }
    final payments =
        await (select(debtPayments)
              ..where((p) => p.debtId.equals(id))
              ..orderBy([(p) => OrderingTerm.asc(p.date)]))
            .get();
    return _statusFor(entry, payments, today: todayKey());
  }

  Future<DebtSummary> summary() async {
    final statuses = await loadStatuses();
    var utang = 0;
    var piutang = 0;
    for (final status in statuses) {
      if (status.remaining <= 0) {
        continue;
      }
      if (status.isUtang) {
        utang += status.remaining;
      } else {
        piutang += status.remaining;
      }
    }
    return DebtSummary(totalUtang: utang, totalPiutang: piutang);
  }

  Future<int> createEntry({
    required String direction,
    required String counterparty,
    required int principal,
    required String startDate,
    String? dueDate,
    String note = '',
    int? commitWalletId,
    int? commitCategoryId,
  }) async {
    _validateEntry(
      direction: direction,
      counterparty: counterparty,
      principal: principal,
      startDate: startDate,
      dueDate: dueDate,
    );
    final shouldCommit = commitWalletId != null && commitCategoryId != null;
    if (shouldCommit) {
      await _requireActiveWallet(commitWalletId);
    }
    return db.transaction(() async {
      int? transactionId;
      if (shouldCommit) {
        transactionId = await db.transactionDao.createTransaction(
          kind: direction == 'utang'
              ? CategoryKind.income
              : CategoryKind.expense,
          amount: principal,
          walletId: commitWalletId,
          categoryId: commitCategoryId,
          date: startDate,
          note: counterparty.trim(),
        );
      }
      final now = DateTime.now();
      return into(debtEntries).insert(
        DebtEntriesCompanion.insert(
          direction: direction,
          counterparty: counterparty.trim(),
          principal: principal,
          startDate: startDate,
          dueDate: Value(dueDate),
          note: Value(note.trim()),
          principalTransactionId: Value(transactionId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  Future<void> recordPayment({
    required int debtId,
    required int amount,
    required String date,
    String note = '',
    int? commitWalletId,
    int? commitCategoryId,
  }) async {
    final status = await statusById(debtId);
    if (status == null) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (amount <= 0 || amount > maxTransactionAmount) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (isAfterToday(parseDateKey(date))) {
      throw const DomainError(ErrorCodes.futureDate);
    }
    if (amount > status.remaining) {
      throw DomainError(ErrorCodes.overpayment, status.remaining);
    }
    final shouldCommit = commitWalletId != null && commitCategoryId != null;
    if (shouldCommit) {
      await _requireActiveWallet(commitWalletId);
    }

    await db.transaction(() async {
      int? transactionId;
      if (shouldCommit) {
        transactionId = await db.transactionDao.createTransaction(
          kind: status.isUtang ? CategoryKind.expense : CategoryKind.income,
          amount: amount,
          walletId: commitWalletId,
          categoryId: commitCategoryId,
          date: date,
          note: status.entry.counterparty,
        );
      }
      await into(debtPayments).insert(
        DebtPaymentsCompanion.insert(
          debtId: debtId,
          amount: amount,
          date: date,
          note: Value(note.trim()),
          transactionId: Value(transactionId),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> commitPrincipal({
    required int debtId,
    required int walletId,
    required int categoryId,
  }) async {
    final status = await statusById(debtId);
    if (status == null) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (status.isCommitted) {
      throw const DomainError(ErrorCodes.alreadyCommitted);
    }
    await _requireActiveWallet(walletId);
    await db.transaction(() async {
      final transactionId = await db.transactionDao.createTransaction(
        kind: status.isUtang ? CategoryKind.income : CategoryKind.expense,
        amount: status.entry.principal,
        walletId: walletId,
        categoryId: categoryId,
        date: status.entry.startDate,
        note: status.entry.counterparty,
      );
      await (update(debtEntries)..where((e) => e.id.equals(debtId))).write(
        DebtEntriesCompanion(
          principalTransactionId: Value(transactionId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> commitPayment({
    required int paymentId,
    required int walletId,
    required int categoryId,
  }) async {
    final payment = await (select(
      debtPayments,
    )..where((p) => p.id.equals(paymentId))).getSingleOrNull();
    if (payment == null || payment.transactionId != null) {
      throw const DomainError(ErrorCodes.alreadyCommitted);
    }
    final status = await statusById(payment.debtId);
    if (status == null) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    await _requireActiveWallet(walletId);
    await db.transaction(() async {
      final transactionId = await db.transactionDao.createTransaction(
        kind: status.isUtang ? CategoryKind.expense : CategoryKind.income,
        amount: payment.amount,
        walletId: walletId,
        categoryId: categoryId,
        date: payment.date,
        note: status.entry.counterparty,
      );
      await (update(debtPayments)..where((p) => p.id.equals(paymentId))).write(
        DebtPaymentsCompanion(transactionId: Value(transactionId)),
      );
    });
  }

  Future<void> deleteEntry(int id) async {
    await (delete(debtEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<void> _requireActiveWallet(int id) async {
    final wallet = await db.walletDao.byId(id);
    if (wallet == null || wallet.archivedAt != null) {
      throw const DomainError(ErrorCodes.noWallet);
    }
  }

  DebtStatus _statusFor(
    DebtEntry entry,
    List<DebtPayment> payments, {
    required String today,
  }) {
    final paid = payments.fold<int>(0, (sum, payment) => sum + payment.amount);
    final remaining = entry.principal - paid;
    final isOverdue =
        remaining > 0 &&
        entry.dueDate != null &&
        entry.dueDate!.compareTo(today) < 0;
    return DebtStatus(
      entry: entry,
      paid: paid,
      remaining: remaining < 0 ? 0 : remaining,
      isSettled: remaining <= 0,
      isOverdue: isOverdue,
      payments: payments,
    );
  }

  void _validateEntry({
    required String direction,
    required String counterparty,
    required int principal,
    required String startDate,
    String? dueDate,
  }) {
    if (direction != 'utang' && direction != 'piutang') {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (counterparty.trim().isEmpty) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (principal <= 0 || principal > maxTransactionAmount) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (isAfterToday(parseDateKey(startDate))) {
      throw const DomainError(ErrorCodes.futureDate);
    }
    if (dueDate != null && dueDate.compareTo(startDate) < 0) {
      throw const DomainError(ErrorCodes.futureDate);
    }
  }
}
