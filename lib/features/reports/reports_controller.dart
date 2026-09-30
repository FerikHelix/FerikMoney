import 'package:get/get.dart';

import '../../models/finance_models.dart';
import '../../repositories/report_repository.dart';
import '../../services/app_preferences_service.dart';
import '../main/money_controller.dart';

class ReportsController extends GetxController {
  ReportsController(this.repository);

  final ReportRepository repository;
  final period = FinancePeriod.month.obs;
  final anchor = DateTime.now().obs;

  ReportSnapshot get snapshot {
    final money = Get.find<MoneyController>();
    final preferences = Get.find<AppPreferencesService>();
    return repository.build(
      transactions: money.transactions,
      period: period.value,
      anchor: anchor.value,
      firstWeekday: preferences.firstWeekday.value,
    );
  }

  void previous() {
    final value = anchor.value;
    anchor.value = switch (period.value) {
      FinancePeriod.week => value.subtract(const Duration(days: 7)),
      FinancePeriod.month => DateTime(value.year, value.month - 1),
      FinancePeriod.year => DateTime(value.year - 1),
    };
  }

  void next() {
    final value = anchor.value;
    anchor.value = switch (period.value) {
      FinancePeriod.week => value.add(const Duration(days: 7)),
      FinancePeriod.month => DateTime(value.year, value.month + 1),
      FinancePeriod.year => DateTime(value.year + 1),
    };
  }
}
