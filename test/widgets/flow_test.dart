import 'dart:async';

import 'package:ferikmoney/features/accounts/account_detail_view.dart';
import 'package:ferikmoney/features/main/money_controller.dart';
import 'package:ferikmoney/features/reports/reports_view.dart';
import 'package:ferikmoney/models/finance_models.dart';
import 'package:ferikmoney/repositories/savings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('home', () {
    testWidgets('is calm: no settings shortcut, period picker or full form', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byTooltip('Pengaturan'), findsNothing);
      expect(find.text('Form lengkap'), findsNothing);
      expect(find.text('Minggu Ini'), findsNothing);
      expect(find.text('Pengeluaran terbesar'), findsNothing);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Total Uang'), findsOneWidget);
      expect(find.text('Masuk bulan ini'), findsOneWidget);
      expect(find.text('Keluar bulan ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("shows today's spending", (tester) async {
      await pumpApp(tester);

      expect(find.textContaining('Hari ini'), findsWidgets);
      expect(find.text('Belum ada pengeluaran hari ini'), findsNothing);
    });

    testWidgets('first run offers only adding a wallet, prefilled', (
      tester,
    ) async {
      await pumpApp(tester, seed: false);

      expect(find.byTooltip('Catat Transaksi'), findsNothing);
      expect(find.text('Selamat datang di FerikMoney'), findsOneWidget);

      await tester.tap(find.text('Tambah Akun'));
      await tester.pumpAndSettle();
      final name = tester.widget<TextField>(find.byType(TextField).first);
      expect(name.controller!.text, 'Tunai');
      expect(tester.takeException(), isNull);
    });
  });

  group('transactions', () {
    testWidgets('deleting needs no confirmation and can be undone', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Makan siang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Transaksi'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hapus transaksi?'), findsNothing);
      expect(
        (await app.database.getAllTransactions()).any(
          (item) => item.note == 'Makan siang',
        ),
        isFalse,
      );
      expect(find.text('UNDO'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await settle(tester);
      expect(
        (await app.database.getAllTransactions()).any(
          (item) => item.note == 'Makan siang',
        ),
        isTrue,
      );
    });

    testWidgets('savings transfers can be opened and deleted from history', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final savings = Get.find<SavingsRepository>();
      final goalId = await savings.saveGoal(
        name: 'Liburan',
        targetAmount: 5000000,
      );
      await savings.transfer(
        goalId: goalId,
        accountId: app.bca,
        type: GoalTransferType.deposit,
        amount: 100000,
        date: DateTime.now(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transfer ke Liburan'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Tabungan'), findsOneWidget);
      await tester.tap(find.text('Hapus Transfer'));
      await settle(tester);

      expect(await app.database.getAllSavingsGoalTransfers(), isEmpty);
    });
  });

  group('reports', () {
    testWidgets('a category opens history filtered to it', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();

      final line = find.text('Makan · 100%');
      await tester.scrollUntilVisible(
        line,
        120,
        scrollable: find
            .descendant(
              of: find.byType(ReportsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      // Keep the row clear of the floating action button.
      await tester.drag(find.byType(ReportsView), const Offset(0, -140));
      await tester.pumpAndSettle();
      await tester.tap(line);
      await tester.pumpAndSettle();

      expect(Get.find<MoneyController>().historyRequest.value, isNull);
      expect(find.text('Cari transaksi'), findsOneWidget);
      expect(find.text('Kategori: Makan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Gaji bulanan'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cannot page past the current period', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
      );
      expect(next.onPressed, isNull);
    });
  });

  group('wallets', () {
    testWidgets('only an empty wallet can be deleted', (tester) async {
      final app = await pumpApp(tester);

      unawaited(Get.to<void>(() => AccountDetailView(accountId: app.bca)));
      await tester.pumpAndSettle();
      expect(find.text('Hapus akun'), findsNothing);
      Get.back<void>();
      await tester.pumpAndSettle();

      unawaited(Get.to<void>(() => AccountDetailView(accountId: app.dana)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Hapus akun'));
      await tester.tap(find.text('Hapus akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus').last);
      await settle(tester);

      expect(
        (await app.database.getAllAccounts()).any(
          (item) => item.id == app.dana,
        ),
        isFalse,
      );
    });
  });
}
