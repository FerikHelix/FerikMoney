import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../utils/balance_adjustment.dart';
import '../utils/money_formatter.dart';

class MoneyValidationException implements Exception {
  const MoneyValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MoneyRepository {
  MoneyRepository(this.database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final Uuid _uuid;

  Stream<List<AccountWithBalance>> watchAccounts() =>
      database.watchAccountsWithBalances();
  Stream<List<Category>> watchCategories() => database.watchAllCategories();
  Stream<List<MoneyTransaction>> watchTransactions() =>
      database.watchAllTransactions();
  Stream<List<Tag>> watchTags() => database.watchAllTags();
  Stream<List<TransactionTag>> watchTransactionTags() =>
      database.watchAllTransactionTags();

  Future<String> saveAccount({
    String? id,
    required String name,
    required String type,
    required int initialBalance,
    required String icon,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const MoneyValidationException('Nama akun wajib diisi.');
    }
    if (!const {'cash', 'bank', 'ewallet', 'savings', 'other'}.contains(type)) {
      throw const MoneyValidationException('Jenis akun tidak valid.');
    }
    if (initialBalance < 0) {
      throw const MoneyValidationException('Saldo awal tidak boleh negatif.');
    }
    if (initialBalance > maxMoneyAmount) {
      throw const MoneyValidationException('Saldo awal terlalu besar.');
    }
    final now = DateTime.now();
    if (id == null) {
      final newId = _uuid.v4();
      await database
          .into(database.accounts)
          .insert(
            AccountsCompanion.insert(
              id: newId,
              name: cleanName,
              type: type,
              initialBalance: initialBalance,
              icon: icon,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return newId;
    }
    final existing = await (database.select(
      database.accounts,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw const MoneyValidationException('Akun tidak ditemukan.');
    }
    await (database.update(
      database.accounts,
    )..where((row) => row.id.equals(id))).write(
      AccountsCompanion(
        name: Value(cleanName),
        type: Value(type),
        initialBalance: Value(initialBalance),
        icon: Value(icon),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  /// Sets a wallet's current balance to [newBalance] by recording the
  /// difference as an income/expense "Penyesuaian saldo" transaction, so the
  /// change is visible in History. Returns the signed difference (0 = no-op).
  Future<int> adjustBalance({
    required String accountId,
    required int newBalance,
    String? note,
  }) async {
    if (newBalance < 0) {
      throw const MoneyValidationException('Saldo tidak boleh negatif.');
    }
    if (newBalance > maxMoneyAmount) {
      throw const MoneyValidationException('Saldo terlalu besar.');
    }
    return database.transaction(() async {
      final account = await (database.select(
        database.accounts,
      )..where((row) => row.id.equals(accountId))).getSingleOrNull();
      if (account == null) {
        throw const MoneyValidationException('Akun tidak ditemukan.');
      }
      final delta = newBalance - await database.accountBalance(accountId);
      if (delta == 0) return 0;
      if (delta.abs() > maxMoneyAmount) {
        throw const MoneyValidationException('Selisih saldo terlalu besar.');
      }
      final income = delta > 0;
      final categoryId = income
          ? adjustmentIncomeCategoryId
          : adjustmentExpenseCategoryId;
      final now = DateTime.now();
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: categoryId,
              name: adjustmentCategoryName,
              type: income ? 'income' : 'expense',
              icon: adjustmentCategoryIcon,
              createdAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      final cleanNote = note?.trim();
      await database
          .into(database.moneyTransactions)
          .insert(
            MoneyTransactionsCompanion.insert(
              id: _uuid.v4(),
              type: income ? 'income' : 'expense',
              amount: delta.abs(),
              accountId: accountId,
              categoryId: Value(categoryId),
              note: Value(
                cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
              ),
              transactionDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return delta;
    });
  }

  Future<void> archiveAccount(String id, {required bool archived}) async {
    final now = DateTime.now();
    final changed =
        await (database.update(
          database.accounts,
        )..where((row) => row.id.equals(id))).write(
          AccountsCompanion(isArchived: Value(archived), updatedAt: Value(now)),
        );
    if (changed == 0) {
      throw const MoneyValidationException('Akun tidak ditemukan.');
    }
    if (archived) {
      await (database.update(database.recurringRules)..where(
            (row) =>
                row.accountId.equals(id) | row.destinationAccountId.equals(id),
          ))
          .write(
            RecurringRulesCompanion(
              isPaused: const Value(true),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Future<void> deleteAccount(String id) async {
    final reference =
        await (database.select(database.moneyTransactions)
              ..where(
                (row) =>
                    row.accountId.equals(id) |
                    row.destinationAccountId.equals(id),
              )
              ..limit(1))
            .getSingleOrNull();
    if (reference != null) {
      throw const MoneyValidationException(
        'Akun tidak dapat dihapus karena masih digunakan oleh transaksi.',
      );
    }
    final goalTransfer =
        await (database.select(database.savingsGoalTransfers)
              ..where((row) => row.accountId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (goalTransfer != null) {
      throw const MoneyValidationException(
        'Akun tidak dapat dihapus karena masih dipakai transfer tabungan.',
      );
    }
    final rule =
        await (database.select(database.recurringRules)
              ..where(
                (row) =>
                    row.accountId.equals(id) |
                    row.destinationAccountId.equals(id),
              )
              ..limit(1))
            .getSingleOrNull();
    if (rule != null) {
      throw const MoneyValidationException(
        'Akun tidak dapat dihapus karena masih dipakai transaksi berulang.',
      );
    }
    final deleted = await (database.delete(
      database.accounts,
    )..where((row) => row.id.equals(id))).go();
    if (deleted == 0) {
      throw const MoneyValidationException('Akun tidak ditemukan.');
    }
  }

  Future<String> saveCategory({
    String? id,
    required String name,
    required String type,
    String icon = 'label',
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const MoneyValidationException('Nama kategori wajib diisi.');
    }
    if (!const {'income', 'expense'}.contains(type)) {
      throw const MoneyValidationException('Jenis kategori tidak valid.');
    }
    if (id == null) {
      final newId = _uuid.v4();
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: newId,
              name: cleanName,
              type: type,
              icon: icon,
              createdAt: DateTime.now(),
            ),
          );
      return newId;
    }
    final changed =
        await (database.update(
          database.categories,
        )..where((row) => row.id.equals(id))).write(
          CategoriesCompanion(name: Value(cleanName), icon: Value(icon)),
        );
    if (changed == 0) {
      throw const MoneyValidationException('Kategori tidak ditemukan.');
    }
    return id;
  }

  Future<void> archiveCategory(String id, {required bool archived}) async {
    final changed =
        await (database.update(database.categories)
              ..where((row) => row.id.equals(id)))
            .write(CategoriesCompanion(isArchived: Value(archived)));
    if (changed == 0) {
      throw const MoneyValidationException('Kategori tidak ditemukan.');
    }
    if (archived) {
      await (database.update(
        database.recurringRules,
      )..where((row) => row.categoryId.equals(id))).write(
        RecurringRulesCompanion(
          isPaused: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    final reference =
        await (database.select(database.moneyTransactions)
              ..where((row) => row.categoryId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (reference != null) {
      throw const MoneyValidationException(
        'Kategori tidak dapat dihapus karena masih digunakan oleh transaksi.',
      );
    }
    final deleted = await (database.delete(
      database.categories,
    )..where((row) => row.id.equals(id))).go();
    if (deleted == 0) {
      throw const MoneyValidationException('Kategori tidak ditemukan.');
    }
  }

  Future<String> saveTransaction({
    String? id,
    required String type,
    required int amount,
    required String accountId,
    String? destinationAccountId,
    String? categoryId,
    String? note,
    List<String> tags = const [],
    required DateTime transactionDate,
  }) async {
    if (!const {'income', 'expense', 'transfer'}.contains(type)) {
      throw const MoneyValidationException('Jenis transaksi tidak valid.');
    }
    if (amount <= 0) {
      throw const MoneyValidationException('Nominal harus lebih dari nol.');
    }
    if (amount > maxMoneyAmount) {
      throw const MoneyValidationException('Nominal terlalu besar.');
    }
    final account = await (database.select(
      database.accounts,
    )..where((row) => row.id.equals(accountId))).getSingleOrNull();
    if (account == null || account.isArchived) {
      throw const MoneyValidationException('Akun tidak tersedia.');
    }
    if (type == 'transfer') {
      if (destinationAccountId == null) {
        throw const MoneyValidationException('Akun tujuan wajib dipilih.');
      }
      if (destinationAccountId == accountId) {
        throw const MoneyValidationException(
          'Akun asal dan tujuan harus berbeda.',
        );
      }
      final destinationId = destinationAccountId;
      final destination = await (database.select(
        database.accounts,
      )..where((row) => row.id.equals(destinationId))).getSingleOrNull();
      if (destination == null || destination.isArchived) {
        throw const MoneyValidationException('Akun tujuan tidak tersedia.');
      }
      categoryId = null;
    } else {
      if (categoryId == null) {
        throw const MoneyValidationException('Kategori wajib dipilih.');
      }
      final selectedCategoryId = categoryId;
      final category = await (database.select(
        database.categories,
      )..where((row) => row.id.equals(selectedCategoryId))).getSingleOrNull();
      if (category == null || category.isArchived || category.type != type) {
        throw const MoneyValidationException(
          'Kategori tidak sesuai transaksi.',
        );
      }
      destinationAccountId = null;
    }
    final now = DateTime.now();
    final cleanNote = note?.trim();
    if (tags.length > 10) {
      throw const MoneyValidationException('Maksimal 10 tag per transaksi.');
    }
    if (id == null) {
      final newId = _uuid.v4();
      await database.transaction(() async {
        await database
            .into(database.moneyTransactions)
            .insert(
              MoneyTransactionsCompanion.insert(
                id: newId,
                type: type,
                amount: amount,
                accountId: accountId,
                destinationAccountId: Value(destinationAccountId),
                categoryId: Value(categoryId),
                note: Value(cleanNote?.isEmpty == true ? null : cleanNote),
                transactionDate: transactionDate,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _syncTags(newId, tags);
      });
      return newId;
    }
    final existing = await (database.select(
      database.moneyTransactions,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw const MoneyValidationException('Transaksi tidak ditemukan.');
    }
    await database.transaction(() async {
      await (database.update(
        database.moneyTransactions,
      )..where((row) => row.id.equals(id))).write(
        MoneyTransactionsCompanion(
          type: Value(type),
          amount: Value(amount),
          accountId: Value(accountId),
          destinationAccountId: Value(destinationAccountId),
          categoryId: Value(categoryId),
          note: Value(cleanNote?.isEmpty == true ? null : cleanNote),
          transactionDate: Value(transactionDate),
          updatedAt: Value(now),
        ),
      );
      await _syncTags(id, tags);
    });
    return id;
  }

  Future<void> restoreTransaction(
    MoneyTransaction transaction, {
    List<String> tags = const [],
  }) async {
    await database.transaction(() async {
      await database
          .into(database.moneyTransactions)
          .insert(
            MoneyTransactionsCompanion.insert(
              id: transaction.id,
              type: transaction.type,
              amount: transaction.amount,
              accountId: transaction.accountId,
              destinationAccountId: Value(transaction.destinationAccountId),
              categoryId: Value(transaction.categoryId),
              note: Value(transaction.note),
              transactionDate: transaction.transactionDate,
              createdAt: transaction.createdAt,
              updatedAt: transaction.updatedAt,
            ),
          );
      await _syncTags(transaction.id, tags);
    });
  }

  Future<void> _syncTags(String transactionId, List<String> names) async {
    await (database.delete(
      database.transactionTags,
    )..where((row) => row.transactionId.equals(transactionId))).go();
    final cleaned = <String, String>{};
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      if (name.length > 40) {
        throw const MoneyValidationException('Nama tag maksimal 40 karakter.');
      }
      cleaned.putIfAbsent(name.toLowerCase(), () => name);
    }
    for (final entry in cleaned.entries) {
      final existing =
          await (database.select(database.tags)
                ..where((row) => row.normalizedName.equals(entry.key)))
              .getSingleOrNull();
      final tagId = existing?.id ?? _uuid.v4();
      if (existing == null) {
        await database
            .into(database.tags)
            .insert(
              TagsCompanion.insert(
                id: tagId,
                name: entry.value,
                normalizedName: entry.key,
                createdAt: DateTime.now(),
              ),
            );
      }
      await database
          .into(database.transactionTags)
          .insert(
            TransactionTagsCompanion.insert(
              transactionId: transactionId,
              tagId: tagId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<void> deleteTransaction(String id) async {
    final deleted = await (database.delete(
      database.moneyTransactions,
    )..where((row) => row.id.equals(id))).go();
    if (deleted == 0) {
      throw const MoneyValidationException('Transaksi tidak ditemukan.');
    }
  }
}
