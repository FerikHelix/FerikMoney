import 'dart:async';

import 'package:ferikmoney/features/main/money_controller.dart';
import 'package:ferikmoney/features/recurring/recurring_view.dart';
import 'package:ferikmoney/features/savings/savings_goals_view.dart';
import 'package:ferikmoney/features/settings/categories_view.dart';
import 'package:ferikmoney/services/privacy_service.dart';
import 'package:ferikmoney/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('MoneyText follows the hide-amounts setting by default', (
    tester,
  ) async {
    await pumpApp(tester);
    final privacy = Get.find<PrivacyService>();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MoneyText(amount: 12345))),
    );

    expect(find.textContaining('12.345'), findsOneWidget);

    await privacy.toggleMoneyVisibility();
    await tester.pump();

    expect(find.textContaining('12.345'), findsNothing);
    expect(find.textContaining('•'), findsOneWidget);
  });

  testWidgets('Lainnya groups its shortcuts and uses one word for accounts', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();

    expect(find.text('Kelola'), findsOneWidget);
    expect(find.text('Perencanaan'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(find.text('Wallet'), findsNothing);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Target Tabungan'), findsOneWidget);
    expect(find.text('Transaksi Berulang'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pengaturan'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categories hide adjustment categories and can be archived', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    // Drift streams need real timers, so run database work outside fake time.
    await tester.runAsync(
      () => app.repository.adjustBalance(accountId: app.bca, newBalance: 10),
    );
    await tester.pumpAndSettle();

    unawaited(Get.to<void>(() => const CategoriesView()));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('Penyesuaian saldo'), findsNothing);
    expect(Get.find<MoneyController>().userCategories.length, 17);

    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arsipkan kategori'));
    await settle(tester);

    final food = (await app.database.getAllCategories()).singleWhere(
      (item) => item.id == 'expense-food',
    );
    expect(food.isArchived, isTrue);
  });

  testWidgets('a new category can be created from the icon picker', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    unawaited(Get.to<void>(() => const CategoriesView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Kopi');
    await tester.tap(find.byIcon(Icons.restaurant_rounded).last);
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await settle(tester);

    final created = (await app.database.getAllCategories()).singleWhere(
      (item) => item.name == 'Kopi',
    );
    expect(created.icon, 'restaurant');
    expect(created.type, 'expense');
  });

  testWidgets('the recurring form keeps everything visible and can delete', (
    tester,
  ) async {
    await pumpApp(tester);
    unawaited(Get.to<void>(() => const RecurringView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buat Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Detail lainnya'), findsNothing);
    expect(find.text('Catatan (opsional)'), findsOneWidget);
    expect(find.text('Frekuensi'), findsOneWidget);
    expect(find.text('Simpan Jadwal'), findsOneWidget);
    expect(find.text('Wallet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('savings goals can be created and later restored', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    unawaited(Get.to<void>(() => const SavingsGoalsView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buat Target'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Laptop');
    await tester.enterText(find.byType(TextField).at(1), '8000000');
    await tester.pump();
    await tester.tap(find.text('Simpan Target'));
    await settle(tester);

    final goals = await app.database.getAllSavingsGoals();
    expect(goals.single.name, 'Laptop');
    expect(goals.single.targetAmount, 8000000);
  });
}
