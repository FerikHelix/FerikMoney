import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/models/finance_models.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
import 'package:ferikmoney/repositories/recurring_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MoneyRepository money;
  late RecurringRepository recurring;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    money = MoneyRepository(database);
    recurring = RecurringRepository(database, money);
    await database.getAllCategories();
  });

  tearDown(() => database.close());

  test('a skipped occurrence can be put back in the queue', () async {
    final accountId = await money.saveAccount(
      name: 'BCA',
      type: 'bank',
      initialBalance: 1000000,
      icon: 'account_balance',
    );
    await recurring.saveRule(
      name: 'Internet',
      type: 'expense',
      amount: 300000,
      accountId: accountId,
      categoryId: 'expense-bills',
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2024, 5, 1),
    );
    await recurring.generateDue(now: DateTime(2024, 5, 2));
    final occurrence = (await database.getAllRecurringOccurrences()).first;
    expect(occurrence.status, OccurrenceStatus.pending.name);

    await recurring.skipOccurrence(occurrence.id);
    expect(
      (await database.getAllRecurringOccurrences()).first.status,
      OccurrenceStatus.skipped.name,
    );

    await recurring.unskipOccurrence(occurrence.id);
    expect(
      (await database.getAllRecurringOccurrences()).first.status,
      OccurrenceStatus.pending.name,
    );
  });

  test('undo only affects skipped occurrences', () async {
    final accountId = await money.saveAccount(
      name: 'BCA',
      type: 'bank',
      initialBalance: 1000000,
      icon: 'account_balance',
    );
    await recurring.saveRule(
      name: 'Internet',
      type: 'expense',
      amount: 300000,
      accountId: accountId,
      categoryId: 'expense-bills',
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2024, 5, 1),
    );
    await recurring.generateDue(now: DateTime(2024, 5, 2));
    final occurrence = (await database.getAllRecurringOccurrences()).first;

    await recurring.unskipOccurrence(occurrence.id);

    expect(
      (await database.getAllRecurringOccurrences()).first.status,
      OccurrenceStatus.pending.name,
    );
  });
}
