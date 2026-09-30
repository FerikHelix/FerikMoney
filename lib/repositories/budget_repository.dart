import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../repositories/money_repository.dart';
import '../utils/money_formatter.dart';

class BudgetRepository {
  BudgetRepository(this.database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final Uuid _uuid;

  Stream<List<Budget>> watchBudgets() => database.watchAllBudgets();

  Future<String> save({
    String? id,
    String? categoryId,
    required int amount,
  }) async {
    if (amount <= 0 || amount > maxMoneyAmount) {
      throw const MoneyValidationException('Nominal budget tidak valid.');
    }
    if (categoryId != null) {
      final category =
          await (database.select(database.categories)..where(
                (row) => row.id.equals(categoryId) & row.type.equals('expense'),
              ))
              .getSingleOrNull();
      if (category == null || category.isArchived) {
        throw const MoneyValidationException(
          'Kategori pengeluaran tidak tersedia.',
        );
      }
    }
    final duplicateQuery = database.select(database.budgets)
      ..where((row) {
        final sameScope = categoryId == null
            ? row.categoryId.isNull()
            : row.categoryId.equals(categoryId);
        return sameScope & row.isActive.equals(true);
      });
    final duplicate = await duplicateQuery.getSingleOrNull();
    if (duplicate != null && duplicate.id != id) {
      throw const MoneyValidationException(
        'Budget untuk cakupan ini sudah tersedia.',
      );
    }
    final now = DateTime.now();
    if (id == null) {
      final newId = _uuid.v4();
      await database
          .into(database.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: newId,
              categoryId: Value(categoryId),
              amount: amount,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return newId;
    }
    final changed =
        await (database.update(
          database.budgets,
        )..where((row) => row.id.equals(id))).write(
          BudgetsCompanion(
            categoryId: Value(categoryId),
            amount: Value(amount),
            updatedAt: Value(now),
          ),
        );
    if (changed == 0) {
      throw const MoneyValidationException('Budget tidak ditemukan.');
    }
    return id;
  }

  Future<void> delete(String id) async {
    await (database.delete(
      database.budgets,
    )..where((row) => row.id.equals(id))).go();
  }
}
