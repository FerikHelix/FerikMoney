import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../services/privacy_service.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/account_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/finance_activity_tile.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
import '../accounts/account_detail_view.dart';
import '../accounts/account_form_sheet.dart';
import '../accounts/accounts_view.dart';
import '../budgets/budget_controller.dart';
import '../budgets/budgets_view.dart';
import '../main/main_tab.dart';
import '../main/money_controller.dart';
import '../savings/goal_transfer_sheet.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_form_sheet.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MoneyController>();
    final privacy = Get.find<PrivacyService>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.databaseError.value != null) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Data tidak dapat dibuka',
            message: controller.databaseError.value,
          );
        }
        if (controller.accounts.isEmpty) return const _WelcomeState();

        final now = DateTime.now();
        final month = controller.summaryFor(now);
        final budget = Get.find<BudgetController>().overallFor(now);
        final latest = controller.activities.take(5).toList();
        final availableWidth = MediaQuery.sizeOf(context).width - 32;
        final accountWidth = math.min(
          196.0,
          math.max(156.0, (availableWidth - AppSpacing.sm) / 2),
        );
        final valuesVisible = privacy.showMoney.value;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              toolbarHeight: 64,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.asset(
                      'assets/branding/ferikmoney_icon.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Text(
                    'FerikMoney',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xxs,
                AppSpacing.md,
                100,
              ),
              sliver: SliverList.list(
                children: [
                  _TotalMoneyHero(
                    total: controller.totalBalance,
                    savings: controller.savingsTotal,
                    todayExpense: controller.expenseOn(now),
                    income: month.income,
                    expense: month.expense,
                    visible: valuesVisible,
                    onToggleVisibility: privacy.toggleMoneyVisibility,
                  ),
                  if (budget != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _BudgetSummary(
                      progress: budget,
                      visible: valuesVisible,
                      onTap: () => Get.to(() => const BudgetsView()),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Akun Saya',
                    actionLabel: 'Lihat semua',
                    onAction: () => Get.to(() => const AccountsView()),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.activeAccounts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = controller.activeAccounts[index];
                        return AccountCard(
                          width: accountWidth,
                          name: item.account.name,
                          type: item.account.type,
                          balance: item.balance,
                          visible: valuesVisible,
                          onTap: () => Get.to(
                            () => AccountDetailView(accountId: item.account.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Tambah Cepat'),
                  const SizedBox(height: AppSpacing.xs),
                  _QuickAdd(
                    categories: controller.frequentCategories('expense'),
                    onSelected: (categoryId) => showTransactionForm(
                      context,
                      initialCategoryId: categoryId,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Aktivitas Terbaru',
                    actionLabel: 'Semua',
                    onAction: () => controller.goTo(MainTab.history),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (latest.isEmpty)
                    FerikCard(
                      child: EmptyState(
                        compact: true,
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada transaksi',
                        message: 'Catat pemasukan atau pengeluaran pertamamu.',
                        action: FilledButton.icon(
                          onPressed: () => showTransactionForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Catat Transaksi'),
                        ),
                      ),
                    )
                  else
                    FerikCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var index = 0; index < latest.length; index++)
                            FinanceActivityTile(
                              activity: latest[index],
                              visible: valuesVisible,
                              showDivider: index < latest.length - 1,
                              onTransactionTap:
                                  latest[index].transaction == null
                                  ? null
                                  : () => showTransactionDetail(
                                      context,
                                      latest[index].transaction!.transaction,
                                    ),
                              onGoalTransferTap:
                                  latest[index].goalTransfer == null
                                  ? null
                                  : () => showGoalTransferDetail(
                                      context,
                                      latest[index].goalTransfer!,
                                    ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({
    required this.progress,
    required this.visible,
    required this.onTap,
  });

  final BudgetProgress progress;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (progress.status) {
      BudgetStatus.safe => context.ferikColors.income,
      BudgetStatus.approaching => context.ferikColors.warning,
      BudgetStatus.over => context.ferikColors.expense,
    };
    return FerikCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.pie_chart_outline_rounded, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.remaining >= 0
                      ? 'Sisa budget bulan ini'
                      : 'Budget terlampaui',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                MoneyText(
                  amount: progress.remaining.abs(),
                  visible: visible,
                  tone: progress.remaining >= 0
                      ? MoneyTone.neutral
                      : MoneyTone.expense,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: LinearProgressIndicator(
              value: progress.ratio.clamp(0.0, 1.0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.categories, required this.onSelected});

  final List<Category> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return OutlinedButton.icon(
        onPressed: () => showTransactionForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Pengeluaran'),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final category in categories)
          ActionChip(
            avatar: Icon(iconForName(category.icon), size: 18),
            label: Text(category.name),
            onPressed: () => onSelected(category.id),
          ),
      ],
    );
  }
}

class _WelcomeState extends StatelessWidget {
  const _WelcomeState();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Selamat datang di FerikMoney',
      message:
          'Mulai dengan menambahkan tempat kamu menyimpan uang, misalnya '
          'akun tunai atau rekening bank.',
      action: FilledButton.icon(
        onPressed: () => showAccountForm(context, suggestedName: 'Tunai'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Akun'),
      ),
    );
  }
}

class _TotalMoneyHero extends StatelessWidget {
  const _TotalMoneyHero({
    required this.total,
    required this.savings,
    required this.todayExpense,
    required this.income,
    required this.expense,
    required this.visible,
    required this.onToggleVisibility,
  });

  final int total;
  final int savings;
  final int todayExpense;
  final int income;
  final int expense;
  final bool visible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return FerikCard(
      color: colors.primaryContainer,
      borderRadius: AppRadius.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Uang',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ),
              IconButton(
                tooltip: visible ? 'Sembunyikan nominal' : 'Tampilkan nominal',
                onPressed: onToggleVisibility,
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface.withValues(alpha: 0.46),
                  foregroundColor: colors.mainText,
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(visible),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: SizedBox(
              key: ValueKey(visible),
              width: double.infinity,
              height: 46,
              child: MoneyText(
                amount: total,
                visible: visible,
                scaleDown: true,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          ),
          if (savings > 0) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Text(
                  'Termasuk tabungan ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Flexible(
                  child: MoneyText(
                    amount: savings,
                    visible: visible,
                    scaleDown: true,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.today_outlined, size: 17, color: colors.secondaryText),
              const SizedBox(width: AppSpacing.xs),
              if (todayExpense == 0)
                Text(
                  'Belum ada pengeluaran hari ini',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...[
                Text(
                  'Hari ini ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Flexible(
                  child: MoneyText(
                    amount: todayExpense,
                    visible: visible,
                    tone: MoneyTone.expense,
                    showSign: true,
                    scaleDown: true,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Masuk bulan ini',
                  amount: income,
                  tone: MoneyTone.income,
                  visible: visible,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: context.ferikContainerDivider,
              ),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Keluar bulan ini',
                  amount: expense,
                  tone: MoneyTone.expense,
                  visible: visible,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.amount,
    required this.tone,
    required this.visible,
  });

  final IconData icon;
  final String label;
  final int amount;
  final MoneyTone tone;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      MoneyTone.income => context.ferikColors.income,
      MoneyTone.expense => context.ferikColors.expense,
      _ => context.ferikColors.mainText,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: MoneyText(
                amount: amount,
                visible: visible,
                tone: tone,
                showSign: true,
                scaleDown: true,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
