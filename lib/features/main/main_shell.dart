import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../home/home_view.dart';
import '../more/more_view.dart';
import '../reports/reports_view.dart';
import '../transactions/history_view.dart';
import '../transactions/transaction_form_sheet.dart';
import 'main_tab.dart';
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
                controller.goTo(MainTab.values[value]),
            destinations: [
              for (final tab in MainTab.values)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
        // Recording needs a wallet, so the first-run screen offers only
        // "Tambah dompet" instead of a button that cannot work yet.
        floatingActionButton: controller.accounts.isEmpty
            ? null
            : FloatingActionButton(
                tooltip: 'Catat Transaksi',
                onPressed: () => showTransactionForm(context),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
