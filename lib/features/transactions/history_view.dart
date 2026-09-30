import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../models/finance_models.dart';
import '../../services/app_preferences_service.dart';
import '../../services/privacy_service.dart';
import '../../utils/balance_adjustment.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/account_icon_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/finance_activity_tile.dart';
import '../../widgets/money_text.dart';
import '../main/money_controller.dart';
import '../savings/savings_controller.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_form_sheet.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  static const _typeOptions = <(String?, String)>[
    (null, 'Semua'),
    ('expense', 'Keluar'),
    ('income', 'Masuk'),
    ('transfer', 'Transfer'),
  ];

  final _money = Get.find<MoneyController>();
  final _searchController = TextEditingController();
  late final Worker _requestWorker;
  String _query = '';
  String? _type;
  String? _accountId;
  String? _categoryId;
  // At most one of these describes the period; both null means all time.
  DateTime? _month = _currentMonth();
  DateTimeRange? _range;

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    _requestWorker = ever(_money.historyRequest, _applyRequest);
    if (_money.historyRequest.value != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyRequest(_money.historyRequest.value),
      );
    }
  }

  @override
  void dispose() {
    _requestWorker.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyRequest(HistoryFilterRequest? request) {
    if (request == null || !mounted) return;
    final start = request.range.start;
    final end = request.range.endExclusive;
    final isWholeMonth =
        start.day == 1 && end == DateTime(start.year, start.month + 1);
    _searchController.clear();
    setState(() {
      _query = '';
      _type = request.type;
      _accountId = request.accountId;
      _categoryId = request.categoryId;
      if (isWholeMonth) {
        _month = DateTime(start.year, start.month);
        _range = null;
      } else {
        _month = null;
        _range = DateTimeRange(
          start: start,
          end: end.subtract(const Duration(days: 1)),
        );
      }
    });
    _money.historyRequest.value = null;
  }

  int get _moreFilterCount =>
      (_accountId == null ? 0 : 1) + (_categoryId == null ? 0 : 1);

  bool get _hasNarrowingFilter =>
      _type != null || _moreFilterCount > 0 || _query.trim().isNotEmpty;

  bool get _canGoNext => _month != null && _month!.isBefore(_currentMonth());

  bool _inPeriod(DateTime date) {
    final month = _month;
    if (month != null) {
      return date.year == month.year && date.month == month.month;
    }
    final range = _range;
    if (range != null) {
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
      return !date.isBefore(start) && date.isBefore(end);
    }
    return true;
  }

  String get _periodLabel {
    final month = _month;
    if (month != null) {
      return DateFormat('MMMM yyyy', 'id_ID').format(month);
    }
    final range = _range;
    if (range != null) {
      final format = DateFormat('d MMM yyyy', 'id_ID');
      return '${format.format(range.start)} – ${format.format(range.end)}';
    }
    return 'Semua waktu';
  }

  List<FinanceActivity> _filtered() {
    final query = _query.trim().toLowerCase();
    final savings = Get.find<SavingsController>();
    return _money.activities.where((activity) {
      if (!_inPeriod(activity.date)) return false;
      final goalTransfer = activity.goalTransfer;
      if (goalTransfer != null) {
        if (_type != null && _type != 'transfer') return false;
        if (_accountId != null && goalTransfer.accountId != _accountId) {
          return false;
        }
        if (_categoryId != null) return false;
        if (query.isEmpty) return true;
        final account = _money
            .accountById(goalTransfer.accountId)
            ?.account
            .name;
        final goal = savings.goalById(goalTransfer.goalId)?.goal.name;
        return '${goalTransfer.note ?? ''} ${account ?? ''} ${goal ?? ''}'
            .toLowerCase()
            .contains(query);
      }
      final transaction = activity.transaction!.transaction;
      if (_type != null && transaction.type != _type) return false;
      if (_accountId != null &&
          transaction.accountId != _accountId &&
          transaction.destinationAccountId != _accountId) {
        return false;
      }
      if (_categoryId != null && transaction.categoryId != _categoryId) {
        return false;
      }
      if (query.isEmpty) return true;
      final category = _money.categoryById(transaction.categoryId)?.name ?? '';
      final source =
          _money.accountById(transaction.accountId)?.account.name ?? '';
      final destination =
          _money.accountById(transaction.destinationAccountId)?.account.name ??
          '';
      final tags = _money
          .tagsForTransaction(transaction.id)
          .map((item) => item.name)
          .join(' ');
      return '${transaction.note ?? ''} $category $source $destination $tags'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  ({int income, int expense}) _totals(List<FinanceActivity> activities) {
    var income = 0;
    var expense = 0;
    for (final activity in activities) {
      final transaction = activity.transaction?.transaction;
      if (transaction == null || isAdjustmentCategory(transaction.categoryId)) {
        continue;
      }
      if (transaction.type == 'income') income += transaction.amount;
      if (transaction.type == 'expense') expense += transaction.amount;
    }
    return (income: income, expense: expense);
  }

  List<_HistoryGroup> _groups(List<FinanceActivity> activities) {
    final grouped = <DateTime, List<FinanceActivity>>{};
    for (final activity in activities) {
      final date = activity.date;
      final day = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(day, () => []).add(activity);
    }
    final groups = grouped.entries.map((entry) {
      final totals = _totals(entry.value);
      return _HistoryGroup(
        date: entry.key,
        activities: entry.value..sort((a, b) => b.date.compareTo(a.date)),
        net: totals.income - totals.expense,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'HARI INI';
    if (day == today.subtract(const Duration(days: 1))) return 'KEMARIN';
    final firstWeekday = Get.find<AppPreferencesService>().firstWeekday.value;
    final offset = (today.weekday - firstWeekday + 7) % 7;
    final startOfWeek = today.subtract(Duration(days: offset));
    if (!day.isBefore(startOfWeek) && day.isBefore(today)) {
      return 'AWAL MINGGU INI';
    }
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(day).toUpperCase();
  }

  void _shiftMonth(int delta) {
    final month = _month;
    if (month == null) return;
    setState(() => _month = DateTime(month.year, month.month + delta));
  }

  void _setType(String? value) {
    setState(() {
      _type = value;
      if (value == 'transfer') {
        _categoryId = null;
      } else if (value != null) {
        final category = _money.categoryById(_categoryId);
        if (category != null && category.type != value) _categoryId = null;
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _type = null;
      _accountId = null;
      _categoryId = null;
    });
  }

  Future<void> _showPeriodSheet() async {
    var year = (_month ?? _currentMonth()).year;
    final latest = _currentMonth();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih periode',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Tahun sebelumnya',
                    onPressed: () => setSheetState(() => year--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$year',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tahun berikutnya',
                    onPressed: year >= latest.year
                        ? null
                        : () => setSheetState(() => year++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: [
                  for (var m = 1; m <= 12; m++)
                    ChoiceChip(
                      label: Text(
                        DateFormat('MMM', 'id_ID').format(DateTime(year, m)),
                      ),
                      selected: _month == DateTime(year, m),
                      onSelected: DateTime(year, m).isAfter(latest)
                          ? null
                          : (_) {
                              Navigator.pop(sheetContext);
                              setState(() {
                                _month = DateTime(year, m);
                                _range = null;
                              });
                            },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('Semua waktu'),
                trailing: _month == null && _range == null
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: context.ferikColors.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _month = null;
                    _range = null;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('Rentang tanggal'),
                trailing: _range == null
                    ? null
                    : Icon(
                        Icons.check_circle_rounded,
                        color: context.ferikColors.primary,
                      ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final selected = await showDateRangePicker(
                    context: this.context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDateRange: _range,
                  );
                  if (selected == null || !mounted) return;
                  setState(() {
                    _range = selected;
                    _month = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          void update(VoidCallback change) {
            setState(change);
            setSheetState(() {});
          }

          final categories = _money.userCategories
              .where((item) => _type == null || item.type == _type)
              .toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxs,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter lainnya',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _moreFilterCount == 0
                                ? null
                                : () => update(() {
                                    _accountId = null;
                                    _categoryId = null;
                                  }),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Dompet',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: _accountId == null,
                            onSelected: (_) => update(() => _accountId = null),
                          ),
                          for (final item in _money.accounts)
                            ChoiceChip(
                              avatar: Icon(
                                accountTypeIcon(item.account.type),
                                size: 18,
                                color: accountTypeColor(
                                  context,
                                  item.account.type,
                                ),
                              ),
                              label: Text(item.account.name),
                              selected: _accountId == item.account.id,
                              onSelected: (_) =>
                                  update(() => _accountId = item.account.id),
                            ),
                        ],
                      ),
                      if (_type != 'transfer') ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Kategori',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: _categoryId == null,
                              onSelected: (_) =>
                                  update(() => _categoryId = null),
                            ),
                            for (final item in categories)
                              ChoiceChip(
                                avatar: Icon(iconForName(item.icon), size: 18),
                                label: Text(item.name),
                                selected: _categoryId == item.id,
                                onSelected: (_) =>
                                    update(() => _categoryId = item.id),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privacy = Get.find<PrivacyService>();
    final accountName = _money.accountById(_accountId)?.account.name;
    final categoryName = _money.categoryById(_categoryId)?.name;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi',
                        prefixIcon: const Icon(Icons.search_rounded, size: 21),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 19),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Badge(
                  isLabelVisible: _moreFilterCount > 0,
                  label: Text('$_moreFilterCount'),
                  child: IconButton.filledTonal(
                    tooltip: 'Filter dompet dan kategori',
                    onPressed: _showMoreFilters,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          _PeriodBar(
            label: _periodLabel,
            canGoPrevious: _month != null,
            canGoNext: _canGoNext,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
            onTap: _showPeriodSheet,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SegmentedButton<String?>(
              key: const Key('history-type-filter'),
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: [
                for (final option in _typeOptions)
                  ButtonSegment<String?>(
                    value: option.$1,
                    label: Text(option.$2),
                  ),
              ],
              selected: {_type},
              onSelectionChanged: (value) => _setType(value.first),
            ),
          ),
          if (accountName != null || categoryName != null)
            SizedBox(
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    if (accountName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: InputChip(
                          label: Text('Dompet: $accountName'),
                          onDeleted: () => setState(() => _accountId = null),
                        ),
                      ),
                    if (categoryName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: InputChip(
                          label: Text('Kategori: $categoryName'),
                          onDeleted: () => setState(() => _categoryId = null),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Obx(() {
              final visible = privacy.showMoney.value;
              final activities = _filtered();
              if (_money.activities.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  message: 'Catat pemasukan atau pengeluaran pertamamu.',
                  action: _money.accounts.isEmpty
                      ? null
                      : FilledButton.icon(
                          onPressed: () => showTransactionForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Catat Transaksi'),
                        ),
                );
              }
              if (activities.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: _hasNarrowingFilter
                      ? 'Tidak ada yang cocok'
                      : 'Belum ada transaksi di periode ini',
                  message: _hasNarrowingFilter
                      ? 'Coba ubah pencarian atau filter.'
                      : 'Pilih bulan lain atau lihat semua waktu.',
                  action: _hasNarrowingFilter
                      ? OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Hapus filter'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _month = null;
                            _range = null;
                          }),
                          icon: const Icon(Icons.all_inclusive_rounded),
                          label: const Text('Semua waktu'),
                        ),
                );
              }
              final totals = _totals(activities);
              final groups = _groups(activities);
              return Column(
                children: [
                  _SummaryStrip(
                    income: totals.income,
                    expense: totals.expense,
                    visible: visible,
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        100,
                      ),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (context, groupIndex) {
                        final group = groups[groupIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DayHeader(
                              group: group,
                              label: _groupLabel(group.date),
                              visible: visible,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            FerikCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < group.activities.length;
                                    index++
                                  )
                                    FinanceActivityTile(
                                      activity: group.activities[index],
                                      visible: visible,
                                      showDivider:
                                          index < group.activities.length - 1,
                                      onTransactionTap:
                                          group.activities[index].transaction ==
                                              null
                                          ? null
                                          : () => showTransactionDetail(
                                              context,
                                              group
                                                  .activities[index]
                                                  .transaction!
                                                  .transaction,
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.label,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
  });

  final String label;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: canGoPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              key: const Key('history-period-button'),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: onTap,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.income,
    required this.expense,
    required this.visible,
  });

  final int income;
  final int expense;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (income == 0 && expense == 0) return const SizedBox(height: 4);
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    Widget cell(String label, int amount, MoneyTone tone) => Expanded(
      child: Row(
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: MoneyText(
              amount: amount,
              visible: visible,
              tone: tone,
              scaleDown: true,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xxs,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Row(
        children: [
          cell('Masuk', income, MoneyTone.income),
          const SizedBox(width: AppSpacing.sm),
          cell('Keluar', expense, MoneyTone.expense),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.group,
    required this.label,
    required this.visible,
  });

  final _HistoryGroup group;
  final String label;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final positive = group.net > 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(letterSpacing: 0.7),
          ),
        ),
        if (group.net != 0)
          MoneyText(
            amount: group.net.abs(),
            visible: visible,
            tone: positive ? MoneyTone.income : MoneyTone.expense,
            showSign: true,
            style: Theme.of(context).textTheme.labelLarge,
          ),
      ],
    );
  }
}

class _HistoryGroup {
  const _HistoryGroup({
    required this.date,
    required this.activities,
    required this.net,
  });

  final DateTime date;
  final List<FinanceActivity> activities;
  final int net;
}
