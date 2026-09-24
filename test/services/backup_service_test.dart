import 'dart:convert';

import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/models/backup_data.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
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

    expect(json['version'], 1);
    expect(json['app'], 'FerikMoney');
    expect(data['accounts'], hasLength(1));
    expect(data['categories'], hasLength(13));
    expect(data['transactions'], hasLength(1));
  });

  test('valid JSON backup passes strict validation', () async {
    await addAccount();
    final source = service.serialize(await service.createBackup());

    final validated = BackupService.validateJson(source);

    expect(validated.accounts.single.name, 'BCA');
    expect(validated.categories, hasLength(13));
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
    expect(categories, hasLength(13));
  });
}
