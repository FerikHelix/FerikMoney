import 'dart:async';

import 'package:drift/native.dart';
import 'package:ferikmoney/app/theme/app_theme.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/features/accounts/account_form_sheet.dart';
import 'package:ferikmoney/features/budgets/budget_controller.dart';
import 'package:ferikmoney/features/main/main_shell.dart';
import 'package:ferikmoney/features/main/money_controller.dart';
import 'package:ferikmoney/features/recurring/recurring_controller.dart';
import 'package:ferikmoney/features/reports/reports_controller.dart';
import 'package:ferikmoney/features/savings/savings_controller.dart';
import 'package:ferikmoney/models/finance_models.dart';
import 'package:ferikmoney/repositories/budget_repository.dart';
import 'package:ferikmoney/repositories/money_repository.dart';
import 'package:ferikmoney/repositories/recurring_repository.dart';
import 'package:ferikmoney/repositories/report_repository.dart';
import 'package:ferikmoney/repositories/savings_repository.dart';
import 'package:ferikmoney/services/app_preferences_service.dart';
import 'package:ferikmoney/services/currency_service.dart';
import 'package:ferikmoney/services/privacy_service.dart';
import 'package:ferikmoney/utils/balance_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Harness {
  _Harness(this.database, this.repository, this.bca, this.dana);

  final AppDatabase database;
  final MoneyRepository repository;
  final String bca;
  final String dana;
}

Future<_Harness> _pumpApp(WidgetTester tester, {Widget? home}) async {
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

  Get.testMode = true;
  await Get.putAsync(() => PrivacyService().init(), permanent: true);
  final preferences = await Get.putAsync(
    () => AppPreferencesService().init(),
    permanent: true,
  );
  Get.put(CurrencyService(preferences), permanent: true);
  Get.put(repository, permanent: true);
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
      home: home ?? const MainShell(),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(database, repository, bca, dana);
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.text('Transaksi'));
  await tester.pumpAndSettle();
}

