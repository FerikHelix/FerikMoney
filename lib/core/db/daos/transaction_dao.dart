import 'package:drift/drift.dart';

import '../../dates/date_keys.dart';
import '../../models/models.dart';
import '../../money/rupiah.dart';
import '../database.dart';
import '../errors.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Transfers, Categories, Wallets])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Category>> watchCategories({
    CategoryKind? kind,
    bool activeOnly = true,
  }) {
    final query = select(categories);
    if (kind != null) {
      query.where((c) => c.kind.equals(kind.storageValue));
    }
    if (activeOnly) {
      query.where((c) => c.archivedAt.isNull());
    }
    query.orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch();
  }

  Future<List<Category>> listCategories({
    CategoryKind? kind,
    bool activeOnly = true,
  }) async {
    final query = select(categories);
    if (kind != null) {
      query.where((c) => c.kind.equals(kind.storageValue));
    }
    if (activeOnly) {
      query.where((c) => c.archivedAt.isNull());
    }
    query.orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.get();
  }

  Future<Category?> categoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> createCategory({
    required String name,
    required CategoryKind kind,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final trimmed = name.trim();
    final existing = await listCategories(kind: kind);
    if (existing.any(
      (c) => c.name.trim().toLowerCase() == trimmed.toLowerCase(),
    )) {
      throw const DomainError(ErrorCodes.duplicateName);
    }
    final maxOrder = categories.sortOrder.max();
    final row = await (selectOnly(
      categories,
    )..addColumns([maxOrder])).getSingle();
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: trimmed,
        kind: kind.storageValue,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        sortOrder: Value((row.read(maxOrder) ?? 0) + 1),
      ),
    );
  }

  Future<void> renameCategory(int id, String name) async {
    final category = await categoryById(id);
    if (category == null || category.isSystem) {
      return;
    }
    final trimmed = name.trim();
    final existing = await listCategories(
      kind: CategoryKind.parse(category.kind),
    );
    if (existing.any(
      (c) => c.id != id && c.name.trim().toLowerCase() == trimmed.toLowerCase(),
    )) {
      throw const DomainError(ErrorCodes.duplicateName);
    }
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(name: Value(trimmed)),
    );
  }

  Future<void> archiveCategory(int id) async {
    final category = await categoryById(id);
    if (category == null || category.isSystem) {
      return;
    }
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(archivedAt: Value(todayKey())),
    );
  }

  Stream<List<TransactionEntry>> watchTransactions({
    int? walletId,
    String? fromDate,
    String? toDate,
    int? limit,
  }) {
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (walletId != null) {
      query.where((t) => t.walletId.equals(walletId));
    }
    if (fromDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.date.isSmallerThanValue(toDate));
    }
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch();
  }

  Future<TransactionEntry?> transactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<TransactionEntry?> lastTransactionOfKind(CategoryKind kind) =>
      (select(transactions)
            ..where((t) => t.kind.equals(kind.storageValue))
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<int> createTransaction({
    required CategoryKind kind,
    required int amount,
    required int walletId,
    required int categoryId,
    required String date,
    String note = '',
  }) async {
    _validateTransaction(
      amount: amount,
      date: date,
      walletId: walletId,
      categoryId: categoryId,
    );
    final category = await categoryById(categoryId);
    if (category == null || category.kind != kind.storageValue) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    final now = DateTime.now();
    return into(transactions).insert(
      TransactionsCompanion.insert(
        kind: kind.storageValue,
        amount: amount,
        walletId: walletId,
        categoryId: categoryId,
        date: date,
        note: Value(note.trim()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTransaction({
    required int id,
    required CategoryKind kind,
    required int amount,
    required int walletId,
    required int categoryId,
    required String date,
    String note = '',
  }) async {
    _validateTransaction(
      amount: amount,
      date: date,
      walletId: walletId,
      categoryId: categoryId,
    );
    final category = await categoryById(categoryId);
    if (category == null || category.kind != kind.storageValue) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        kind: Value(kind.storageValue),
        amount: Value(amount),
        walletId: Value(walletId),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<TransferEntry>> watchTransfers({int? walletId, int? limit}) {
    final query = select(transfers)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (walletId != null) {
      query.where(
        (t) =>
            t.sourceWalletId.equals(walletId) |
            t.destinationWalletId.equals(walletId),
      );
    }
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch();
  }

  Future<TransferEntry?> transferById(int id) =>
      (select(transfers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createTransfer({
    required int sourceWalletId,
    required int destinationWalletId,
    required int amount,
    required int fee,
    required String date,
    String note = '',
  }) async {
    _validateTransfer(
      sourceWalletId: sourceWalletId,
      destinationWalletId: destinationWalletId,
      amount: amount,
      fee: fee,
      date: date,
    );
    final now = DateTime.now();
    return into(transfers).insert(
      TransfersCompanion.insert(
        sourceWalletId: sourceWalletId,
        destinationWalletId: destinationWalletId,
        amount: amount,
        fee: Value(fee),
        date: date,
        note: Value(note.trim()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTransfer({
    required int id,
    required int sourceWalletId,
    required int destinationWalletId,
    required int amount,
    required int fee,
    required String date,
    String note = '',
  }) async {
    _validateTransfer(
      sourceWalletId: sourceWalletId,
      destinationWalletId: destinationWalletId,
      amount: amount,
      fee: fee,
      date: date,
    );
    await (update(transfers)..where((t) => t.id.equals(id))).write(
      TransfersCompanion(
        sourceWalletId: Value(sourceWalletId),
        destinationWalletId: Value(destinationWalletId),
        amount: Value(amount),
        fee: Value(fee),
        date: Value(date),
        note: Value(note.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTransfer(int id) async {
    await (delete(transfers)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ActivityItem>> watchRecentActivity({
    int limit = 10,
    int? walletId,
  }) {
    final walletFilter = walletId == null ? '' : 'AND wallet_id = $walletId';
    final sql =
        '''
SELECT 'transaction' AS row_type, t.id, t.kind, t.amount, t.date, t.note,
       t.wallet_id, w.name AS wallet_name, c.name AS counterpart,
       c.icon_code_point AS icon_code_point
FROM transactions t
JOIN wallets w ON w.id = t.wallet_id
JOIN categories c ON c.id = t.category_id
WHERE 1 = 1 $walletFilter
UNION ALL
SELECT 'transfer' AS row_type, tr.id, 'transfer', tr.amount, tr.date, tr.note,
       tr.source_wallet_id, sw.name AS wallet_name, dw.name AS counterpart,
       0 AS icon_code_point
FROM transfers tr
JOIN wallets sw ON sw.id = tr.source_wallet_id
JOIN wallets dw ON dw.id = tr.destination_wallet_id
WHERE 1 = 1 ${walletId == null ? '' : 'AND (tr.source_wallet_id = $walletId OR tr.destination_wallet_id = $walletId)'}
ORDER BY date DESC, id DESC
LIMIT ?
''';
    return customSelect(
      sql,
      variables: [Variable.withInt(limit)],
      readsFrom: {transactions, transfers, wallets, categories},
    ).watch().map(
      (rows) => rows.map((row) {
        final isTransfer = row.read<String>('row_type') == 'transfer';
        final kindValue = row.read<String>('kind');
        final kind = isTransfer
            ? ActivityKind.transfer
            : kindValue == 'income'
            ? ActivityKind.income
            : ActivityKind.expense;
        return ActivityItem(
          id: row.read<int>('id'),
          kind: kind,
          amount: row.read<int>('amount'),
          date: row.read<String>('date'),
          walletName: row.read<String>('wallet_name'),
          title: row.read<String>('counterpart'),
          iconCodePoint: row.read<int>('icon_code_point'),
          note: row.read<String>('note'),
          isTransfer: isTransfer,
        );
      }).toList(),
    );
  }

  void _validateTransaction({
    required int amount,
    required String date,
    required int walletId,
    required int categoryId,
  }) {
    if (amount <= 0) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (amount > maxTransactionAmount) {
      throw const DomainError(ErrorCodes.amountTooLarge);
    }
    if (isAfterToday(parseDateKey(date))) {
      throw const DomainError(ErrorCodes.futureDate);
    }
  }

  void _validateTransfer({
    required int sourceWalletId,
    required int destinationWalletId,
    required int amount,
    required int fee,
    required String date,
  }) {
    if (sourceWalletId == destinationWalletId) {
      throw const DomainError(ErrorCodes.sameWallet);
    }
    if (amount <= 0 || fee < 0) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (amount > maxTransactionAmount || fee > maxTransactionAmount) {
      throw const DomainError(ErrorCodes.amountTooLarge);
    }
    if (isAfterToday(parseDateKey(date))) {
      throw const DomainError(ErrorCodes.futureDate);
    }
  }
}
