import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../features/budgets/budget_controller.dart';
import '../../features/main/money_controller.dart';
import '../../features/recurring/recurring_controller.dart';
import '../../features/reports/reports_controller.dart';
import '../../features/savings/savings_controller.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/money_repository.dart';
import '../../repositories/recurring_repository.dart';
import '../../repositories/report_repository.dart';
import '../../repositories/savings_repository.dart';
import '../../services/backup_service.dart';
import '../../services/app_preferences_service.dart';
import '../../services/privacy_service.dart';
import '../../services/theme_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppDatabase(), permanent: true);
    final moneyRepository = Get.put(
      MoneyRepository(Get.find()),
      permanent: true,
    );
    final budgetRepository = Get.put(
      BudgetRepository(Get.find()),
      permanent: true,
    );
    final recurringRepository = Get.put(
      RecurringRepository(Get.find(), moneyRepository),
      permanent: true,
    );
    final savingsRepository = Get.put(
      SavingsRepository(Get.find()),
      permanent: true,
    );
    final reportRepository = Get.put(const ReportRepository(), permanent: true);
    Get.put(
      BackupService(
        Get.find(),
        preferences: Get.find<AppPreferencesService>(),
        themeService: Get.find<ThemeService>(),
        privacyService: Get.find<PrivacyService>(),
      ),
      permanent: true,
    );
    Get.put(MoneyController(moneyRepository), permanent: true);
    Get.put(BudgetController(budgetRepository), permanent: true);
    Get.put(RecurringController(recurringRepository), permanent: true);
    Get.put(SavingsController(savingsRepository), permanent: true);
    Get.put(ReportsController(reportRepository), permanent: true);
  }
}
