import 'dart:async';

import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../repositories/savings_repository.dart';

class SavingsController extends GetxController {
  SavingsController(this.repository);

  final SavingsRepository repository;
  final goals = <SavingsGoalWithProgress>[].obs;
  final transfers = <SavingsGoalTransfer>[].obs;
  StreamSubscription<List<SavingsGoalWithProgress>>? _goalSubscription;
  StreamSubscription<List<SavingsGoalTransfer>>? _transferSubscription;

  int get totalSaved => goals.fold<int>(0, (total, item) => total + item.saved);

  @override
  void onInit() {
    super.onInit();
    _goalSubscription = repository.watchGoals().listen(goals.assignAll);
    _transferSubscription = repository.watchTransfers().listen(
      transfers.assignAll,
    );
  }

  SavingsGoalWithProgress? goalById(String id) {
    for (final item in goals) {
      if (item.goal.id == id) return item;
    }
    return null;
  }

  @override
  void onClose() {
    _goalSubscription?.cancel();
    _transferSubscription?.cancel();
    super.onClose();
  }
}
