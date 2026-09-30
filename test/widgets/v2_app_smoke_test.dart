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
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('V2 core screens and keyboard-aware composer render at 320 px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = MoneyRepository(database);
    await database.getAllCategories();
    final bca = await repository.saveAccount(
      name: 'Bank BCA',
      type: 'bank',
      initialBalance: 1000000,
      icon: 'account_balance',
    );
    final dana = await repository.saveAccount(
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
      note: 'Gaji',
      transactionDate: now,
    );
    await repository.saveTransaction(
      type: 'expense',
      amount: 125750000,
      accountId: bca,
      categoryId: 'expense-shopping',
      note: 'Belanja bulanan keluarga',
      transactionDate: now,
    );
    await repository.saveTransaction(
      type: 'transfer',
      amount: 200000,
      accountId: bca,
      destinationAccountId: dana,
      transactionDate: now,
    );

    Get.testMode = true;
    await Get.putAsync(() => PrivacyService().init(), permanent: true);
    final preferences = await Get.putAsync(
      () => AppPreferencesService().init(),
      permanent: true,
    );
    Get.put(CurrencyService(preferences), permanent: true);
    Get.put(MoneyController(repository), permanent: true);
    Get.put(BudgetController(BudgetRepository(database)), permanent: true);
    Get.put(SavingsController(SavingsRepository(database)), permanent: true);
    Get.put(
      RecurringController(RecurringRepository(database, repository)),
      permanent: true,
    );
    Get.put(ReportsController(const ReportRepository()), permanent: true);
    Get.put(const ReportRepository(), permanent: true);
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const MainShell(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Uang'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Aktivitas Terbaru'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Cari transaksi'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengeluaran per Kategori'), findsOneWidget);
    expect(find.byKey(const Key('expense-donut-painter')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Catat Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar'), findsWidgets);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Transfer'), findsWidgets);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transaction-save-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
