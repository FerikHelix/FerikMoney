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
  late SavingsRepository savings;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    money = MoneyRepository(database);
    savings = SavingsRepository(database);
    await database.getAllCategories();
  });

  tearDown(() => database.close());

  Future<String> wallet({int balance = 1000000}) => money.saveAccount(
    name: 'BCA',
    type: 'bank',
    initialBalance: balance,
    icon: 'account_balance',
  );

  group('savings transfers', () {
    test('deleting a deposit returns the money to the wallet', () async {
      final accountId = await wallet();
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 1000000,
      );
      final transferId = await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.deposit,
        amount: 300000,
        date: DateTime(2026, 9, 1),
      );
      expect(await database.accountBalance(accountId), 700000);

      await savings.deleteTransfer(transferId);

      expect(await database.accountBalance(accountId), 1000000);
      expect(await database.getAllSavingsGoalTransfers(), isEmpty);
    });

    test('undo restores the exact transfer', () async {
      final accountId = await wallet();
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 1000000,
      );
      final transferId = await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.deposit,
        amount: 300000,
        note: 'Awal',
        date: DateTime(2026, 9, 1),
      );
      final original = (await database.getAllSavingsGoalTransfers()).single;
      await savings.deleteTransfer(transferId);

      await savings.restoreTransfer(original);

      final restored = (await database.getAllSavingsGoalTransfers()).single;
      expect(restored.id, original.id);
      expect(restored.amount, 300000);
      expect(restored.note, 'Awal');
      expect(await database.accountBalance(accountId), 700000);
    });

    test('a deposit that was already withdrawn cannot be deleted', () async {
      final accountId = await wallet();
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 1000000,
      );
      final depositId = await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.deposit,
        amount: 300000,
        date: DateTime(2026, 9, 1),
      );
      await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.withdrawal,
        amount: 250000,
        date: DateTime(2026, 9, 2),
      );

      await expectLater(
        savings.deleteTransfer(depositId),
        throwsA(isA<MoneyValidationException>()),
      );
      expect(await database.getAllSavingsGoalTransfers(), hasLength(2));
    });

    test('a withdrawal can always be deleted', () async {
      final accountId = await wallet();
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 1000000,
      );
      await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.deposit,
        amount: 300000,
        date: DateTime(2026, 9, 1),
      );
      final withdrawalId = await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.withdrawal,
        amount: 100000,
        date: DateTime(2026, 9, 2),
      );

      await savings.deleteTransfer(withdrawalId);

      expect(await database.getAllSavingsGoalTransfers(), hasLength(1));
    });

    test('a missing transfer is reported', () async {
      await expectLater(
        savings.deleteTransfer('missing'),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('archived goals can be restored', () async {
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 1000000,
      );
      await savings.archiveGoal(goalId, archived: true);
      expect((await database.getAllSavingsGoals()).single.isArchived, isTrue);

      await savings.archiveGoal(goalId, archived: false);

      expect((await database.getAllSavingsGoals()).single.isArchived, isFalse);
    });
  });

  group('deleting a wallet', () {
    test('succeeds when nothing references it', () async {
      final accountId = await wallet();

      await money.deleteAccount(accountId);

      expect(await database.getAllAccounts(), isEmpty);
    });

    test('is refused when transactions use it', () async {
      final accountId = await wallet();
      await money.saveTransaction(
        type: 'expense',
        amount: 1000,
        accountId: accountId,
        categoryId: 'expense-food',
        transactionDate: DateTime(2026, 9, 1),
      );

      await expectLater(
        money.deleteAccount(accountId),
        throwsA(isA<MoneyValidationException>()),
      );
      expect(await database.getAllAccounts(), hasLength(1));
    });

    test('is refused when a savings transfer uses it', () async {
      final accountId = await wallet();
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 1000000,
      );
      await savings.transfer(
        goalId: goalId,
        accountId: accountId,
        type: GoalTransferType.deposit,
        amount: 1000,
        date: DateTime(2026, 9, 1),
      );

      await expectLater(
        money.deleteAccount(accountId),
        throwsA(isA<MoneyValidationException>()),
      );
    });

    test('is refused when a recurring rule uses it', () async {
      final accountId = await wallet();
      await RecurringRepository(database, money).saveRule(
        name: 'Langganan',
        type: 'expense',
        amount: 50000,
        accountId: accountId,
        categoryId: 'expense-bills',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
      );

      await expectLater(
        money.deleteAccount(accountId),
        throwsA(isA<MoneyValidationException>()),
      );
    });
  });

  test('a budget can be deleted', () async {
    final budgets = BudgetRepository(database);
    final id = await budgets.save(categoryId: 'expense-food', amount: 500000);
    expect(await database.getAllBudgets(), hasLength(1));

    await budgets.delete(id);

    expect(await database.getAllBudgets(), isEmpty);
  });
}