/// Lets real (non-fake) async work such as database writes finish, then
/// settles the UI.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  // Let the confirmation snackbar time out so no timer outlives the test.
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Future<void> _tapType(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('history-type-filter')),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('transaction form', () {
    testWidgets('is simple: note on top, no frequent chips, tags or details', (
      tester,
    ) async {
      await _pumpApp(tester);
      await tester.tap(find.byTooltip('Catat Transaksi'));
      await tester.pumpAndSettle();

      expect(find.text('Sering digunakan'), findsNothing);
      expect(find.text('Detail lainnya'), findsNothing);
      expect(find.text('Tags (opsional)'), findsNothing);
      expect(find.byKey(const Key('transaction-more-details')), findsNothing);

      final note = find.byKey(const Key('transaction-note-input'));
      expect(note, findsOneWidget);
      final noteTop = tester.getTopLeft(note).dy;
      expect(
        noteTop,
        greaterThan(
          tester
              .getTopLeft(find.byKey(const Key('transaction-amount-input')))
              .dy,
        ),
      );
      expect(noteTop, lessThan(tester.getTopLeft(find.text('Kategori')).dy));

      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.text('Pilih tanggal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saves an expense with the optional note', (tester) async {
      final app = await _pumpApp(tester);
      await tester.tap(find.byTooltip('Catat Transaksi'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('transaction-amount-input')),
        '12000',
      );
      await tester.enterText(
        find.byKey(const Key('transaction-note-input')),
        'Kopi pagi',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('transaction-save-button')));
      await _settle(tester);

      final saved = (await app.database.getAllTransactions()).singleWhere(
        (item) => item.note == 'Kopi pagi',
      );
      expect(saved.amount, 12000);
      expect(saved.type, 'expense');
    });

    testWidgets('account picker shows icons, type and balance', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byTooltip('Catat Transaksi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Akun'), findsOneWidget);
      expect(find.text('Bank BCA'), findsWidgets);
      expect(find.text('DANA'), findsWidgets);
      expect(find.text('Bank'), findsWidgets);
      expect(find.text('E-wallet'), findsWidgets);
      expect(find.byIcon(Icons.account_balance_rounded), findsWidgets);
      expect(find.byIcon(Icons.smartphone_rounded), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('history filters', () {
    testWidgets('defaults to this month and filters by type in one tap', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _openHistory(tester);

      final label = find.byKey(const Key('history-period-button'));
      expect(label, findsOneWidget);
      expect(find.text('Gaji bulanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);

      await _tapType(tester, 'Keluar');
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Gaji bulanan'), findsNothing);

      await _tapType(tester, 'Masuk');
      expect(find.text('Gaji bulanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsNothing);

      await _tapType(tester, 'Semua');
      expect(find.text('Gaji bulanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('month navigation and all-time recover from an empty month', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _openHistory(tester);

      // Next month is not reachable from the current one.
      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
      );
      expect(next.onPressed, isNull);

      await tester.tap(find.byTooltip('Bulan sebelumnya'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada transaksi di periode ini'), findsOneWidget);

      await tester.tap(find.text('Semua waktu').last);
      await tester.pumpAndSettle();
      expect(find.text('Gaji bulanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wallet filter uses one-tap chips and shows a removable chip', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      await app.repository.saveTransaction(
        type: 'expense',
        amount: 9000,
        accountId: app.dana,
        categoryId: 'expense-transport',
        note: 'Ojek',
        transactionDate: DateTime.now(),
      );
      await tester.pumpAndSettle();
      await _openHistory(tester);

      await tester.tap(find.byTooltip('Filter dompet dan kategori'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'DANA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Ojek'), findsOneWidget);
      expect(find.text('Makan siang'), findsNothing);
      expect(find.text('Dompet: DANA'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Makan siang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a report drill-down request pre-filters the list', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _openHistory(tester);
      final money = Get.find<MoneyController>();
      final now = DateTime.now();

      money.historyRequest.value = HistoryFilterRequest(
        type: 'expense',
        categoryId: 'expense-food',
        range: FinanceDateRange(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(money.historyRequest.value, isNull);
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Gaji bulanan'), findsNothing);
      expect(find.text('Kategori: Makan'), findsOneWidget);
    });
  });

  group('wallet balance edit', () {
    testWidgets('changing the balance records an adjustment in history', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      final account = (await app.database.getAllAccounts()).singleWhere(
        (item) => item.id == app.bca,
      );
      final context = tester.element(find.byType(MainShell));
      unawaited(showAccountForm(context, account: account));
      await tester.pumpAndSettle();

      // Shows the current balance (1.000.000 + 500.000 - 25.000), not the opening one.
      final field = tester.widget<TextField>(
        find.byKey(const Key('account-balance-input')),
      );
      expect(field.controller!.text.replaceAll(RegExp(r'\D'), ''), '1475000');
      expect(find.text('Saldo saat ini'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('account-balance-input')),
        '1000000',
      );
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await _settle(tester);

      expect(await app.database.accountBalance(app.bca), 1000000);
      final adjustment = (await app.database.getAllTransactions()).singleWhere(
        (item) => isAdjustmentCategory(item.categoryId),
      );
      expect(adjustment.type, 'expense');
      expect(adjustment.amount, 475000);
      // The opening balance itself is untouched.
      final updated = (await app.database.getAllAccounts()).singleWhere(
        (item) => item.id == app.bca,
      );
      expect(updated.initialBalance, 1000000);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renaming without touching the balance adds no adjustment', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      final account = (await app.database.getAllAccounts()).singleWhere(
        (item) => item.id == app.bca,
      );
      final context = tester.element(find.byType(MainShell));
      unawaited(showAccountForm(context, account: account));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'BCA Utama');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await _settle(tester);

      expect(
        (await app.database.getAllAccounts()).any(
          (item) => item.name == 'BCA Utama',
        ),
        isTrue,
      );
      expect(
        (await app.database.getAllTransactions()).where(
          (item) => isAdjustmentCategory(item.categoryId),
        ),
        isEmpty,
      );
    });
  });
}
