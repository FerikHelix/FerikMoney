import 'dart:convert';

import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/models/backup_data.dart';
import 'package:ferikmoney/models/finance_models.dart';
import 'package:ferikmoney/repositories/budget_repository.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
import 'package:ferikmoney/repositories/recurring_repository.dart';
import 'package:ferikmoney/repositories/savings_repository.dart';
import 'package:ferikmoney/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MoneyRepository repository;
  late BackupService service;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = MoneyRepository(database);
    service = BackupService(database);
    await database.getAllCategories();
  });

  tearDown(() => database.close());

  Future<String> addAccount() => repository.saveAccount(
    name: 'BCA',
    type: 'bank',
    initialBalance: 1000000,
    icon: 'account_balance',
  );

  test('JSON export serializes metadata and all entity collections', () async {
    final accountId = await addAccount();
    await repository.saveTransaction(
      type: 'income',
      amount: 500000,
      accountId: accountId,
      categoryId: 'income-salary',
      transactionDate: DateTime(2026, 9, 1),
    );

    final encoded = service.serialize(await service.createBackup());
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;

    expect(json['version'], BackupData.currentVersion);
    expect(json['app'], 'FerikMoney');
    expect(data['accounts'], hasLength(1));
    expect(data['categories'], hasLength(17));
    expect(data['transactions'], hasLength(1));
    expect(data['tags'], isEmpty);
    expect(data['budgets'], isEmpty);
    expect(data['recurringRules'], isEmpty);
    expect(data['savingsGoals'], isEmpty);
  });

  test('valid JSON backup passes strict validation', () async {
    await addAccount();
    final source = service.serialize(await service.createBackup());

    final validated = BackupService.validateJson(source);

    expect(validated.accounts.single.name, 'BCA');
    expect(validated.categories, hasLength(17));
  });

  test(
    'v1 backup is accepted with safe defaults for new collections',
    () async {
      await addAccount();
      final map =
          jsonDecode(service.serialize(await service.createBackup()))
              as Map<String, dynamic>;
      map['version'] = 1;
      final data = map['data'] as Map<String, dynamic>;
      for (final key in [
        'tags',
        'transactionTags',
        'budgets',
        'recurringRules',
        'recurringRuleTags',
        'recurringOccurrences',
        'savingsGoals',
        'savingsGoalTransfers',
        'preferences',
      ]) {
        data.remove(key);
      }
      for (final account in data['accounts'] as List<dynamic>) {
        (account as Map<String, dynamic>).remove('isArchived');
      }
      for (final category in data['categories'] as List<dynamic>) {
        (category as Map<String, dynamic>).remove('isArchived');
      }

      final validated = BackupService.validateJson(jsonEncode(map));

      expect(validated.version, 1);
      expect(validated.accounts.single.isArchived, isFalse);
      expect(validated.tags, isEmpty);
      expect(validated.preferences, isEmpty);
    },
  );

  test('v2 round-trip restores all new references', () async {
    final accountId = await addAccount();
    await repository.saveTransaction(
      type: 'expense',
      amount: 25000,
      accountId: accountId,
      categoryId: 'expense-food',
      tags: const ['Kantor'],
      transactionDate: DateTime(2026, 9, 2),
    );
    await BudgetRepository(database).save(amount: 500000);
    final savings = SavingsRepository(database);
    final goalId = await savings.saveGoal(
      name: 'Laptop',
      targetAmount: 1500000,
    );
    await savings.transfer(
      goalId: goalId,
      accountId: accountId,
      type: GoalTransferType.deposit,
      amount: 100000,
      date: DateTime(2026, 9, 3),
    );
    final recurring = RecurringRepository(database, repository);
    await recurring.saveRule(
      name: 'Makan',
      type: 'expense',
      amount: 20000,
      accountId: accountId,
      categoryId: 'expense-food',
      frequency: RecurrenceFrequency.weekly,
      startDate: DateTime(2026, 9, 1),
      tags: const ['Kantor'],
    );
    await recurring.generateDue(now: DateTime(2026, 9, 10));
    final backup = BackupService.validateJson(
      service.serialize(await service.createBackup()),
    );

    await database.resetAllData();
    await service.restore(backup);

    expect(await database.getAllAccounts(), hasLength(1));
    expect(await database.getAllTransactions(), hasLength(1));
    expect(await database.getAllTags(), hasLength(1));
    expect(await database.getAllTransactionTags(), hasLength(1));
    expect(await database.getAllBudgets(), hasLength(1));
    expect(await database.getAllRecurringRules(), hasLength(1));
    expect(await database.getAllRecurringRuleTags(), hasLength(1));
    expect(await database.getAllRecurringOccurrences(), hasLength(2));
    expect(await database.getAllSavingsGoals(), hasLength(1));
    expect(await database.getAllSavingsGoalTransfers(), hasLength(1));
  });

  test('invalid and corrupted JSON is rejected', () {
    expect(
      () => BackupService.validateJson('{broken'),
      throwsA(isA<BackupValidationException>()),
    );
    expect(
      () => BackupService.validateJson('{"version":1}'),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('unsupported backup version is rejected', () async {
    await addAccount();
    final map =
        jsonDecode(service.serialize(await service.createBackup()))
            as Map<String, dynamic>;
    map['version'] = 99;

    expect(
      () => BackupService.validateJson(jsonEncode(map)),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('missing account reference is rejected', () async {
    final accountId = await addAccount();
    await repository.saveTransaction(
      type: 'expense',
      amount: 25000,
      accountId: accountId,
      categoryId: 'expense-food',
      transactionDate: DateTime(2026, 9, 2),
    );
    final map =
        jsonDecode(service.serialize(await service.createBackup()))
            as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final transactions = data['transactions'] as List<dynamic>;
    (transactions.single as Map<String, dynamic>)['accountId'] = 'missing';

    expect(
      () => BackupService.validateJson(jsonEncode(map)),
      throwsA(
        isA<BackupValidationException>().having(
          (error) => error.message,
          'message',
          contains('akun'),
        ),
      ),
    );
  });

  test('duplicate IDs are rejected', () async {
    await addAccount();
    final map =
        jsonDecode(service.serialize(await service.createBackup()))
            as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final accounts = data['accounts'] as List<dynamic>;
    accounts.add(Map<String, dynamic>.from(accounts.first as Map));

    expect(
      () => BackupService.validateJson(jsonEncode(map)),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('failed atomic restore rolls back and keeps existing data', () async {
    await addAccount();
    final now = DateTime(2026, 9, 23);
    final invalidBackup = BackupData(
      exportedAt: now,
      accounts: const [],
      categories: [
        BackupCategory(
          id: 'expense-food',
          name: 'Makan',
          type: 'expense',
          icon: 'restaurant',
          createdAt: now,
        ),
      ],
      transactions: [
        BackupTransaction(
          id: 'tx-invalid',
          type: 'expense',
          amount: 10000,
          accountId: 'missing-account',
          destinationAccountId: null,
          categoryId: 'expense-food',
          note: null,
          transactionDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    await expectLater(database.restoreBackup(invalidBackup), throwsA(anything));

    final accounts = await database.getAllAccounts();
    final categories = await database.getAllCategories();
    expect(accounts.single.name, 'BCA');
    expect(categories, hasLength(17));
  });
}
