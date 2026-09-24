import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../services/privacy_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_donut_chart.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
import '../main/money_controller.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final money = Get.find<MoneyController>();
    final privacy = Get.find<PrivacyService>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final visible = privacy.showMoney.value;
        final summary = money.summaryFor(_month);
        final categories = money.categoryTotalsFor(_month);
        final chartColors = context.ferikColors.chartColors;
        final slices = [
          for (var index = 0; index < categories.length; index++)
            ExpenseChartSlice(
              value: categories[index].amount,
              color: chartColors[index % chartColors.length],
            ),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            100,
          ),
          children: [
            Text(
              'Statistik',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MonthSelector(
              month: _month,
              onPrevious: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryCard(
              income: summary.income,
              expense: summary.expense,
              net: summary.net,
              visible: visible,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Pengeluaran per Kategori'),
            const SizedBox(height: AppSpacing.sm),
            if (categories.isEmpty)
              const FerikCard(
                child: EmptyState(
                  compact: true,
                  icon: Icons.donut_large_outlined,
                  title: 'Belum ada pengeluaran bulan ini',
                  message:
                      'Distribusi kategori akan muncul setelah kamu mencatat pengeluaran.',
                ),
              )
            else ...[
              FerikCard(
                child: Center(
                  child: ExpenseDonutChart(
                    total: summary.expense,
                    slices: slices,
                    visible: visible,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FerikCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < categories.length; index++)
                      _CategoryRow(
                        item: categories[index],
                        total: summary.expense,
                        color: chartColors[index % chartColors.length],
                        visible: visible,
                        showDivider: index < categories.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: 'Bulan sebelumnya',
          onPressed: onPrevious,
          style: context.isFerikDark
              ? null
              : IconButton.styleFrom(
                  backgroundColor: context.ferikColors.primarySoft,
                  foregroundColor: context.ferikColors.primary,
                ),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        SizedBox(
          width: 176,
          child: Text(
            monthLabel(month),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Bulan berikutnya',
          onPressed: onNext,
          style: context.isFerikDark
              ? null
              : IconButton.styleFrom(
                  backgroundColor: context.ferikColors.primarySoft,
                  foregroundColor: context.ferikColors.primary,
                ),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.net,
    required this.visible,
  });

  final int income;
  final int expense;
  final int net;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return FerikCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Pemasukan',
                amount: income,
                icon: Icons.arrow_upward_rounded,
                tone: MoneyTone.income,
                visible: visible,
              ),
            ),
            const VerticalDivider(width: AppSpacing.md),
            Expanded(
              child: _SummaryMetric(
                label: 'Pengeluaran',
                amount: expense,
                icon: Icons.arrow_downward_rounded,
                tone: MoneyTone.expense,
                visible: visible,
              ),
            ),
            const VerticalDivider(width: AppSpacing.md),
            Expanded(
              child: _SummaryMetric(
                label: 'Arus Bersih',
                amount: net,
                icon: Icons.swap_vert_rounded,
                tone: net > 0
                    ? MoneyTone.income
                    : net < 0
                    ? MoneyTone.expense
                    : MoneyTone.neutral,
                visible: visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.tone,
    required this.visible,
  });

  final String label;
  final int amount;
  final IconData icon;
  final MoneyTone tone;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final semanticColor = switch (tone) {
      MoneyTone.income => context.ferikColors.income,
      MoneyTone.expense => context.ferikColors.expense,
      MoneyTone.transfer => context.ferikColors.transfer,
      MoneyTone.neutral => context.ferikColors.primary,
    };
    final semanticBackground = switch (tone) {
      MoneyTone.income => context.ferikColors.incomeSoft,
      MoneyTone.expense => context.ferikColors.expenseSoft,
      MoneyTone.transfer => context.ferikColors.transferSoft,
      MoneyTone.neutral => context.ferikColors.primarySoft,
    };
    return Column(
      children: [
        if (context.isFerikDark)
          Icon(icon, size: 19, color: semanticColor)
        else
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: semanticBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 17, color: semanticColor),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        SizedBox(
          width: double.infinity,
          height: 20,
          child: MoneyText(
            amount: amount,
            visible: visible,
            tone: tone,
            showSign: tone == MoneyTone.income || tone == MoneyTone.expense,
            scaleDown: true,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.total,
    required this.color,
    required this.visible,
    required this.showDivider,
  });

  final CategoryTotal item;
  final int total;
  final Color color;
  final bool visible;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (item.amount / total * 100).round();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 112,
                child: MoneyText(
                  amount: item.amount,
                  visible: visible,
                  scaleDown: true,
                  textAlign: TextAlign.end,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 38,
                child: Text(
                  '$percentage%',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}
