import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
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
    if (!const {'cash', 'bank', 'ewallet', 'other'}.contains(type)) {
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
    final deleted = await (database.delete(
      database.accounts,
    )..where((row) => row.id.equals(id))).go();
    if (deleted == 0) {
      throw const MoneyValidationException('Akun tidak ditemukan.');
    }
  }

  Future<String> saveCategory({
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
    final id = _uuid.v4();
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            name: cleanName,
            type: type,
            icon: icon,
            createdAt: DateTime.now(),
          ),
        );
    return id;
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
    if (account == null) {
      throw const MoneyValidationException('Akun tidak ditemukan.');
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
      if (destination == null) {
        throw const MoneyValidationException('Akun tujuan tidak ditemukan.');
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
      if (category == null || category.type != type) {
        throw const MoneyValidationException(
          'Kategori tidak sesuai transaksi.',
        );
      }
      destinationAccountId = null;
    }
    final now = DateTime.now();
    final cleanNote = note?.trim();
    if (id == null) {
      final newId = _uuid.v4();
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
      return newId;
    }
    final existing = await (database.select(
      database.moneyTransactions,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw const MoneyValidationException('Transaksi tidak ditemukan.');
    }
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
    return id;
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
