import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../home/home_view.dart';
import '../more/more_view.dart';
import '../reports/reports_view.dart';
import '../transactions/history_view.dart';
import '../transactions/transaction_form_sheet.dart';
import 'money_controller.dart';

class MainShell extends GetView<MoneyController> {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.navigationIndex.value,
          children: const [
            HomeView(),
            HistoryView(),
            ReportsView(),
            MoreView(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.isFerikDark
                    ? context.ferikColors.divider
                    : context.ferikColors.borderSubtle,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: controller.navigationIndex.value,
            onDestinationSelected: (value) =>
                controller.navigationIndex.value = value,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Transaksi',
              ),
              NavigationDestination(
                icon: Icon(Icons.donut_large_outlined),
                selectedIcon: Icon(Icons.donut_large_rounded),
                label: 'Laporan',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Lainnya',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Catat Transaksi',
          onPressed: () {
            if (controller.accounts.isEmpty) {
              Get.snackbar(
                'Belum ada akun',
                'Tambahkan akun sebelum mencatat transaksi.',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            showTransactionForm(context);
          },
          child: const Icon(Icons.add_rounded, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
