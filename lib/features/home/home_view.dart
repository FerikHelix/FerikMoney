import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../services/privacy_service.dart';
import '../../widgets/account_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_tile.dart';
import '../accounts/account_detail_view.dart';
import '../accounts/account_form_sheet.dart';
import '../accounts/accounts_view.dart';
import '../main/money_controller.dart';
import '../settings/settings_view.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transaction_form_sheet.dart';

class HomeView extends GetView<MoneyController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
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

        final summary = controller.summaryFor(DateTime.now());
        final latest = controller.transactions.take(5).toList();
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
                    borderRadius: BorderRadius.circular(7),
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: IconButton.filledTonal(
                    tooltip: 'Pengaturan',
                    onPressed: () => Get.to(() => const SettingsView()),
                    icon: const Icon(Icons.settings_outlined, size: 21),
                  ),
                ),
              ],
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
                    income: summary.income,
                    expense: summary.expense,
                    visible: valuesVisible,
                    onToggleVisibility: privacy.toggleMoneyVisibility,
                  ),
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
                      itemCount: controller.accounts.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = controller.accounts[index];
                        return AccountCard(
                          width: accountWidth,
                          name: item.account.name,
                          type: _accountTypeLabel(item.account.type),
                          iconName: item.account.icon,
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
                  SectionHeader(
                    title: 'Aktivitas Terbaru',
                    actionLabel: 'Semua',
                    onAction: () => controller.navigationIndex.value = 1,
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
                            TransactionTile(
                              transaction: latest[index],
                              accountName:
                                  controller
                                      .accountById(latest[index].accountId)
                                      ?.account
                                      .name ??
                                  '-',
                              destinationName: controller
                                  .accountById(
                                    latest[index].destinationAccountId,
                                  )
                                  ?.account
                                  .name,
                              category: controller.categoryById(
                                latest[index].categoryId,
                              ),
                              visible: valuesVisible,
                              showDivider: index < latest.length - 1,
                              onTap: () =>
                                  showTransactionDetail(context, latest[index]),
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

class _WelcomeState extends StatelessWidget {
  const _WelcomeState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FerikMoney',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: IconButton.filledTonal(
              tooltip: 'Pengaturan',
              onPressed: () => Get.to(() => const SettingsView()),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Belum ada akun',
        message:
            'Tambahkan tempat kamu menyimpan uang untuk mulai mencatat dengan simpel.',
        action: FilledButton.icon(
          onPressed: () => showAccountForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah Akun'),
        ),
      ),
    );
  }
}

class _TotalMoneyHero extends StatelessWidget {
  const _TotalMoneyHero({
    required this.total,
    required this.income,
    required this.expense,
    required this.visible,
    required this.onToggleVisibility,
  });

  final int total;
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
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Pemasukan',
                  amount: income,
                  tone: MoneyTone.income,
                  visible: visible,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: context.isFerikDark
                    ? colors.divider
                    : colors.primaryContainerStrong,
              ),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Pengeluaran',
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

String _accountTypeLabel(String type) => switch (type) {
  'bank' => 'Bank',
  'ewallet' => 'E-wallet',
  'other' => 'Lainnya',
  _ => 'Tunai',
};
