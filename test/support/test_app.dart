import 'package:drift/native.dart';
import 'package:ferikmoney/app/theme/app_theme.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/features/budgets/budget_controller.dart';
import 'package:ferikmoney/features/main/main_shell.dart';
import 'package:ferikmoney/features/main/money_controller.dart';
import 'package:ferikmoney/features/recurring/recurring_controller.dart';
import 'package:ferikmoney/features/reports/reports_controller.dart';
import 'package:ferikmoney/features/savings/savings_controller.dart';
import 'package:ferikmoney/repositories/budget_repository.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
import 'package:ferikmoney/repositories/recurring_repository.dart';
import 'package:ferikmoney/repositories/report_repository.dart';
import 'package:ferikmoney/repositories/savings_repository.dart';
import 'package:ferikmoney/services/app_preferences_service.dart';
import 'package:ferikmoney/services/currency_service.dart';
import 'package:ferikmoney/services/privacy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles to a running test app: an in-memory database with two wallets and
/// two transactions, wired the same way as the real app.
class TestApp {
  TestApp(this.database, this.repository, this.bca, this.dana);

  final AppDatabase database;
  final MoneyRepository repository;
  final String bca;
  final String dana;
}

/// Boots [MainShell] (or [home]) at 320 px wide.
///
/// Seeds wallets "Bank BCA" (bank, Rp 1.000.000) and "DANA" (e-wallet,
/// Rp 500.000), plus "Gaji bulanan" (+500.000) and "Makan siang" (-25.000)
/// dated now. Pass [seed] false for an empty database (first-run state).
Future<TestApp> pumpApp(
  WidgetTester tester, {
  Widget? home,
  bool seed = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 700);
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(database.close);
  final repository = MoneyRepository(database);
  await database.getAllCategories();
  var bca = '';
  var dana = '';
  if (seed) {
    bca = await repository.saveAccount(
      name: 'Bank BCA',
      type: 'bank',
      initialBalance: 1000000,
      icon: 'account_balance',
    );
    dana = await repository.saveAccount(
      name: 'DANA',
      type: 'ewallet',
      initialBalance: 500000,
      icon: 'smartphone',
    );
    final now = DateTime.now();
    await repository.saveTransaction(
      type: 'income',
      amount: 500000,
      accountId: bca,
      categoryId: 'income-salary',
      note: 'Gaji bulanan',
      transactionDate: now,
    );
    await repository.saveTransaction(
      type: 'expense',
      amount: 25000,
      accountId: bca,
      categoryId: 'expense-food',
      note: 'Makan siang',
      transactionDate: now,
    );
  }

  Get.testMode = true;
  await Get.putAsync(() => PrivacyService().init(), permanent: true);
  final preferences = await Get.putAsync(
    () => AppPreferencesService().init(),
    permanent: true,
  );
  Get.put(CurrencyService(preferences), permanent: true);
  Get.put(repository, permanent: true);
  Get.put(MoneyController(repository), permanent: true);
  Get.put(BudgetRepository(database), permanent: true);
  Get.put(BudgetController(Get.find<BudgetRepository>()), permanent: true);
  final savingsRepository = SavingsRepository(database);
  Get.put(savingsRepository, permanent: true);
  Get.put(SavingsController(savingsRepository), permanent: true);
  final recurringRepository = RecurringRepository(database, repository);
  Get.put(recurringRepository, permanent: true);
  Get.put(RecurringController(recurringRepository), permanent: true);
  Get.put(ReportsController(const ReportRepository()), permanent: true);
  Get.put(const ReportRepository(), permanent: true);
  addTearDown(Get.reset);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: home ?? const MainShell(),
    ),
  );
  await tester.pumpAndSettle();
  return TestApp(database, repository, bca, dana);
}

/// Lets real (non-fake) async work such as database writes finish, then
/// settles the UI and lets confirmation snackbars time out so no timer
/// outlives the test.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}
