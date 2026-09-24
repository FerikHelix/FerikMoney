import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
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

  Future<String> account(String name, int initialBalance) {
    return repository.saveAccount(
      name: name,
      type: 'bank',
      initialBalance: initialBalance,
      icon: 'account_balance',
    );
  }

  test('income increases account balance', () async {
    final id = await account('BCA', 1000000);
    await repository.saveTransaction(
      type: 'income',
      amount: 500000,
      accountId: id,
      categoryId: 'income-salary',
      transactionDate: DateTime(2026, 9, 1),
    );

    expect(await database.accountBalance(id), 1500000);
  });

  test('expense decreases account balance', () async {
    final id = await account('Cash', 1000000);
    await repository.saveTransaction(
      type: 'expense',
      amount: 25000,
      accountId: id,
      categoryId: 'expense-food',
      transactionDate: DateTime(2026, 9, 2),
    );

    expect(await database.accountBalance(id), 975000);
  });

  test(
    'transfer updates both accounts and never changes total money',
    () async {
      final source = await account('Bank Jago', 1000000);
      final destination = await account('BCA', 500000);

      await repository.saveTransaction(
        type: 'transfer',
        amount: 200000,
        accountId: source,
        destinationAccountId: destination,
        transactionDate: DateTime(2026, 9, 3),
      );

      expect(await database.accountBalance(source), 800000);
      expect(await database.accountBalance(destination), 700000);
      expect(await database.totalBalance(), 1500000);
    },
  );

  test('total money is calculated across multiple accounts', () async {
    await account('Bank Jago', 4200000);
    await account('BCA', 2500000);
    await account('Cash', 1000000);
    await account('GoPay', 750000);

    expect(await database.totalBalance(), 8450000);
  });

  test('monthly income calculation includes only selected month', () async {
    final id = await account('BCA', 0);
    await repository.saveTransaction(
      type: 'income',
      amount: 5300000,
      accountId: id,
      categoryId: 'income-salary',
      transactionDate: DateTime(2026, 9, 1),
    );
    await repository.saveTransaction(
      type: 'income',
      amount: 100000,
      accountId: id,
      categoryId: 'income-bonus',
      transactionDate: DateTime(2026, 8, 31),
    );

    expect((await database.monthlySummary(DateTime(2026, 9))).income, 5300000);
  });

  test('monthly expense calculation includes only expenses', () async {
    final id = await account('Cash', 1000000);
    await repository.saveTransaction(
      type: 'expense',
      amount: 30000,
      accountId: id,
      categoryId: 'expense-transport',
      transactionDate: DateTime(2026, 9, 4),
    );
    await repository.saveTransaction(
      type: 'income',
      amount: 90000,
      accountId: id,
      categoryId: 'income-gift',
      transactionDate: DateTime(2026, 9, 4),
    );

    expect((await database.monthlySummary(DateTime(2026, 9))).expense, 30000);
  });

  test('net cash flow is income minus expense and ignores transfer', () async {
    final source = await account('BCA', 1000000);
    final destination = await account('Cash', 0);
    await repository.saveTransaction(
      type: 'income',
      amount: 500000,
      accountId: source,
      categoryId: 'income-salary',
      transactionDate: DateTime(2026, 9, 5),
    );
    await repository.saveTransaction(
      type: 'expense',
      amount: 200000,
      accountId: source,
      categoryId: 'expense-shopping',
      transactionDate: DateTime(2026, 9, 6),
    );
    await repository.saveTransaction(
      type: 'transfer',
      amount: 100000,
      accountId: source,
      destinationAccountId: destination,
      transactionDate: DateTime(2026, 9, 7),
    );

    final summary = await database.monthlySummary(DateTime(2026, 9));
    expect(summary.net, 300000);
  });

  test('editing a transaction recalculates balance', () async {
    final id = await account('Cash', 1000000);
    final transactionId = await repository.saveTransaction(
      type: 'expense',
      amount: 100000,
      accountId: id,
      categoryId: 'expense-food',
      transactionDate: DateTime(2026, 9, 8),
    );
    await repository.saveTransaction(
      id: transactionId,
      type: 'expense',
      amount: 250000,
      accountId: id,
      categoryId: 'expense-food',
      transactionDate: DateTime(2026, 9, 8),
    );

    expect(await database.accountBalance(id), 750000);
  });

  test('referenced account cannot be deleted', () async {
    final id = await account('Cash', 100000);
    await repository.saveTransaction(
      type: 'expense',
      amount: 10000,
      accountId: id,
      categoryId: 'expense-food',
      transactionDate: DateTime(2026, 9, 9),
    );

    expect(
      () => repository.deleteAccount(id),
      throwsA(isA<MoneyValidationException>()),
    );
  });

  test('transfer to the same account is rejected', () async {
    final id = await account('BCA', 100000);
    expect(
      () => repository.saveTransaction(
        type: 'transfer',
        amount: 10000,
        accountId: id,
        destinationAccountId: id,
        transactionDate: DateTime(2026, 9, 10),
      ),
      throwsA(isA<MoneyValidationException>()),
    );
  });

  test('amount beyond the safe SQLite money range is rejected', () async {
    final id = await account('BCA', 100000);
    expect(
      () => repository.saveTransaction(
        type: 'income',
        amount: 9000000000000001,
        accountId: id,
        categoryId: 'income-salary',
        transactionDate: DateTime(2026, 9, 11),
      ),
      throwsA(isA<MoneyValidationException>()),
    );
  });
}
