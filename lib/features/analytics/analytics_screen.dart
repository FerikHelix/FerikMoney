import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/dates/date_keys.dart';
import '../../core/models/models.dart';
import '../../core/money/rupiah.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/display.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/l10n.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime _month = monthStart(DateTime.now());
  int? _walletId;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(
      monthSnapshotProvider((month: _month, walletId: _walletId)),
    );
    final wallets = ref.watch(allWalletBalancesProvider).value ?? const [];
    final data = snapshot.value ?? AnalyticsSnapshot.empty;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.analyticsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    }),
                    icon: const Icon(Symbols.chevron_left_rounded),
                    tooltip: context.l10n.selectMonth,
                  ),
                  Expanded(
                    child: Text(
                      formatMonthLabel(_month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    }),
                    icon: const Icon(Symbols.chevron_right_rounded),
                    tooltip: context.l10n.selectMonth,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: ValueKey('wallet-filter-${wallets.length}-$_walletId'),
            initialValue: _walletId ?? 0,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.l10n.wallet),
            items: [
              DropdownMenuItem(value: 0, child: Text(context.l10n.allWallets)),
              for (final item in wallets)
                DropdownMenuItem(
                  value: item.wallet.id,
                  child: Text(item.wallet.name),
                ),
            ],
            onChanged: (value) => setState(() {
              _walletId = value == 0 ? null : value;
            }),
          ),
          const SizedBox(height: 12),
          _SummaryRow(summary: data.summary),
          if (!data.hasData) ...[
            const SizedBox(height: 24),
            EmptyState(
              icon: Symbols.bar_chart_rounded,
              title: context.l10n.noDataMonth,
              body: context.l10n.noDataMonthBody,
              actionLabel: context.l10n.addTransaction,
              onAction: () => context.push('/transactions/new?type=expense'),
            ),
          ] else ...[
            const SizedBox(height: 20),
            _BreakdownSection(
              title: context.l10n.expenseBreakdown,
              items: data.expenseBreakdown,
            ),
            const SizedBox(height: 20),
            _BreakdownSection(
              title: context.l10n.incomeBreakdown,
              items: data.incomeBreakdown,
            ),
            const SizedBox(height: 20),
            _TrendSection(points: data.trend),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: context.l10n.income,
                amount: summary.income,
                color: theme.colorScheme.primary,
              ),
            ),
            Expanded(
              child: _SummaryItem(
                label: context.l10n.expense,
                amount: summary.expense,
                color: theme.colorScheme.error,
              ),
            ),
            Expanded(
              child: _SummaryItem(
                label: context.l10n.net,
                amount: summary.net,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          formatRupiah(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.title, required this.items});

  final String title;
  final List<CategoryTotal> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(context.l10n.noDataMonth, style: theme.textTheme.bodyMedium)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          WalletAvatar(
                            iconCodePoint: item.iconCodePoint,
                            colorValue: item.colorValue == 0
                                ? theme.colorScheme.secondary.toARGB32()
                                : item.colorValue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name.isEmpty
                                      ? context.l10n.transferCategory
                                      : item.name,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: item.percentage / 100,
                                  minHeight: 4,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatRupiah(item.amount),
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                formatPercentage(item.percentage),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = points.fold<int>(1, (max, point) {
      final local = point.income > point.expense ? point.income : point.expense;
      return local > max ? local : max;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.trendTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final point in points)
                        Expanded(
                          child: Semantics(
                            label:
                                '${formatMonthLabel(point.month)}: ${formatRupiah(point.income)} masuk, ${formatRupiah(point.expense)} keluar',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _Bar(
                                        value: point.income / maxValue,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 2),
                                      _Bar(
                                        value: point.expense / maxValue,
                                        color: theme.colorScheme.error,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatMonthShort(point.month),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(
                      color: theme.colorScheme.primary,
                      label: context.l10n.incomeShort,
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: theme.colorScheme.error,
                      label: context.l10n.expenseShort,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 2 + (value.clamp(0, 1) * 90),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
