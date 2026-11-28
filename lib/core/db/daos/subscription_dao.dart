import 'package:drift/drift.dart';

import '../../dates/date_keys.dart';
import '../../dates/subscription_due.dart';
import '../../money/rupiah.dart';
import '../database.dart';
import '../errors.dart';
import '../tables.dart';

part 'subscription_dao.g.dart';

@DriftAccessor(tables: [Subscriptions])
class SubscriptionDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionDaoMixin {
  SubscriptionDao(super.db);

  Stream<List<SubscriptionEntry>> watchAll() =>
      (select(subscriptions)..orderBy([
            (s) => OrderingTerm.asc(s.nextDueDate),
            (s) => OrderingTerm.asc(s.name),
          ]))
          .watch();

  Stream<List<SubscriptionEntry>> watchDue(DateTime today) {
    return (select(subscriptions)
          ..where((s) => s.active.equals(true))
          ..orderBy([(s) => OrderingTerm.asc(s.nextDueDate)]))
        .watch()
        .map(
          (rows) => rows.where((row) {
            final days = daysUntil(parseDateKey(row.nextDueDate), today);
            return days <= row.leadDays;
          }).toList(),
        );
  }

  Future<SubscriptionEntry?> byId(int id) =>
      (select(subscriptions)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> createSubscription({
    required String name,
    required int amount,
    required int walletId,
    required int categoryId,
    required SubscriptionCycle cycle,
    required int anchorDay,
    int? anchorMonth,
    required int leadDays,
    String note = '',
    DateTime? from,
  }) async {
    _validate(
      amount: amount,
      anchorDay: anchorDay,
      anchorMonth: anchorMonth,
      leadDays: leadDays,
    );
    final now = DateTime.now();
    final next = initialDueDate(
      cycle: cycle,
      anchorDay: anchorDay,
      anchorMonth: anchorMonth,
      from: from ?? now,
    );
    return into(subscriptions).insert(
      SubscriptionsCompanion.insert(
        name: name.trim(),
        amount: amount,
        walletId: walletId,
        categoryId: categoryId,
        cycle: cycle.storageValue,
        anchorDay: anchorDay,
        anchorMonth: Value(anchorMonth),
        leadDays: Value(leadDays),
        nextDueDate: dateKey(next),
        note: Value(note.trim()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateSubscription({
    required int id,
    required String name,
    required int amount,
    required int walletId,
    required int categoryId,
    required SubscriptionCycle cycle,
    required int anchorDay,
    int? anchorMonth,
    required int leadDays,
    required bool active,
    String note = '',
  }) async {
    _validate(
      amount: amount,
      anchorDay: anchorDay,
      anchorMonth: anchorMonth,
      leadDays: leadDays,
    );
    final existing = await byId(id);
    if (existing == null) {
      return;
    }
    final anchorChanged =
        existing.anchorDay != anchorDay ||
        existing.anchorMonth != anchorMonth ||
        existing.cycle != cycle.storageValue;
    final nextDueDate = anchorChanged
        ? dateKey(
            initialDueDate(
              cycle: cycle,
              anchorDay: anchorDay,
              anchorMonth: anchorMonth,
              from: DateTime.now(),
            ),
          )
        : existing.nextDueDate;
    await (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        name: Value(name.trim()),
        amount: Value(amount),
        walletId: Value(walletId),
        categoryId: Value(categoryId),
        cycle: Value(cycle.storageValue),
        anchorDay: Value(anchorDay),
        anchorMonth: Value(anchorMonth),
        leadDays: Value(leadDays),
        nextDueDate: Value(nextDueDate),
        active: Value(active),
        note: Value(note.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setActive(int id, bool active) async {
    await (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        active: Value(active),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> completeCycle(int id) async {
    final existing = await byId(id);
    if (existing == null) {
      return;
    }
    final cycle = SubscriptionCycle.parse(existing.cycle);
    final next = advanceDueDate(
      current: parseDateKey(existing.nextDueDate),
      cycle: cycle,
      anchorDay: existing.anchorDay,
      anchorMonth: existing.anchorMonth,
    );
    await (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(
        nextDueDate: Value(dateKey(next)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void _validate({
    required int amount,
    required int anchorDay,
    int? anchorMonth,
    required int leadDays,
  }) {
    if (amount <= 0 || amount > maxTransactionAmount) {
      throw const DomainError(ErrorCodes.invalidAmount);
    }
    if (anchorDay < 1 || anchorDay > 31) {
      throw const DomainError(ErrorCodes.invalidDueDay);
    }
    if (anchorMonth != null && (anchorMonth < 1 || anchorMonth > 12)) {
      throw const DomainError(ErrorCodes.invalidDueDay);
    }
    if (leadDays < 0 || leadDays > 30) {
      throw const DomainError(ErrorCodes.invalidDueDay);
    }
  }
}
