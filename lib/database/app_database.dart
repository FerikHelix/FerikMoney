import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/backup_data.dart';

part 'app_database.g.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text()();
  IntColumn get initialBalance => integer()();
  TextColumn get icon => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text()();
  TextColumn get icon => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MoneyTransaction')
class MoneyTransactions extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  @ReferenceName('sourceAccountTransactions')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('destinationAccountTransactions')
  TextColumn get destinationAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AccountWithBalance {
  const AccountWithBalance({required this.account, required this.balance});

  final Account account;
  final int balance;
}

class MonthlySummary {
  const MonthlySummary({required this.income, required this.expense});

  final int income;
  final int expense;
  int get net => income - expense;
}

@DriftDatabase(tables: [Accounts, Categories, MoneyTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedDefaultCategories();
    },
    // Add versioned migration steps here when schemaVersion is increased.
    onUpgrade: (migrator, from, to) async {},
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static const _expenseCategories = <(String, String, String)>[
    ('expense-food', 'Makan', 'restaurant'),
    ('expense-transport', 'Transport', 'directions_car'),
    ('expense-shopping', 'Belanja', 'shopping_bag'),
    ('expense-bills', 'Tagihan', 'receipt_long'),
    ('expense-entertainment', 'Hiburan', 'movie'),
    ('expense-health', 'Kesehatan', 'health_and_safety'),
    ('expense-hobby', 'Hobi', 'sports_esports'),
    ('expense-other', 'Lainnya', 'more_horiz'),
  ];

  static const _incomeCategories = <(String, String, String)>[
    ('income-salary', 'Gaji', 'payments'),
    ('income-bonus', 'Bonus', 'stars'),
    ('income-freelance', 'Freelance', 'work'),
    ('income-gift', 'Hadiah', 'card_giftcard'),
    ('income-other', 'Lainnya', 'more_horiz'),
  ];

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();
    await batch((batch) {
      for (final item in _expenseCategories) {
        batch.insert(
          categories,
          CategoriesCompanion.insert(
            id: item.$1,
            name: item.$2,
            type: 'expense',
            icon: item.$3,
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final item in _incomeCategories) {
        batch.insert(
          categories,
          CategoriesCompanion.insert(
            id: item.$1,
            name: item.$2,
            type: 'income',
            icon: item.$3,
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Stream<List<AccountWithBalance>> watchAccountsWithBalances() {
    return customSelect(
      '''
      SELECT a.*,
        a.initial_balance + COALESCE(SUM(
          CASE
            WHEN t.type = 'income' AND t.account_id = a.id THEN t.amount
            WHEN t.type = 'expense' AND t.account_id = a.id THEN -t.amount
            WHEN t.type = 'transfer' AND t.account_id = a.id THEN -t.amount
            WHEN t.type = 'transfer' AND t.destination_account_id = a.id THEN t.amount
            ELSE 0
          END
        ), 0) AS current_balance
      FROM accounts a
      LEFT JOIN transactions t
        ON t.account_id = a.id OR t.destination_account_id = a.id
      GROUP BY a.id
      ORDER BY a.created_at ASC
      ''',
      readsFrom: {accounts, moneyTransactions},
    ).watch().map(
      (rows) => rows.map((row) {
        final account = Account(
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          type: row.read<String>('type'),
          initialBalance: row.read<int>('initial_balance'),
          icon: row.read<String>('icon'),
          createdAt: row.read<DateTime>('created_at'),
          updatedAt: row.read<DateTime>('updated_at'),
        );
        return AccountWithBalance(
          account: account,
          balance: row.read<int>('current_balance'),
        );
      }).toList(),
    );
  }

  Stream<List<MoneyTransaction>> watchAllTransactions() => (select(
    moneyTransactions,
  )..orderBy([(row) => OrderingTerm.desc(row.transactionDate)])).watch();

  Stream<List<Category>> watchAllCategories() => (select(
    categories,
  )..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  Future<List<Account>> getAllAccounts() => select(accounts).get();
  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<List<MoneyTransaction>> getAllTransactions() =>
      select(moneyTransactions).get();

  Future<int> totalBalance() async {
    final rows = await watchAccountsWithBalances().first;
    return rows.fold<int>(0, (total, item) => total + item.balance);
  }

  Future<int> accountBalance(String accountId) async {
    final rows = await watchAccountsWithBalances().first;
    return rows
        .where((item) => item.account.id == accountId)
        .map((item) => item.balance)
        .first;
  }

  Future<MonthlySummary> monthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final row = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {moneyTransactions},
    ).getSingle();
    return MonthlySummary(
      income: row.read<int>('income'),
      expense: row.read<int>('expense'),
    );
  }

  Future<void> restoreBackup(BackupData backup) async {
    await transaction(() async {
      await delete(moneyTransactions).go();
      await delete(categories).go();
      await delete(accounts).go();
      await batch((batch) {
        batch.insertAll(
          accounts,
          backup.accounts
              .map(
                (item) => AccountsCompanion.insert(
                  id: item.id,
                  name: item.name,
                  type: item.type,
                  initialBalance: item.initialBalance,
                  icon: item.icon,
                  createdAt: item.createdAt,
                  updatedAt: item.updatedAt,
                ),
              )
              .toList(),
        );
        batch.insertAll(
          categories,
          backup.categories
              .map(
                (item) => CategoriesCompanion.insert(
                  id: item.id,
                  name: item.name,
                  type: item.type,
                  icon: item.icon,
                  createdAt: item.createdAt,
                ),
              )
              .toList(),
        );
        batch.insertAll(
          moneyTransactions,
          backup.transactions
              .map(
                (item) => MoneyTransactionsCompanion.insert(
                  id: item.id,
                  type: item.type,
                  amount: item.amount,
                  accountId: item.accountId,
                  destinationAccountId: Value(item.destinationAccountId),
                  categoryId: Value(item.categoryId),
                  note: Value(item.note),
                  transactionDate: item.transactionDate,
                  createdAt: item.createdAt,
                  updatedAt: item.updatedAt,
                ),
              )
              .toList(),
        );
      });
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'ferikmoney.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
