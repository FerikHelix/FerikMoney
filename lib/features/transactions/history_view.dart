import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../models/finance_models.dart';
import '../../services/app_preferences_service.dart';
import '../../services/privacy_service.dart';
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
  final _searchController = TextEditingController();
  String _query = '';
  String? _type;
  String? _accountId;
  String? _categoryId;
  DateTimeRange? _dateRange;
  TransactionSort _sort = TransactionSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _filterCount => [
    _type,
    _accountId,
    _categoryId,
    _dateRange,
    _sort == TransactionSort.newest ? null : _sort,
  ].where((value) => value != null).length;

  List<FinanceActivity> _filtered(MoneyController money) {
    final query = _query.trim().toLowerCase();
    final savings = Get.find<SavingsController>();
    return money.activities.where((activity) {
      final goalTransfer = activity.goalTransfer;
      if (goalTransfer != null) {
        if (_type != null && _type != 'transfer') return false;
        if (_accountId != null && goalTransfer.accountId != _accountId) {
          return false;
        }
        if (_categoryId != null) return false;
        if (_dateRange != null &&
            (goalTransfer.transferDate.isBefore(_dateRange!.start) ||
                !goalTransfer.transferDate.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ))) {
          return false;
        }
        if (query.isEmpty) return true;
        final account = money.accountById(goalTransfer.accountId)?.account.name;
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
      if (_dateRange != null &&
          (transaction.transactionDate.isBefore(_dateRange!.start) ||
              !transaction.transactionDate.isBefore(
                _dateRange!.end.add(const Duration(days: 1)),
              ))) {
        return false;
      }
      if (query.isEmpty) return true;
      final category = money.categoryById(transaction.categoryId)?.name ?? '';
      final source =
          money.accountById(transaction.accountId)?.account.name ?? '';
      final destination =
          money.accountById(transaction.destinationAccountId)?.account.name ??
          '';
      final tags = money
          .tagsForTransaction(transaction.id)
          .map((item) => item.name)
          .join(' ');
      return '${transaction.note ?? ''} $category $source $destination $tags'
          .toLowerCase()
          .contains(query);
    }).toList()..sort(
      (a, b) => switch (_sort) {
        TransactionSort.newest => b.date.compareTo(a.date),
        TransactionSort.oldest => a.date.compareTo(b.date),
        TransactionSort.highest => b.amount.compareTo(a.amount),
        TransactionSort.lowest => a.amount.compareTo(b.amount),
      },
    );
  }

  List<_HistoryGroup> _groups(List<FinanceActivity> activities) {
    final grouped = <DateTime, List<FinanceActivity>>{};
    for (final activity in activities) {
      final date = activity.date;
      final day = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(day, () => []).add(activity);
    }
    final groups = grouped.entries.map((entry) {
      var net = 0;
      for (final activity in entry.value) {
        final transaction = activity.transaction?.transaction;
        if (transaction == null) continue;
        if (transaction.type == 'income') net += transaction.amount;
        if (transaction.type == 'expense') net -= transaction.amount;
      }
      return _HistoryGroup(
        date: entry.key,
        activities: entry.value
          ..sort(
            (a, b) => switch (_sort) {
              TransactionSort.oldest => a.date.compareTo(b.date),
              TransactionSort.highest => b.amount.compareTo(a.amount),
              TransactionSort.lowest => a.amount.compareTo(b.amount),
              TransactionSort.newest => b.date.compareTo(a.date),
            },
          ),
        net: net,
      );
    }).toList();
    groups.sort(
      (a, b) => _sort == TransactionSort.oldest
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date),
    );
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

  void _clearFilters() {
    setState(() {
      _type = null;
      _accountId = null;
      _categoryId = null;
      _dateRange = null;
      _sort = TransactionSort.newest;
    });
  }

  Future<void> _showFilters(MoneyController money) async {
    var type = _type;
    var account = _accountId;
    var category = _categoryId;
    var dateRange = _dateRange;
    var sort = _sort;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Riwayat',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setSheetState(() {
                      type = null;
                      account = null;
                      category = null;
                      dateRange = null;
                      sort = TransactionSort.newest;
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Jenis transaksi',
                  prefixIcon: Icon(Icons.swap_vert_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua jenis')),
                  DropdownMenuItem(
                    value: 'expense',
                    child: Text('Pengeluaran'),
                  ),
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                ],
                onChanged: (value) => setSheetState(() => type = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                initialValue: account,
                decoration: const InputDecoration(
                  labelText: 'Akun',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua akun'),
                  ),
                  ...money.accounts.map(
                    (item) => DropdownMenuItem(
                      value: item.account.id,
                      child: Text(item.account.name),
                    ),
                  ),
                ],
                onChanged: (value) => setSheetState(() => account = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua kategori'),
                  ),
                  ...money.categories.map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: (value) => setSheetState(() => category = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<TransactionSort>(
                initialValue: sort,
                decoration: const InputDecoration(
                  labelText: 'Urutkan',
                  prefixIcon: Icon(Icons.sort_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TransactionSort.newest,
                    child: Text('Terbaru'),
                  ),
                  DropdownMenuItem(
                    value: TransactionSort.oldest,
                    child: Text('Terlama'),
                  ),
                  DropdownMenuItem(
                    value: TransactionSort.highest,
                    child: Text('Nominal tertinggi'),
                  ),
                  DropdownMenuItem(
                    value: TransactionSort.lowest,
                    child: Text('Nominal terendah'),
                  ),
                ],
                onChanged: (value) => setSheetState(() => sort = value ?? sort),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDateRange: dateRange,
                  );
                  if (selected != null) {
                    setSheetState(() => dateRange = selected);
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  dateRange == null
                      ? 'Semua tanggal'
                      : '${DateFormat('d MMM yyyy', 'id_ID').format(dateRange!.start)} – ${DateFormat('d MMM yyyy', 'id_ID').format(dateRange!.end)}',
                ),
              ),
              if (dateRange != null)
                TextButton(
                  onPressed: () => setSheetState(() => dateRange = null),
                  child: const Text('Hapus rentang tanggal'),
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Terapkan Filter'),
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true) {
      setState(() {
        _type = type;
        _accountId = account;
        _categoryId = category;
        _dateRange = dateRange;
        _sort = sort;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = Get.find<MoneyController>();
    final privacy = Get.find<PrivacyService>();
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
                  isLabelVisible: _filterCount > 0,
                  label: Text('$_filterCount'),
                  child: IconButton.filledTonal(
                    tooltip: 'Filter riwayat',
                    onPressed: () => _showFilters(money),
                    style: context.isFerikDark
                        ? null
                        : IconButton.styleFrom(
                            backgroundColor: _filterCount > 0
                                ? context.ferikColors.primary
                                : context.ferikColors.primarySoft,
                            foregroundColor: _filterCount > 0
                                ? Colors.white
                                : context.ferikColors.primary,
                          ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          if (_filterCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.filter_alt_off_outlined, size: 17),
                  label: Text('Hapus $_filterCount filter'),
                  onPressed: _clearFilters,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Obx(() {
              final visible = privacy.showMoney.value;
              final activities = _filtered(money);
              if (money.activities.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  message: 'Catat pemasukan atau pengeluaran pertamamu.',
                  action: money.accounts.isEmpty
                      ? null
                      : FilledButton.icon(
                          onPressed: () => showTransactionForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Catat Transaksi'),
                        ),
                );
              }
              if (activities.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Transaksi tidak ditemukan',
                  message: 'Coba ubah pencarian atau filter.',
                );
              }
              final groups = _groups(activities);
              return ListView.separated(
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
                                    group.activities[index].transaction == null
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
              );
            }),
          ),
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
