import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/backup_data.dart';
import '../utils/balance_adjustment.dart';

part 'app_database.g.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text()();
  IntColumn get initialBalance => integer()();
  TextColumn get icon => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text()();
  TextColumn get icon => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

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

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get normalizedName => text().withLength(min: 1, max: 40)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {normalizedName},
  ];
}

class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(MoneyTransactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, tagId};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  IntColumn get amount => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  @ReferenceName('sourceAccountRecurringRules')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('destinationAccountRecurringRules')
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
  TextColumn get frequency => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueAt => dateTime()();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RecurringRuleTags extends Table {
  TextColumn get ruleId =>
      text().references(RecurringRules, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {ruleId, tagId};
}

class RecurringOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId =>
      text().references(RecurringRules, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get status => text()();
  TextColumn get transactionId => text().nullable().references(
    MoneyTransactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {ruleId, dueAt},
  ];
}

class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get targetAmount => integer()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SavingsGoalTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get goalId =>
      text().references(SavingsGoals, #id, onDelete: KeyAction.restrict)();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transferDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

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

class SavingsGoalWithProgress {
  const SavingsGoalWithProgress({required this.goal, required this.saved});

  final SavingsGoal goal;
  final int saved;
}

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    MoneyTransactions,
    Tags,
    TransactionTags,
    Budgets,
    RecurringRules,
    RecurringRuleTags,
    RecurringOccurrences,
    SavingsGoals,
    SavingsGoalTransfers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedDefaultCategories();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(accounts, accounts.isArchived);
        await migrator.addColumn(categories, categories.isArchived);
        await migrator.createTable(tags);
        await migrator.createTable(transactionTags);
        await migrator.createTable(budgets);
        await migrator.createTable(recurringRules);
        await migrator.createTable(recurringRuleTags);
        await migrator.createTable(recurringOccurrences);
        await migrator.createTable(savingsGoals);
        await migrator.createTable(savingsGoalTransfers);
        await _seedDefaultCategories();
      }
    },
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
    ('expense-education', 'Pendidikan', 'school'),
    ('expense-family', 'Keluarga', 'family_restroom'),
    ('expense-personal', 'Personal', 'person'),
    ('expense-hobby', 'Hobi', 'sports_esports'),
    ('expense-other', 'Lainnya', 'more_horiz'),
  ];

  static const _incomeCategories = <(String, String, String)>[
    ('income-salary', 'Gaji', 'payments'),
    ('income-bonus', 'Bonus', 'stars'),
    ('income-freelance', 'Freelance', 'work'),
    ('income-gift', 'Hadiah', 'card_giftcard'),
    ('income-investment', 'Investasi', 'trending_up'),
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
        a.initial_balance
        + COALESCE((
          SELECT SUM(CASE
            WHEN t.type = 'income' THEN t.amount
            WHEN t.type = 'expense' THEN -t.amount
            WHEN t.type = 'transfer' THEN -t.amount
            ELSE 0
          END)
          FROM transactions t
          WHERE t.account_id = a.id
        ), 0)
        + COALESCE((
          SELECT SUM(t.amount)
          FROM transactions t
          WHERE t.type = 'transfer' AND t.destination_account_id = a.id
        ), 0)
        + COALESCE((
          SELECT SUM(CASE
            WHEN g.type = 'deposit' THEN -g.amount
            WHEN g.type = 'withdrawal' THEN g.amount
            ELSE 0
          END)
          FROM savings_goal_transfers g
          WHERE g.account_id = a.id
        ), 0) AS current_balance
      FROM accounts a
      ORDER BY a.is_archived ASC, a.created_at ASC
      ''',
      readsFrom: {accounts, moneyTransactions, savingsGoalTransfers},
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
          isArchived: row.read<bool>('is_archived'),
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

  Stream<List<Tag>> watchAllTags() =>
      (select(tags)..orderBy([(row) => OrderingTerm.asc(row.name)])).watch();

  Stream<List<TransactionTag>> watchAllTransactionTags() =>
      select(transactionTags).watch();

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..orderBy([
            (row) => OrderingTerm.asc(row.isArchived),
            (row) => OrderingTerm.asc(row.name),
          ]))
          .watch();

  Stream<List<Budget>> watchAllBudgets() => (select(
    budgets,
  )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).watch();

  Stream<List<RecurringRule>> watchAllRecurringRules() => (select(
    recurringRules,
  )..orderBy([(row) => OrderingTerm.asc(row.nextDueAt)])).watch();

  Stream<List<RecurringOccurrence>> watchPendingOccurrences() =>
      (select(recurringOccurrences)
            ..where((row) => row.status.equals('pending'))
            ..orderBy([(row) => OrderingTerm.asc(row.dueAt)]))
          .watch();

  Stream<List<SavingsGoalTransfer>> watchAllSavingsGoalTransfers() => (select(
    savingsGoalTransfers,
  )..orderBy([(row) => OrderingTerm.desc(row.transferDate)])).watch();

  Stream<List<SavingsGoalWithProgress>> watchSavingsGoalsWithProgress() {
    return customSelect(
      '''
      SELECT g.*,
        COALESCE((
          SELECT SUM(CASE
            WHEN t.type = 'deposit' THEN t.amount
            WHEN t.type = 'withdrawal' THEN -t.amount
            ELSE 0
          END)
          FROM savings_goal_transfers t
          WHERE t.goal_id = g.id
        ), 0) AS saved
      FROM savings_goals g
      ORDER BY g.is_archived ASC, g.created_at ASC
      ''',
      readsFrom: {savingsGoals, savingsGoalTransfers},
    ).watch().map(
      (rows) => rows.map((row) {
        final goal = SavingsGoal(
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          targetAmount: row.read<int>('target_amount'),
          targetDate: row.readNullable<DateTime>('target_date'),
          isArchived: row.read<bool>('is_archived'),
          createdAt: row.read<DateTime>('created_at'),
          updatedAt: row.read<DateTime>('updated_at'),
        );
        return SavingsGoalWithProgress(
          goal: goal,
          saved: row.read<int>('saved'),
        );
      }).toList(),
    );
  }

  Future<List<Account>> getAllAccounts() => select(accounts).get();
  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<List<MoneyTransaction>> getAllTransactions() =>
      select(moneyTransactions).get();
  Future<List<Tag>> getAllTags() => select(tags).get();
  Future<List<TransactionTag>> getAllTransactionTags() =>
      select(transactionTags).get();
  Future<List<Budget>> getAllBudgets() => select(budgets).get();
  Future<List<RecurringRule>> getAllRecurringRules() =>
      select(recurringRules).get();
  Future<List<RecurringRuleTag>> getAllRecurringRuleTags() =>
      select(recurringRuleTags).get();
  Future<List<RecurringOccurrence>> getAllRecurringOccurrences() =>
      select(recurringOccurrences).get();
  Future<List<SavingsGoal>> getAllSavingsGoals() => select(savingsGoals).get();
  Future<List<SavingsGoalTransfer>> getAllSavingsGoalTransfers() =>
      select(savingsGoalTransfers).get();

  Future<int> totalBalance() async {
    final rows = await watchAccountsWithBalances().first;
    final goals = await watchSavingsGoalsWithProgress().first;
    return rows.fold<int>(0, (total, item) => total + item.balance) +
        goals.fold<int>(0, (total, item) => total + item.saved);
  }

  Future<int> accountBalance(String accountId) async {
    final rows = await watchAccountsWithBalances().first;
    return rows
        .where((item) => item.account.id == accountId)
        .map((item) => item.balance)
        .first;
  }

  Future<bool> canChangeCurrency() async {
    if ((await getAllAccounts()).any((item) => item.initialBalance != 0)) {
      return false;
    }
    final checks = await Future.wait<int>([
      select(moneyTransactions).get().then((value) => value.length),
      select(budgets).get().then((value) => value.length),
      select(recurringRules).get().then((value) => value.length),
      select(savingsGoals).get().then((value) => value.length),
      select(savingsGoalTransfers).get().then((value) => value.length),
    ]);
    return checks.every((count) => count == 0);
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
        AND (category_id IS NULL
          OR category_id NOT IN ('$adjustmentIncomeCategoryId', '$adjustmentExpenseCategoryId'))
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
      await _deleteAllFinancialData();
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
                  isArchived: Value(item.isArchived),
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
                  isArchived: Value(item.isArchived),
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
        batch.insertAll(
          tags,
          backup.tags
              .map(
                (item) => TagsCompanion.insert(
                  id: item['id']! as String,
                  name: item['name']! as String,
                  normalizedName: item['normalizedName']! as String,
                  createdAt: DateTime.parse(item['createdAt']! as String),
                ),
              )
              .toList(),
        );
        batch.insertAll(
          transactionTags,
          backup.transactionTags
              .map(
                (item) => TransactionTagsCompanion.insert(
                  transactionId: item['transactionId']! as String,
                  tagId: item['tagId']! as String,
                ),
              )
              .toList(),
        );
        batch.insertAll(
          budgets,
          backup.budgets
              .map(
                (item) => BudgetsCompanion.insert(
                  id: item['id']! as String,
                  categoryId: Value(item['categoryId'] as String?),
                  amount: item['amount']! as int,
                  isActive: Value(item['isActive']! as bool),
                  createdAt: DateTime.parse(item['createdAt']! as String),
                  updatedAt: DateTime.parse(item['updatedAt']! as String),
                ),
              )
              .toList(),
        );
        batch.insertAll(
          savingsGoals,
          backup.savingsGoals
              .map(
                (item) => SavingsGoalsCompanion.insert(
                  id: item['id']! as String,
                  name: item['name']! as String,
                  targetAmount: item['targetAmount']! as int,
                  targetDate: Value(
                    item['targetDate'] == null
                        ? null
                        : DateTime.parse(item['targetDate']! as String),
                  ),
                  isArchived: Value(item['isArchived']! as bool),
                  createdAt: DateTime.parse(item['createdAt']! as String),
                  updatedAt: DateTime.parse(item['updatedAt']! as String),
                ),
              )
              .toList(),
        );
        batch.insertAll(
          savingsGoalTransfers,
          backup.savingsGoalTransfers
              .map(
                (item) => SavingsGoalTransfersCompanion.insert(
                  id: item['id']! as String,
                  goalId: item['goalId']! as String,
                  accountId: item['accountId']! as String,
                  type: item['type']! as String,
                  amount: item['amount']! as int,
                  note: Value(item['note'] as String?),
                  transferDate: DateTime.parse(item['transferDate']! as String),
                  createdAt: DateTime.parse(item['createdAt']! as String),
                ),
              )
              .toList(),
        );
        batch.insertAll(
          recurringRules,
          backup.recurringRules
              .map(
                (item) => RecurringRulesCompanion.insert(
                  id: item['id']! as String,
                  name: item['name']! as String,
                  type: item['type']! as String,
                  amount: item['amount']! as int,
                  accountId: item['accountId']! as String,
                  destinationAccountId: Value(
                    item['destinationAccountId'] as String?,
                  ),
                  categoryId: Value(item['categoryId'] as String?),
                  note: Value(item['note'] as String?),
                  frequency: item['frequency']! as String,
                  startDate: DateTime.parse(item['startDate']! as String),
                  nextDueAt: DateTime.parse(item['nextDueAt']! as String),
                  isPaused: Value(item['isPaused']! as bool),
                  createdAt: DateTime.parse(item['createdAt']! as String),
                  updatedAt: DateTime.parse(item['updatedAt']! as String),
                ),
              )
              .toList(),
        );
        batch.insertAll(
          recurringRuleTags,
          backup.recurringRuleTags
              .map(
                (item) => RecurringRuleTagsCompanion.insert(
                  ruleId: item['ruleId']! as String,
                  tagId: item['tagId']! as String,
                ),
              )
              .toList(),
        );
        batch.insertAll(
          recurringOccurrences,
          backup.recurringOccurrences
              .map(
                (item) => RecurringOccurrencesCompanion.insert(
                  id: item['id']! as String,
                  ruleId: item['ruleId']! as String,
                  dueAt: DateTime.parse(item['dueAt']! as String),
                  status: item['status']! as String,
                  transactionId: Value(item['transactionId'] as String?),
                  createdAt: DateTime.parse(item['createdAt']! as String),
                  updatedAt: DateTime.parse(item['updatedAt']! as String),
                ),
              )
              .toList(),
        );
      });
    });
  }

  Future<void> resetAllData() async {
    await transaction(() async {
      await _deleteAllFinancialData();
      await _seedDefaultCategories();
    });
  }

  Future<void> _deleteAllFinancialData() async {
    await delete(recurringRuleTags).go();
    await delete(recurringOccurrences).go();
    await delete(transactionTags).go();
    await delete(savingsGoalTransfers).go();
    await delete(budgets).go();
    await delete(recurringRules).go();
    await delete(savingsGoals).go();
    await delete(tags).go();
    await delete(moneyTransactions).go();
    await delete(categories).go();
    await delete(accounts).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'ferikmoney.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
