import 'dart:async';

import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/money_repository.dart';
import '../savings/savings_controller.dart';

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
  final tags = <Tag>[].obs;
  final transactionTags = <TransactionTag>[].obs;
  final navigationIndex = 0.obs;
  final loading = true.obs;
  final databaseError = RxnString();

  StreamSubscription<List<AccountWithBalance>>? _accountSubscription;
  StreamSubscription<List<Category>>? _categorySubscription;
  StreamSubscription<List<MoneyTransaction>>? _transactionSubscription;
  StreamSubscription<List<Tag>>? _tagSubscription;
  StreamSubscription<List<TransactionTag>>? _transactionTagSubscription;

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
    _tagSubscription = repository.watchTags().listen(tags.assignAll);
    _transactionTagSubscription = repository.watchTransactionTags().listen(
      transactionTags.assignAll,
    );
  }

  void _onDatabaseError(Object error) {
    loading.value = false;
    databaseError.value =
        'Data lokal tidak dapat dibaca. Coba buka ulang aplikasi.';
  }

  int get totalBalance {
    final walletTotal = accounts.fold<int>(
      0,
      (total, item) => total + item.balance,
    );
    final goalTotal = Get.isRegistered<SavingsController>()
        ? Get.find<SavingsController>().totalSaved
        : 0;
    return walletTotal + goalTotal;
  }

  List<AccountWithBalance> get activeAccounts =>
      accounts.where((item) => !item.account.isArchived).toList();

  List<Category> get activeCategories =>
      categories.where((item) => !item.isArchived).toList();

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

  List<Tag> tagsForTransaction(String transactionId) {
    final ids = transactionTags
        .where((item) => item.transactionId == transactionId)
        .map((item) => item.tagId)
        .toSet();
    return tags.where((item) => ids.contains(item.id)).toList();
  }

  List<Category> frequentCategories(String type, {int limit = 4}) {
    final counts = <String, int>{};
    for (final transaction in transactions) {
      if (transaction.type == type && transaction.categoryId != null) {
        counts.update(
          transaction.categoryId!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final values = activeCategories.where((item) => item.type == type).toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    return values.take(limit).toList();
  }

  List<FinanceActivity> get activities {
    final result = transactions
        .map(
          (transaction) => FinanceActivity.transaction(
            TransactionWithTags(
              transaction: transaction,
              tags: tagsForTransaction(transaction.id),
            ),
          ),
        )
        .toList();
    if (Get.isRegistered<SavingsController>()) {
      result.addAll(
        Get.find<SavingsController>().transfers.map(
          FinanceActivity.goalTransfer,
        ),
      );
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
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
    _tagSubscription?.cancel();
    _transactionTagSubscription?.cancel();
    super.onClose();
  }
}
