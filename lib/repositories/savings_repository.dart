import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/finance_models.dart';
import '../repositories/money_repository.dart';
import '../utils/money_formatter.dart';

class SavingsRepository {
  SavingsRepository(this.database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final Uuid _uuid;

  Stream<List<SavingsGoalWithProgress>> watchGoals() =>
      database.watchSavingsGoalsWithProgress();
  Stream<List<SavingsGoalTransfer>> watchTransfers() =>
      database.watchAllSavingsGoalTransfers();

  Future<String> saveGoal({
    String? id,
    required String name,
    required int targetAmount,
    DateTime? targetDate,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const MoneyValidationException('Nama target wajib diisi.');
    }
    if (targetAmount <= 0 || targetAmount > maxMoneyAmount) {
      throw const MoneyValidationException('Nominal target tidak valid.');
    }
    final now = DateTime.now();
    if (id == null) {
      final newId = _uuid.v4();
      await database
          .into(database.savingsGoals)
          .insert(
            SavingsGoalsCompanion.insert(
              id: newId,
              name: cleanName,
              targetAmount: targetAmount,
              targetDate: Value(targetDate),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return newId;
    }
    final changed =
        await (database.update(
          database.savingsGoals,
        )..where((row) => row.id.equals(id))).write(
          SavingsGoalsCompanion(
            name: Value(cleanName),
            targetAmount: Value(targetAmount),
            targetDate: Value(targetDate),
            updatedAt: Value(now),
          ),
        );
    if (changed == 0) {
      throw const MoneyValidationException('Target tabungan tidak ditemukan.');
    }
    return id;
  }

  Future<void> archiveGoal(String id, {required bool archived}) async {
    await (database.update(
      database.savingsGoals,
    )..where((row) => row.id.equals(id))).write(
      SavingsGoalsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String> transfer({
    required String goalId,
    required String accountId,
    required GoalTransferType type,
    required int amount,
    String? note,
    required DateTime date,
  }) async {
    if (amount <= 0 || amount > maxMoneyAmount) {
      throw const MoneyValidationException('Nominal transfer tidak valid.');
    }
    final goal = await (database.select(
      database.savingsGoals,
    )..where((row) => row.id.equals(goalId))).getSingleOrNull();
    if (goal == null || goal.isArchived) {
      throw const MoneyValidationException('Target tabungan tidak tersedia.');
    }
    final account = await (database.select(
      database.accounts,
    )..where((row) => row.id.equals(accountId))).getSingleOrNull();
    if (account == null || account.isArchived) {
      throw const MoneyValidationException('Akun tidak tersedia.');
    }
    if (type == GoalTransferType.withdrawal) {
      final progress = await database.watchSavingsGoalsWithProgress().first;
      final saved = progress
          .where((item) => item.goal.id == goalId)
          .map((item) => item.saved)
          .firstOrNull;
      if (saved == null || amount > saved) {
        throw const MoneyValidationException(
          'Nominal penarikan melebihi dana target.',
        );
      }
    }
    final id = _uuid.v4();
    await database
        .into(database.savingsGoalTransfers)
        .insert(
          SavingsGoalTransfersCompanion.insert(
            id: id,
            goalId: goalId,
            accountId: accountId,
            type: type.name,
            amount: amount,
            note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
            transferDate: date,
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  /// Removes a deposit/withdrawal. A deposit cannot be removed if later
  /// withdrawals would then exceed the money left in the goal.
  Future<void> deleteTransfer(String id) async {
    final transfer = await (database.select(
      database.savingsGoalTransfers,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (transfer == null) {
      throw const MoneyValidationException('Transfer tidak ditemukan.');
    }
    if (transfer.type == GoalTransferType.deposit.name) {
      final progress = await database.watchSavingsGoalsWithProgress().first;
      final saved = progress
          .where((item) => item.goal.id == transfer.goalId)
          .map((item) => item.saved)
          .firstOrNull;
      if (saved != null && saved - transfer.amount < 0) {
        throw const MoneyValidationException(
          'Setoran ini tidak bisa dihapus karena dananya sudah ditarik.',
        );
      }
    }
    await (database.delete(
      database.savingsGoalTransfers,
    )..where((row) => row.id.equals(id))).go();
  }

  /// Puts a just-deleted transfer back exactly as it was (used by Undo).
  Future<void> restoreTransfer(SavingsGoalTransfer transfer) async {
    await database
        .into(database.savingsGoalTransfers)
        .insert(
          SavingsGoalTransfersCompanion.insert(
            id: transfer.id,
            goalId: transfer.goalId,
            accountId: transfer.accountId,
            type: transfer.type,
            amount: transfer.amount,
            note: Value(transfer.note),
            transferDate: transfer.transferDate,
            createdAt: transfer.createdAt,
          ),
        );
  }
}
