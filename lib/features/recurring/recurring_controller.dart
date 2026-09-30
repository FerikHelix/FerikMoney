import 'dart:async';

import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../repositories/recurring_repository.dart';

class RecurringController extends GetxController {
  RecurringController(this.repository);

  final RecurringRepository repository;
  final rules = <RecurringRule>[].obs;
  final pending = <RecurringOccurrence>[].obs;
  final loading = true.obs;
  StreamSubscription<List<RecurringRule>>? _ruleSubscription;
  StreamSubscription<List<RecurringOccurrence>>? _pendingSubscription;

  @override
  void onInit() {
    super.onInit();
    _ruleSubscription = repository.watchRules().listen(rules.assignAll);
    _pendingSubscription = repository.watchPending().listen((value) {
      pending.assignAll(value);
      loading.value = false;
    });
    repository.generateDue().catchError((_) {
      loading.value = false;
    });
  }

  RecurringRule? ruleById(String id) {
    for (final rule in rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  @override
  void onClose() {
    _ruleSubscription?.cancel();
    _pendingSubscription?.cancel();
    super.onClose();
  }
}
