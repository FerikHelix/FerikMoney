import 'dart:async';

import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';

class CategoryTotal {
  const CategoryTotal({required this.category, required this.amount});
  final Category category;
  final int amount;
}

class MoneyController extends GetxController {
  MoneyController(this.repository);

  final MoneyRepository repository;
  final accounts = <AccountWithBalance>[].obs;
  final categories = <Category>[].obs;
  final transactions = <MoneyTransaction>[].obs;
  final navigationIndex = 0.obs;
  final loading = true.obs;
  final databaseError = RxnString();

  StreamSubscription<List<AccountWithBalance>>? _accountSubscription;
  StreamSubscription<List<Category>>? _categorySubscription;
  StreamSubscription<List<MoneyTransaction>>? _transactionSubscription;

  @override
  void onInit() {
    super.onInit();
    _accountSubscription = repository.watchAccounts().listen((value) {
      accounts.assignAll(value);
      loading.value = false;
      databaseError.value = null;
    }, onError: _onDatabaseError);
    _categorySubscription = repository.watchCategories().listen(
      categories.assignAll,
      onError: _onDatabaseError,
    );
    _transactionSubscription = repository.watchTransactions().listen(
      transactions.assignAll,
      onError: _onDatabaseError,
    );
  }

  void _onDatabaseError(Object error) {
    loading.value = false;
    databaseError.value =
        'Data lokal tidak dapat dibaca. Coba buka ulang aplikasi.';
  }

  int get totalBalance =>
      accounts.fold(0, (total, item) => total + item.balance);

  AccountWithBalance? accountById(String? id) {
    if (id == null) return null;
    for (final item in accounts) {
      if (item.account.id == id) return item;
    }
    return null;
  }

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final item in categories) {
      if (item.id == id) return item;
    }
    return null;
  }

  MonthlySummary summaryFor(DateTime month) {
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      if (transaction.transactionDate.year != month.year ||
          transaction.transactionDate.month != month.month) {
        continue;
      }
      if (transaction.type == 'income') income += transaction.amount;
      if (transaction.type == 'expense') expense += transaction.amount;
    }
    return MonthlySummary(income: income, expense: expense);
  }

  List<CategoryTotal> categoryTotalsFor(DateTime month) {
    final totals = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.type == 'expense' &&
          transaction.transactionDate.year == month.year &&
          transaction.transactionDate.month == month.month &&
          transaction.categoryId != null) {
        totals.update(
          transaction.categoryId!,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    final result = <CategoryTotal>[];
    for (final entry in totals.entries) {
      final category = categoryById(entry.key);
      if (category != null) {
        result.add(CategoryTotal(category: category, amount: entry.value));
      }
    }
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  @override
  void onClose() {
    _accountSubscription?.cancel();
    _categorySubscription?.cancel();
    _transactionSubscription?.cancel();
    super.onClose();
  }
}
