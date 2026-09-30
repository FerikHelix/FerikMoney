import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../models/finance_models.dart';
import '../../services/app_preferences_service.dart';
import '../../services/privacy_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_donut_chart.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../main/money_controller.dart';
import 'reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final money = Get.find<MoneyController>();
    final privacy = Get.find<PrivacyService>();
    final preferences = Get.find<AppPreferencesService>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        money.transactions.length;
        preferences.firstWeekday.value;
        final snapshot = controller.snapshot;
        final visible = privacy.showMoney.value;
        final expenseEntries = snapshot.expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final incomeEntries = snapshot.incomeByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final chartColors = context.ferikColors.chartColors;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            100,
          ),
          children: [
            Text('Laporan', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<FinancePeriod>(
              showSelectedIcon: false,
              segments: [
                for (final value in FinancePeriod.values)
                  ButtonSegment(value: value, label: Text(value.label)),
              ],
              selected: {controller.period.value},
              onSelectionChanged: (value) {
                controller.period.value = value.first;
                controller.anchor.value = DateTime.now();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: controller.previous,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    _rangeLabel(
                      controller.period.value,
                      controller.anchor.value,
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.next,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Summary(snapshot: snapshot, visible: visible),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tren Arus Kas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            FerikCard(
              child: snapshot.trend.isEmpty
                  ? const EmptyState(
                      compact: true,
                      icon: Icons.show_chart_rounded,
                      title: 'Belum cukup data',
                      message:
                          'Tren muncul setelah ada transaksi pada periode ini.',
                    )
                  : SizedBox(
                      height: 180,
                      child: CustomPaint(
                        key: const Key('cash-flow-trend-chart'),
                        painter: _TrendPainter(
                          points: snapshot.trend,
                          incomeColor: context.ferikColors.income,
                          expenseColor: context.ferikColors.expense,
                          gridColor: context.ferikColors.borderSubtle,
                        ),
                      ),
                    ),
            ),
            if (expenseEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pengeluaran per Kategori',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              FerikCard(
                child: Column(
                  children: [
                    ExpenseDonutChart(
                      total: snapshot.expense,
                      visible: visible,
                      slices: [
                        for (var i = 0; i < expenseEntries.length; i++)
                          ExpenseChartSlice(
                            value: expenseEntries[i].value,
                            color: chartColors[i % chartColors.length],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < expenseEntries.length; i++)
                      _CategoryLine(
                        name:
                            money.categoryById(expenseEntries[i].key)?.name ??
                            'Kategori',
                        amount: expenseEntries[i].value,
                        color: chartColors[i % chartColors.length],
                        visible: visible,
                      ),
                  ],
                ),
              ),
            ],
            if (incomeEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pemasukan per Kategori',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              FerikCard(
                child: Column(
                  children: [
                    for (var i = 0; i < incomeEntries.length; i++)
                      _CategoryLine(
                        name:
                            money.categoryById(incomeEntries[i].key)?.name ??
                            'Kategori',
                        amount: incomeEntries[i].value,
                        color: context.ferikColors.income,
                        visible: visible,
                      ),
                  ],
                ),
              ),
            ],
            if (snapshot.expense > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              _InsightCard(snapshot: snapshot, money: money),
            ],
          ],
        );
      }),
    );
  }

  String _rangeLabel(FinancePeriod period, DateTime anchor) => switch (period) {
    FinancePeriod.week =>
      'Minggu ${DateFormat('d MMM', 'id_ID').format(anchor)}',
    FinancePeriod.month => DateFormat('MMMM yyyy', 'id_ID').format(anchor),
    FinancePeriod.year => '${anchor.year}',
  };
}

class _Summary extends StatelessWidget {
  const _Summary({required this.snapshot, required this.visible});

  final ReportSnapshot snapshot;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return FerikCard(
      child: Row(
        children: [
          _Metric(
            label: 'Masuk',
            amount: snapshot.income,
            tone: MoneyTone.income,
            visible: visible,
          ),
          const SizedBox(height: 52, child: VerticalDivider()),
          _Metric(
            label: 'Keluar',
            amount: snapshot.expense,
            tone: MoneyTone.expense,
            visible: visible,
          ),
          const SizedBox(height: 52, child: VerticalDivider()),
          _Metric(
            label: 'Bersih',
            amount: snapshot.net,
            tone: snapshot.net >= 0 ? MoneyTone.income : MoneyTone.expense,
            visible: visible,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.amount,
    required this.tone,
    required this.visible,
  });

  final String label;
  final int amount;
  final MoneyTone tone;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: MoneyText(
              amount: amount,
              visible: visible,
              tone: tone,
              scaleDown: true,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.name,
    required this.amount,
    required this.color,
    required this.visible,
  });

  final String name;
  final int amount;
  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(name)),
          SizedBox(
            width: 130,
            child: MoneyText(
              amount: amount,
              visible: visible,
              scaleDown: true,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.snapshot, required this.money});

  final ReportSnapshot snapshot;
  final MoneyController money;

  @override
  Widget build(BuildContext context) {
    final top = snapshot.expenseByCategory.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final category = money.categoryById(top.key)?.name ?? 'Kategori terbesar';
    final comparison = snapshot.previousExpense == 0
        ? null
        : ((snapshot.expense - snapshot.previousExpense) /
                  snapshot.previousExpense *
                  100)
              .round();
    return FerikCard(
      color: context.ferikColors.primarySoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: context.ferikColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              comparison == null
                  ? '$category adalah pengeluaran terbesar pada periode ini.'
                  : '$category adalah pengeluaran terbesar. Pengeluaran ${comparison.abs()}% ${comparison >= 0 ? 'lebih tinggi' : 'lebih rendah'} dari periode pembanding.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
  });

  final List<TrendPoint> points;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = points.fold<int>(
      1,
      (value, point) => math.max(value, math.max(point.income, point.expense)),
    );
    final grid = Paint()..color = gridColor;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), grid);
    }
    final groupWidth = size.width / points.length;
    final barWidth = math.min(12.0, groupWidth * 0.28);
    for (var i = 0; i < points.length; i++) {
      final center = groupWidth * (i + 0.5);
      final incomeHeight = size.height * points[i].income / maxValue;
      final expenseHeight = size.height * points[i].expense / maxValue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center - barWidth - 1,
            size.height - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = incomeColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center + 1,
            size.height - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = expenseColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor;
}
