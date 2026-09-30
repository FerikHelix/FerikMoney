import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/models/finance_models.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
import 'package:ferikmoney/repositories/report_repository.dart';
import 'package:ferikmoney/services/backup_service.dart';
import 'package:ferikmoney/utils/balance_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MoneyRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = MoneyRepository(database);
    await database.getAllCategories();
  });

  tearDown(() => database.close());

  Future<String> wallet({int balance = 1000000}) => repository.saveAccount(
    name: 'BCA',
    type: 'bank',
    initialBalance: balance,
    icon: 'account_balance',
  );

  test('raising the balance records an income adjustment', () async {
    final id = await wallet();

    final delta = await repository.adjustBalance(
      accountId: id,
      newBalance: 1250000,
      note: 'Saldo diubah',
    );

    expect(delta, 250000);
    expect(await database.accountBalance(id), 1250000);
    final transaction = (await database.getAllTransactions()).single;
    expect(transaction.type, 'income');
    expect(transaction.amount, 250000);
    expect(transaction.categoryId, adjustmentIncomeCategoryId);
    expect(transaction.note, 'Saldo diubah');
    final category = (await database.getAllCategories()).singleWhere(
      (item) => item.id == adjustmentIncomeCategoryId,
    );
    expect(category.name, adjustmentCategoryName);
    expect(category.type, 'income');
  });

  test('lowering the balance records an expense adjustment', () async {
    final id = await wallet();

    final delta = await repository.adjustBalance(
      accountId: id,
      newBalance: 400000,
    );

    expect(delta, -600000);
    expect(await database.accountBalance(id), 400000);
    final transaction = (await database.getAllTransactions()).single;
    expect(transaction.type, 'expense');
    expect(transaction.amount, 600000);
    expect(transaction.categoryId, adjustmentExpenseCategoryId);
    expect(transaction.note, isNull);
  });

  test('an unchanged balance records nothing', () async {
    final id = await wallet();
    await repository.saveTransaction(
      type: 'expense',
      amount: 100000,
      accountId: id,
      categoryId: 'expense-food',
      transactionDate: DateTime(2026, 9, 1),
    );

    final delta = await repository.adjustBalance(
      accountId: id,
      newBalance: 900000,
    );

    expect(delta, 0);
    expect(await database.getAllTransactions(), hasLength(1));
  });

  test(
    'adjustment is relative to the current balance, not the opening one',
    () async {
      final id = await wallet();
      await repository.saveTransaction(
        type: 'expense',
        amount: 300000,
        accountId: id,
        categoryId: 'expense-food',
        transactionDate: DateTime(2026, 9, 1),
      );

      await repository.adjustBalance(accountId: id, newBalance: 800000);

      final adjustment = (await database.getAllTransactions()).singleWhere(
        (item) => isAdjustmentCategory(item.categoryId),
      );
      expect(adjustment.type, 'income');
      expect(adjustment.amount, 100000);
      expect(await database.accountBalance(id), 800000);
    },
  );

  test('invalid balances and unknown wallets are rejected', () async {
    final id = await wallet();

    await expectLater(
      repository.adjustBalance(accountId: id, newBalance: -1),
      throwsA(isA<MoneyValidationException>()),
    );
    await expectLater(
      repository.adjustBalance(accountId: 'missing', newBalance: 10),
      throwsA(isA<MoneyValidationException>()),
    );
    expect(await database.getAllTransactions(), isEmpty);
  });

  test('archived wallets can still be adjusted', () async {
    final id = await wallet();
    await repository.archiveAccount(id, archived: true);

    await repository.adjustBalance(accountId: id, newBalance: 50);

    expect(await database.accountBalance(id), 50);
  });

  test('adjustments are excluded from income and expense totals', () async {
    final id = await wallet();
    final today = DateTime.now();
    await repository.saveTransaction(
      type: 'income',
      amount: 500000,
      accountId: id,
      categoryId: 'income-salary',
      transactionDate: today,
    );
    await repository.saveTransaction(
      type: 'expense',
      amount: 20000,
      accountId: id,
      categoryId: 'expense-food',
      transactionDate: today,
    );
    await repository.adjustBalance(accountId: id, newBalance: 9000000);
    await repository.adjustBalance(accountId: id, newBalance: 100);

    // Balances include the adjustments...
    expect(await database.accountBalance(id), 100);

    // ...but income/expense totals do not.
    final summary = await database.monthlySummary(today);
    expect(summary.income, 500000);
    expect(summary.expense, 20000);

    final report = const ReportRepository().build(
      transactions: await database.getAllTransactions(),
      period: FinancePeriod.month,
      anchor: today,
      firstWeekday: DateTime.monday,
      now: today.add(const Duration(hours: 1)),
    );
    expect(report.income, 500000);
    expect(report.expense, 20000);
    expect(report.expenseByCategory.keys, ['expense-food']);
    expect(report.incomeByCategory.keys, ['income-salary']);
  });

  test('adjustments survive a backup round trip', () async {
    final id = await wallet();
    await repository.adjustBalance(accountId: id, newBalance: 700000);
    final service = BackupService(database);
    final backup = await service.createBackup();

    await database.restoreBackup(backup);

    expect(await database.accountBalance(id), 700000);
    final transactions = await database.getAllTransactions();
    expect(transactions, hasLength(1));
    expect(transactions.single.categoryId, adjustmentExpenseCategoryId);
    expect(
      (await database.getAllCategories()).any(
        (item) => item.id == adjustmentExpenseCategoryId,
      ),
      isTrue,
    );
  });
}
