import 'package:drift/drift.dart';

import '../../dates/date_keys.dart';
import '../../models/models.dart';
import '../database.dart';
import '../errors.dart';
import '../tables.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets, Transactions, Transfers, Subscriptions])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  Stream<List<WalletBalance>> watchBalances({bool activeOnly = true}) {
    final where = activeOnly ? 'WHERE w.archived_at IS NULL' : '';
    final query =
        '''
SELECT w.*,
  w.opening_balance
  + COALESCE((SELECT SUM(CASE WHEN t.kind = 'income' THEN t.amount ELSE -t.amount END)
      FROM transactions t WHERE t.wallet_id = w.id), 0)
  + COALESCE((SELECT SUM(tr.amount) FROM transfers tr
      WHERE tr.destination_wallet_id = w.id), 0)
  - COALESCE((SELECT SUM(tr.amount + tr.fee) FROM transfers tr
      WHERE tr.source_wallet_id = w.id), 0)
  AS balance
FROM wallets w
$where
ORDER BY w.sort_order, w.id
''';
    return customSelect(
      query,
      readsFrom: {wallets, transactions, transfers},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => WalletBalance(
              wallet: wallets.map(row.data),
              balance: row.read<int>('balance'),
            ),
          )
          .toList(),
    );
  }

  Stream<List<Wallet>> watchAll() => (select(
    wallets,
  )..orderBy([(w) => OrderingTerm.asc(w.sortOrder)])).watch();

  Stream<Wallet?> watchById(int id) =>
      (select(wallets)..where((w) => w.id.equals(id))).watchSingleOrNull();

  Future<List<Wallet>> all() =>
      (select(wallets)..orderBy([(w) => OrderingTerm.asc(w.sortOrder)])).get();

  Future<List<Wallet>> active() =>
      (select(wallets)
            ..where((w) => w.archivedAt.isNull())
            ..orderBy([(w) => OrderingTerm.asc(w.sortOrder)]))
          .get();

  Future<Wallet?> byId(int id) =>
      (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<int> activeCount() async {
    final count = countAll();
    final row =
        await (selectOnly(wallets)
              ..addColumns([count])
              ..where(wallets.archivedAt.isNull()))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<bool> nameExists(String name, {int? exceptId}) async {
    final normalized = name.trim().toLowerCase();
    final rows = await (select(
      wallets,
    )..where((w) => w.archivedAt.isNull())).get();
    return rows.any(
      (w) => w.id != exceptId && w.name.trim().toLowerCase() == normalized,
    );
  }

  Future<int> currentBalance(int walletId) async {
    final row = await customSelect(
      '''
SELECT COALESCE((
  SELECT w.opening_balance
  FROM wallets w WHERE w.id = ?
), 0)
+ COALESCE((SELECT SUM(CASE WHEN t.kind = 'income' THEN t.amount ELSE -t.amount END)
    FROM transactions t WHERE t.wallet_id = ?), 0)
+ COALESCE((SELECT SUM(tr.amount) FROM transfers tr
    WHERE tr.destination_wallet_id = ?), 0)
- COALESCE((SELECT SUM(tr.amount + tr.fee) FROM transfers tr
    WHERE tr.source_wallet_id = ?), 0) AS balance
''',
      variables: [
        Variable.withInt(walletId),
        Variable.withInt(walletId),
        Variable.withInt(walletId),
        Variable.withInt(walletId),
      ],
      readsFrom: {wallets, transactions, transfers},
    ).getSingle();
    return row.read<int>('balance');
  }

  Future<int> createWallet({
    required String name,
    required WalletType type,
    required int openingBalance,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final trimmed = name.trim();
    if (await nameExists(trimmed)) {
      throw const DomainError(ErrorCodes.duplicateName);
    }
    final now = DateTime.now();
    final nextOrder = await _nextSortOrder();
    return into(wallets).insert(
      WalletsCompanion.insert(
        name: trimmed,
        type: type.storageValue,
        openingBalance: Value(openingBalance),
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
        sortOrder: Value(nextOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateWallet({
    required int id,
    required String name,
    required WalletType type,
    required int openingBalance,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final trimmed = name.trim();
    if (await nameExists(trimmed, exceptId: id)) {
      throw const DomainError(ErrorCodes.duplicateName);
    }
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        name: Value(trimmed),
        type: Value(type.storageValue),
        openingBalance: Value(openingBalance),
        iconCodePoint: Value(iconCodePoint),
        colorValue: Value(colorValue),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> archiveWallet(int id) async {
    final active = await activeCount();
    final wallet = await byId(id);
    if (wallet == null) {
      return;
    }
    if (wallet.archivedAt == null && active <= 1) {
      throw const DomainError(ErrorCodes.lastWallet);
    }
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        archivedAt: Value(todayKey()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> unarchiveWallet(int id) async {
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(
        archivedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteWallet(int id) async {
    if (await hasHistory(id)) {
      throw const DomainError(ErrorCodes.walletHasHistory);
    }
    await (delete(wallets)..where((w) => w.id.equals(id))).go();
  }

  Future<bool> hasHistory(int id) async {
    final transactionCount = countAll();
    final transactionRow =
        await (selectOnly(transactions)
              ..addColumns([transactionCount])
              ..where(transactions.walletId.equals(id)))
            .getSingle();
    if ((transactionRow.read(transactionCount) ?? 0) > 0) {
      return true;
    }

    final outgoing = countAll();
    final incoming = countAll();
    final transferRow =
        await (selectOnly(transfers)
              ..addColumns([outgoing, incoming])
              ..where(
                transfers.sourceWalletId.equals(id) |
                    transfers.destinationWalletId.equals(id),
              ))
            .getSingle();
    if ((transferRow.read(outgoing) ?? 0) > 0 ||
        (transferRow.read(incoming) ?? 0) > 0) {
      return true;
    }

    final subscriptionCount = countAll();
    final subscriptionRow =
        await (selectOnly(subscriptions)
              ..addColumns([subscriptionCount])
              ..where(subscriptions.walletId.equals(id)))
            .getSingle();
    return (subscriptionRow.read(subscriptionCount) ?? 0) > 0;
  }

  Future<int> _nextSortOrder() async {
    final maxOrder = wallets.sortOrder.max();
    final row = await (selectOnly(wallets)..addColumns([maxOrder])).getSingle();
    return (row.read(maxOrder) ?? 0) + 1;
  }
}
