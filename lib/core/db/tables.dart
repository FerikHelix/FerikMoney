import 'package:drift/drift.dart';

@TableIndex(name: 'wallets_name', columns: {#name})
@DataClassName('Wallet')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => text()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get archivedAt => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'categories_kind', columns: {#kind})
@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get kind => text()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  TextColumn get archivedAt => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@TableIndex(name: 'transactions_wallet_date', columns: {#walletId, #date})
@TableIndex(name: 'transactions_category_date', columns: {#categoryId, #date})
@TableIndex(name: 'transactions_date', columns: {#date})
@DataClassName('TransactionEntry')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  IntColumn get amount => integer()();
  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get date => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'transfers_source_date', columns: {#sourceWalletId, #date})
@TableIndex(
  name: 'transfers_destination_date',
  columns: {#destinationWalletId, #date},
)
@TableIndex(name: 'transfers_date', columns: {#date})
@DataClassName('TransferEntry')
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceWalletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  IntColumn get destinationWalletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  IntColumn get amount => integer()();
  IntColumn get fee => integer().withDefault(const Constant(0))();
  TextColumn get date => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'subscriptions_due', columns: {#nextDueDate})
@DataClassName('SubscriptionEntry')
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get amount => integer()();
  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get cycle => text()();
  IntColumn get anchorDay => integer()();
  IntColumn get anchorMonth => integer().nullable()();
  IntColumn get leadDays => integer().withDefault(const Constant(3))();
  TextColumn get nextDueDate => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'debt_entries_direction_due', columns: {#direction, #dueDate})
@TableIndex(
  name: 'debt_entries_principal_transaction',
  columns: {#principalTransactionId},
  unique: true,
)
@DataClassName('DebtEntry')
class DebtEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get direction => text()();
  TextColumn get counterparty => text().withLength(min: 1, max: 80)();
  IntColumn get principal => integer()();
  TextColumn get startDate => text()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get principalTransactionId => integer().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@TableIndex(name: 'debt_payments_debt', columns: {#debtId})
@TableIndex(
  name: 'debt_payments_transaction',
  columns: {#transactionId},
  unique: true,
)
@DataClassName('DebtPayment')
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId =>
      integer().references(DebtEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()();
  TextColumn get date => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get transactionId => integer().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
