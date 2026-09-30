import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/models/finance_models.dart';
import 'package:ferikmoney/repositories/budget_repository.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
import 'package:ferikmoney/repositories/recurring_repository.dart';
import 'package:ferikmoney/repositories/savings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MoneyRepository money;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    money = MoneyRepository(database);
    await database.getAllCategories();
  });

  tearDown(() => database.close());

  Future<String> addWallet({int balance = 1000000}) => money.saveAccount(
    name: 'Wallet',
    type: 'bank',
    initialBalance: balance,
    icon: 'account_balance',
  );

  test(
    'tags are normalized and archived references cannot be reused',
    () async {
      final accountId = await addWallet();
      final transactionId = await money.saveTransaction(
        type: 'expense',
        amount: 10000,
        accountId: accountId,
        categoryId: 'expense-food',
        tags: const ['Kerja', ' kerja ', 'Kantor'],
        transactionDate: DateTime(2026, 9, 1),
      );

      expect(await database.getAllTags(), hasLength(2));
      expect(
        (await database.getAllTransactionTags()).where(
          (item) => item.transactionId == transactionId,
        ),
        hasLength(2),
      );

      final recurring = RecurringRepository(database, money);
      final ruleId = await recurring.saveRule(
        name: 'Makan siang',
        type: 'expense',
        amount: 20000,
        accountId: accountId,
        categoryId: 'expense-food',
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 9, 2),
      );
      await money.archiveCategory('expense-food', archived: true);
      final rule = (await database.getAllRecurringRules()).singleWhere(
        (item) => item.id == ruleId,
      );
      expect(rule.isPaused, isTrue);
      await expectLater(
        money.saveTransaction(
          type: 'expense',
          amount: 1000,
          accountId: accountId,
          categoryId: 'expense-food',
          transactionDate: DateTime(2026, 9, 3),
        ),
        throwsA(isA<MoneyValidationException>()),
      );
    },
  );

  test(
    'budget enforces one active scope and exact status thresholds',
    () async {
      final repository = BudgetRepository(database);
      await repository.save(amount: 100000);
      await expectLater(
        repository.save(amount: 200000),
        throwsA(isA<MoneyValidationException>()),
      );

      final budget = (await database.getAllBudgets()).single;
      expect(
        BudgetProgress(budget: budget, spent: 79999).status,
        BudgetStatus.safe,
      );
      expect(
        BudgetProgress(budget: budget, spent: 80000).status,
        BudgetStatus.approaching,
      );
      expect(
        BudgetProgress(budget: budget, spent: 100000).status,
        BudgetStatus.over,
      );
    },
  );

  test(
    'goal transfers preserve total money and reverse on withdrawal',
    () async {
      final accountId = await addWallet();
      final savings = SavingsRepository(database);
      final goalId = await savings.saveGoal(
        name: 'Dana darurat',
        targetAmount: 2000000,
      );
      final initialTotal = await database.totalBalance();

      await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.deposit,
        amount: 200000,
        date: DateTime(2026, 9, 1),
      );
      expect(await database.accountBalance(accountId), 800000);
      expect(
        (await database.watchSavingsGoalsWithProgress().first).single.saved,
        200000,
      );
      expect(await database.totalBalance(), initialTotal);

      await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.withdrawal,
        amount: 50000,
        date: DateTime(2026, 9, 2),
      );
      expect(await database.accountBalance(accountId), 850000);
      expect(
        (await database.watchSavingsGoalsWithProgress().first).single.saved,
        150000,
      );
      expect(await database.totalBalance(), initialTotal);
    },
  );

  test(
    'recurring generation is idempotent and confirmation creates once',
    () async {
      final accountId = await addWallet();
      final recurring = RecurringRepository(database, money);
      await recurring.saveRule(
        name: 'Tagihan bulanan',
        type: 'expense',
        amount: 75000,
        accountId: accountId,
        categoryId: 'expense-bills',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 31, 8),
      );

      await recurring.generateDue(now: DateTime(2024, 5, 1));
      await recurring.generateDue(now: DateTime(2024, 5, 1));
      final occurrences = await database.getAllRecurringOccurrences();
      expect(occurrences, hasLength(4));
      expect(
        occurrences.map((item) => item.dueAt.day),
        orderedEquals([31, 29, 31, 30]),
      );

      final confirmedDate = DateTime(2024, 2, 1, 10, 30);
      await recurring.createOccurrence(
        occurrences.first.id,
        type: 'expense',
        amount: 91000,
        accountId: accountId,
        categoryId: 'expense-bills',
        note: 'Tagihan PayLater aktual',
        tags: const ['PayLater'],
        transactionDate: confirmedDate,
      );
      await recurring.createOccurrence(occurrences.first.id);
      final transactions = await database.getAllTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.single.amount, 91000);
      expect(transactions.single.note, 'Tagihan PayLater aktual');
      expect(transactions.single.transactionDate, confirmedDate);
      expect(await database.getAllTransactionTags(), hasLength(1));
      expect((await database.getAllRecurringRules()).single.amount, 75000);
      final created = (await database.getAllRecurringOccurrences()).firstWhere(
        (item) => item.id == occurrences.first.id,
      );
      expect(created.status, OccurrenceStatus.created.name);
      expect(created.transactionId, isNotNull);
    },
  );
}
