// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_dao.dart';

// ignore_for_file: type=lint
mixin _$DebtDaoMixin on DatabaseAccessor<AppDatabase> {
  $WalletsTable get wallets => attachedDatabase.wallets;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $DebtEntriesTable get debtEntries => attachedDatabase.debtEntries;
  $DebtPaymentsTable get debtPayments => attachedDatabase.debtPayments;
  DebtDaoManager get managers => DebtDaoManager(this);
}

class DebtDaoManager {
  final _$DebtDaoMixin _db;
  DebtDaoManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db.attachedDatabase, _db.wallets);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$DebtEntriesTableTableManager get debtEntries =>
      $$DebtEntriesTableTableManager(_db.attachedDatabase, _db.debtEntries);
  $$DebtPaymentsTableTableManager get debtPayments =>
      $$DebtPaymentsTableTableManager(_db.attachedDatabase, _db.debtPayments);
}
