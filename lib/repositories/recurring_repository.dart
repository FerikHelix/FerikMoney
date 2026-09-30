import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/finance_models.dart';
import '../utils/money_formatter.dart';
import 'money_repository.dart';

class RecurringRepository {
  RecurringRepository(this.database, this.moneyRepository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final MoneyRepository moneyRepository;
  final Uuid _uuid;

  Stream<List<RecurringRule>> watchRules() => database.watchAllRecurringRules();
  Stream<List<RecurringOccurrence>> watchPending() =>
      database.watchPendingOccurrences();

  Future<String> saveRule({
    String? id,
    required String name,
    required String type,
    required int amount,
    required String accountId,
    String? destinationAccountId,
    String? categoryId,
    String? note,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    List<String> tags = const [],
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const MoneyValidationException(
        'Nama transaksi berulang wajib diisi.',
      );
    }
    if (amount <= 0 || amount > maxMoneyAmount) {
      throw const MoneyValidationException('Nominal tidak valid.');
    }
    if (!const {'income', 'expense', 'transfer'}.contains(type)) {
      throw const MoneyValidationException('Jenis transaksi tidak valid.');
    }
    final account = await (database.select(
      database.accounts,
    )..where((row) => row.id.equals(accountId))).getSingleOrNull();
    if (account == null || account.isArchived) {
      throw const MoneyValidationException('Akun tidak tersedia.');
    }
    if (type == 'transfer') {
      if (destinationAccountId == null || destinationAccountId == accountId) {
        throw const MoneyValidationException('Akun tujuan tidak valid.');
      }
      final destination =
          await (database.select(database.accounts)
                ..where((row) => row.id.equals(destinationAccountId!)))
              .getSingleOrNull();
      if (destination == null || destination.isArchived) {
        throw const MoneyValidationException('Akun tujuan tidak tersedia.');
      }
      categoryId = null;
    } else {
      if (categoryId == null) {
        throw const MoneyValidationException('Kategori wajib dipilih.');
      }
      final category =
          await (database.select(database.categories)..where(
                (row) =>
                    row.id.equals(categoryId!) &
                    row.type.equals(type) &
                    row.isArchived.equals(false),
              ))
              .getSingleOrNull();
      if (category == null) {
        throw const MoneyValidationException('Kategori tidak tersedia.');
      }
      destinationAccountId = null;
    }
    final now = DateTime.now();
    if (id == null) {
      final newId = _uuid.v4();
      await database.transaction(() async {
        await database
            .into(database.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                id: newId,
                name: cleanName,
                type: type,
                amount: amount,
                accountId: accountId,
                destinationAccountId: Value(destinationAccountId),
                categoryId: Value(categoryId),
                note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
                frequency: frequency.name,
                startDate: startDate,
                nextDueAt: startDate,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _syncTags(newId, tags);
      });
      return newId;
    }
    final existing = await (database.select(
      database.recurringRules,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw const MoneyValidationException('Aturan berulang tidak ditemukan.');
    }
    await database.transaction(() async {
      await (database.update(
        database.recurringRules,
      )..where((row) => row.id.equals(id))).write(
        RecurringRulesCompanion(
          name: Value(cleanName),
          type: Value(type),
          amount: Value(amount),
          accountId: Value(accountId),
          destinationAccountId: Value(destinationAccountId),
          categoryId: Value(categoryId),
          note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
          frequency: Value(frequency.name),
          startDate: Value(startDate),
          nextDueAt: Value(
            existing.nextDueAt.isBefore(startDate)
                ? startDate
                : existing.nextDueAt,
          ),
          updatedAt: Value(now),
        ),
      );
      await _syncTags(id, tags);
    });
    return id;
  }

  Future<void> generateDue({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final rules = await (database.select(
      database.recurringRules,
    )..where((row) => row.isPaused.equals(false))).get();
    for (final rule in rules) {
      var due = rule.nextDueAt;
      var generated = 0;
      final frequency = RecurrenceFrequency.values.byName(rule.frequency);
      await database.transaction(() async {
        while (!due.isAfter(current) && generated < 1000) {
          final occurrenceId = _uuid.v5(
            Namespace.url.value,
            '${rule.id}:${due.toUtc().toIso8601String()}',
          );
          await database
              .into(database.recurringOccurrences)
              .insert(
                RecurringOccurrencesCompanion.insert(
                  id: occurrenceId,
                  ruleId: rule.id,
                  dueAt: due,
                  status: OccurrenceStatus.pending.name,
                  createdAt: current,
                  updatedAt: current,
                ),
                mode: InsertMode.insertOrIgnore,
              );
          due = _nextDue(frequency, due, rule.startDate);
          generated++;
        }
        await (database.update(
          database.recurringRules,
        )..where((row) => row.id.equals(rule.id))).write(
          RecurringRulesCompanion(
            nextDueAt: Value(due),
            updatedAt: Value(current),
          ),
        );
      });
    }
  }

  Future<void> createOccurrence(
    String occurrenceId, {
    String? type,
    int? amount,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    String? note,
    List<String>? tags,
    DateTime? transactionDate,
  }) async {
    final occurrence = await (database.select(
      database.recurringOccurrences,
    )..where((row) => row.id.equals(occurrenceId))).getSingleOrNull();
    if (occurrence == null || occurrence.status != 'pending') return;
    final rule = await (database.select(
      database.recurringRules,
    )..where((row) => row.id.equals(occurrence.ruleId))).getSingle();
    final useOverrides = amount != null;
    final tagNames = tags ?? await tagsForRule(rule.id);
    await database.transaction(() async {
      final transactionId = await moneyRepository.saveTransaction(
        type: type ?? rule.type,
        amount: amount ?? rule.amount,
        accountId: accountId ?? rule.accountId,
        destinationAccountId: useOverrides
            ? destinationAccountId
            : rule.destinationAccountId,
        categoryId: useOverrides ? categoryId : rule.categoryId,
        note: useOverrides ? note : rule.note,
        tags: tagNames,
        transactionDate: transactionDate ?? occurrence.dueAt,
      );
      await (database.update(database.recurringOccurrences)..where(
            (row) => row.id.equals(occurrenceId) & row.status.equals('pending'),
          ))
          .write(
            RecurringOccurrencesCompanion(
              status: Value(OccurrenceStatus.created.name),
              transactionId: Value(transactionId),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<void> skipOccurrence(String id) =>
      (database.update(database.recurringOccurrences)
            ..where((row) => row.id.equals(id) & row.status.equals('pending')))
          .write(
            RecurringOccurrencesCompanion(
              status: Value(OccurrenceStatus.skipped.name),
              updatedAt: Value(DateTime.now()),
            ),
          );

  /// Undo for [skipOccurrence]: puts a skipped occurrence back in the queue.
  Future<void> unskipOccurrence(String id) =>
      (database.update(database.recurringOccurrences)
            ..where((row) => row.id.equals(id) & row.status.equals('skipped')))
          .write(
            RecurringOccurrencesCompanion(
              status: Value(OccurrenceStatus.pending.name),
              updatedAt: Value(DateTime.now()),
            ),
          );

  Future<void> setPaused(String id, {required bool paused}) =>
      (database.update(
        database.recurringRules,
      )..where((row) => row.id.equals(id))).write(
        RecurringRulesCompanion(
          isPaused: Value(paused),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteRule(String id) => (database.delete(
    database.recurringRules,
  )..where((row) => row.id.equals(id))).go();

  Future<void> _syncTags(String ruleId, List<String> names) async {
    await (database.delete(
      database.recurringRuleTags,
    )..where((row) => row.ruleId.equals(ruleId))).go();
    for (final raw in names.take(10)) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final normalized = name.toLowerCase();
      final existing =
          await (database.select(database.tags)
                ..where((row) => row.normalizedName.equals(normalized)))
              .getSingleOrNull();
      final tagId = existing?.id ?? _uuid.v4();
      if (existing == null) {
        await database
            .into(database.tags)
            .insert(
              TagsCompanion.insert(
                id: tagId,
                name: name,
                normalizedName: normalized,
                createdAt: DateTime.now(),
              ),
            );
      }
      await database
          .into(database.recurringRuleTags)
          .insert(
            RecurringRuleTagsCompanion.insert(ruleId: ruleId, tagId: tagId),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<List<String>> tagsForRule(String ruleId) async {
    final links = await (database.select(
      database.recurringRuleTags,
    )..where((row) => row.ruleId.equals(ruleId))).get();
    if (links.isEmpty) return const [];
    final ids = links.map((item) => item.tagId).toList();
    final values = await (database.select(
      database.tags,
    )..where((row) => row.id.isIn(ids))).get();
    return values.map((item) => item.name).toList();
  }

  DateTime _nextDue(
    RecurrenceFrequency frequency,
    DateTime due,
    DateTime anchor,
  ) {
    if (frequency == RecurrenceFrequency.daily) {
      return due.add(const Duration(days: 1));
    }
    if (frequency == RecurrenceFrequency.weekly) {
      return due.add(const Duration(days: 7));
    }
    if (frequency == RecurrenceFrequency.monthly) {
      final target = DateTime(due.year, due.month + 1);
      final lastDay = DateTime(target.year, target.month + 1, 0).day;
      final day = anchor.day > lastDay ? lastDay : anchor.day;
      return DateTime(
        target.year,
        target.month,
        day,
        anchor.hour,
        anchor.minute,
      );
    }
    final year = due.year + 1;
    final lastDay = DateTime(year, anchor.month + 1, 0).day;
    final day = anchor.day > lastDay ? lastDay : anchor.day;
    return DateTime(year, anchor.month, day, anchor.hour, anchor.minute);
  }
}
