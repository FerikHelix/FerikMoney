import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../services/privacy_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/transaction_tile.dart';
import '../main/money_controller.dart';
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
  DateTime? _month;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _filterCount => [
    _type,
    _accountId,
    _categoryId,
    _month,
  ].where((value) => value != null).length;

  List<MoneyTransaction> _filtered(MoneyController money) {
    final query = _query.trim().toLowerCase();
    return money.transactions.where((transaction) {
      if (_type != null && transaction.type != _type) return false;
      if (_accountId != null &&
          transaction.accountId != _accountId &&
          transaction.destinationAccountId != _accountId) {
        return false;
      }
      if (_categoryId != null && transaction.categoryId != _categoryId) {
        return false;
      }
      if (_month != null &&
          (transaction.transactionDate.year != _month!.year ||
              transaction.transactionDate.month != _month!.month)) {
        return false;
      }
      if (query.isEmpty) return true;
      final category = money.categoryById(transaction.categoryId)?.name ?? '';
      final source =
          money.accountById(transaction.accountId)?.account.name ?? '';
      final destination =
          money.accountById(transaction.destinationAccountId)?.account.name ??
          '';
      return '${transaction.note ?? ''} $category $source $destination'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  List<_HistoryGroup> _groups(List<MoneyTransaction> transactions) {
    final grouped = <DateTime, List<MoneyTransaction>>{};
    for (final transaction in transactions) {
      final date = transaction.transactionDate;
      final day = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(day, () => []).add(transaction);
    }
    return grouped.entries.map((entry) {
      var net = 0;
      for (final transaction in entry.value) {
        if (transaction.type == 'income') net += transaction.amount;
        if (transaction.type == 'expense') net -= transaction.amount;
      }
      return _HistoryGroup(
        date: entry.key,
        transactions: entry.value,
        net: net,
      );
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _type = null;
      _accountId = null;
      _categoryId = null;
      _month = null;
    });
  }

  Future<void> _showFilters(MoneyController money) async {
    var type = _type;
    var account = _accountId;
    var category = _categoryId;
    var month = _month;
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
                      month = null;
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.ferikColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.ferikInteractiveBorder),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Filter bulan'),
                  subtitle: Text(
                    month == null ? 'Semua bulan' : monthLabel(month!),
                  ),
                  value: month != null,
                  onChanged: (enabled) => setSheetState(
                    () => month = enabled ? DateTime.now() : null,
                  ),
                ),
              ),
              if (month != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Bulan sebelumnya',
                      onPressed: () => setSheetState(
                        () => month = DateTime(month!.year, month!.month - 1),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    SizedBox(
                      width: 170,
                      child: Text(
                        monthLabel(month!),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bulan berikutnya',
                      onPressed: () => setSheetState(
                        () => month = DateTime(month!.year, month!.month + 1),
                      ),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
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
        _month = month;
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
              final transactions = _filtered(money);
              if (money.transactions.isEmpty) {
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
              if (transactions.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Transaksi tidak ditemukan',
                  message: 'Coba ubah pencarian atau filter.',
                );
              }
              final groups = _groups(transactions);
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
                      _DayHeader(group: group, visible: visible),
                      const SizedBox(height: AppSpacing.xs),
                      FerikCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index < group.transactions.length;
                              index++
                            )
                              TransactionTile(
                                transaction: group.transactions[index],
                                accountName:
                                    money
                                        .accountById(
                                          group.transactions[index].accountId,
                                        )
                                        ?.account
                                        .name ??
                                    '-',
                                destinationName: money
                                    .accountById(
                                      group
                                          .transactions[index]
                                          .destinationAccountId,
                                    )
                                    ?.account
                                    .name,
                                category: money.categoryById(
                                  group.transactions[index].categoryId,
                                ),
                                visible: visible,
                                showDivider:
                                    index < group.transactions.length - 1,
                                onTap: () => showTransactionDetail(
                                  context,
                                  group.transactions[index],
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
  const _DayHeader({required this.group, required this.visible});

  final _HistoryGroup group;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final positive = group.net > 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            relativeDateLabel(group.date).toUpperCase(),
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
    required this.transactions,
    required this.net,
  });

  final DateTime date;
  final List<MoneyTransaction> transactions;
  final int net;
}
