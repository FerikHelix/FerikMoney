import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../widgets/ferik_card.dart';
import '../accounts/accounts_view.dart';
import '../budgets/budgets_view.dart';
import '../recurring/recurring_controller.dart';
import '../recurring/recurring_view.dart';
import '../savings/savings_goals_view.dart';
import '../settings/categories_view.dart';
import '../settings/settings_view.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final recurring = Get.find<RecurringController>();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
        children: [
          Text('Lainnya', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          FerikCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Wallet',
                  subtitle: 'Kelola akun dan saldo',
                  onTap: () => Get.to(() => const AccountsView()),
                ),
                const Divider(height: 1),
                _MoreTile(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Budget',
                  subtitle: 'Batas pengeluaran bulanan',
                  onTap: () => Get.to(() => const BudgetsView()),
                ),
                const Divider(height: 1),
                _MoreTile(
                  icon: Icons.flag_outlined,
                  title: 'Target Tabungan',
                  subtitle: 'Sisihkan uang untuk tujuanmu',
                  onTap: () => Get.to(() => const SavingsGoalsView()),
                ),
                const Divider(height: 1),
                Obx(
                  () => _MoreTile(
                    icon: Icons.event_repeat_outlined,
                    title: 'Transaksi Berulang',
                    subtitle: 'Jadwal pemasukan dan pengeluaran',
                    badge: recurring.pending.length,
                    onTap: () => Get.to(() => const RecurringView()),
                  ),
                ),
                const Divider(height: 1),
                _MoreTile(
                  icon: Icons.category_outlined,
                  title: 'Kategori',
                  subtitle: 'Atur kategori pemasukan dan pengeluaran',
                  onTap: () => Get.to(() => const CategoriesView()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FerikCard(
            padding: EdgeInsets.zero,
            child: _MoreTile(
              icon: Icons.settings_outlined,
              title: 'Pengaturan',
              subtitle: 'Tampilan, preferensi, dan data',
              onTap: () => Get.to(() => const SettingsView()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.ferikColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: context.ferikColors.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0)
            Badge(
              label: Text('$badge'),
              backgroundColor: context.ferikColors.expense,
            ),
          const SizedBox(width: AppSpacing.xxs),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}
