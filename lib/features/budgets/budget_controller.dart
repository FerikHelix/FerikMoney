import 'dart:async';

import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/budget_repository.dart';
import '../../utils/balance_adjustment.dart';
import '../main/money_controller.dart';

class BudgetController extends GetxController {
  BudgetController(this.repository);

  final BudgetRepository repository;
  final budgets = <Budget>[].obs;
  StreamSubscription<List<Budget>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = repository.watchBudgets().listen(budgets.assignAll);
  }

  List<BudgetProgress> progressFor(DateTime month) {
    final money = Get.find<MoneyController>();
    final result = <BudgetProgress>[];
    for (final budget in budgets.where((item) => item.isActive)) {
      var spent = 0;
      for (final transaction in money.transactions) {
        if (transaction.type != 'expense' ||
            isAdjustmentCategory(transaction.categoryId) ||
            transaction.transactionDate.year != month.year ||
            transaction.transactionDate.month != month.month) {
          continue;
        }
        if (budget.categoryId == null ||
            transaction.categoryId == budget.categoryId) {
          spent += transaction.amount;
        }
      }
      result.add(BudgetProgress(budget: budget, spent: spent));
    }
    return result;
  }

  BudgetProgress? overallFor(DateTime month) {
    for (final item in progressFor(month)) {
      if (item.budget.categoryId == null) return item;
    }
    return null;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
