// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_dao.dart';

// ignore_for_file: type=lint
mixin _$WalletDaoMixin on DatabaseAccessor<AppDatabase> {
  $WalletsTable get wallets => attachedDatabase.wallets;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $TransfersTable get transfers => attachedDatabase.transfers;
  $SubscriptionsTable get subscriptions => attachedDatabase.subscriptions;
  WalletDaoManager get managers => WalletDaoManager(this);
}

class WalletDaoManager {
  final _$WalletDaoMixin _db;
  WalletDaoManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db.attachedDatabase, _db.wallets);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db.attachedDatabase, _db.transfers);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db.attachedDatabase, _db.subscriptions);
}
