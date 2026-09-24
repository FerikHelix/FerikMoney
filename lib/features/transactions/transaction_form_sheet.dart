import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../utils/icon_mapper.dart';
import '../../utils/money_formatter.dart';
import '../../widgets/amount_input.dart';
import '../../widgets/transaction_type_selector.dart';
import '../main/money_controller.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  MoneyTransaction? transaction,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TransactionFormSheet(transaction: transaction),
  );
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({super.key, this.transaction});

  final MoneyTransaction? transaction;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _money = Get.find<MoneyController>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _type;
  String? _accountId;
  String? _destinationAccountId;
  String? _categoryId;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _type = transaction?.type ?? 'expense';
    _amountController = TextEditingController(
      text: transaction == null
          ? ''
          : NumberFormat.decimalPattern('id_ID').format(transaction.amount),
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _accountId =
        transaction?.accountId ??
        (_money.accounts.isEmpty ? null : _money.accounts.first.account.id);
    _destinationAccountId = transaction?.destinationAccountId;
    _categoryId = transaction?.categoryId ?? _firstCategoryId(_type);
    _date = transaction?.transactionDate ?? DateTime.now();
  }

  String? _firstCategoryId(String type) {
    for (final category in _money.categories) {
      if (category.type == type) return category.id;
    }
    return null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _amount => parseRupiah(_amountController.text);

  bool get _canSave {
    if (_saving || _amount <= 0 || _accountId == null) return false;
    if (_type == 'transfer') {
      return _destinationAccountId != null &&
          _destinationAccountId != _accountId;
    }
    return _categoryId != null;
  }

  String get _fullTypeLabel => switch (_type) {
    'income' => 'Pemasukan',
    'transfer' => 'Transfer',
    _ => 'Pengeluaran',
  };

  void _changeType(String value) {
    setState(() {
      _type = value;
      _categoryId = value == 'transfer' ? null : _firstCategoryId(value);
      if (value != 'transfer') _destinationAccountId = null;
    });
  }

  Future<T?> _select<T>({
    required String title,
    required List<_Choice<T>> choices,
    required T? selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: choices.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final choice = choices[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    leading: Icon(choice.icon),
                    title: Text(choice.label),
                    trailing: choice.value == selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.ferikColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, choice.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final choices = _money.categories
        .where((category) => category.type == _type)
        .map(
          (category) => _Choice(
            value: category.id,
            label: category.name,
            icon: iconForName(category.icon),
          ),
        )
        .toList();
    final value = await _select<String>(
      title: 'Pilih Kategori',
      choices: choices,
      selected: _categoryId,
    );
    if (value != null) setState(() => _categoryId = value);
  }

  Future<void> _pickAccount({required bool destination}) async {
    final choices = _money.accounts
        .where((item) => !destination || item.account.id != _accountId)
        .map(
          (item) => _Choice(
            value: item.account.id,
            label: item.account.name,
            icon: iconForName(item.account.icon),
          ),
        )
        .toList();
    final value = await _select<String>(
      title: destination ? 'Pilih Akun Tujuan' : 'Pilih Akun',
      choices: choices,
      selected: destination ? _destinationAccountId : _accountId,
    );
    if (value == null) return;
    setState(() {
      if (destination) {
        _destinationAccountId = value;
      } else {
        _accountId = value;
        if (_destinationAccountId == value) _destinationAccountId = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected == null) return;
    setState(() {
      _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await Get.find<MoneyRepository>().saveTransaction(
        id: widget.transaction?.id,
        type: _type,
        amount: _amount,
        accountId: _accountId ?? '',
        destinationAccountId: _destinationAccountId,
        categoryId: _categoryId,
        note: _noteController.text,
        transactionDate: _date,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Get.snackbar(
        'Tersimpan',
        widget.transaction == null
            ? 'Transaksi berhasil dicatat.'
            : 'Transaksi berhasil diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } on MoneyValidationException catch (error) {
      Get.snackbar('Periksa transaksi', error.message);
    } catch (_) {
      Get.snackbar('Terjadi kesalahan', 'Transaksi tidak dapat disimpan.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final category = _money.categoryById(_categoryId);
    final account = _money.accountById(_accountId)?.account;
    final destination = _money.accountById(_destinationAccountId)?.account;
    final today = DateTime.now();
    final isToday =
        _date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day;
    final buttonPrefix = _type == 'transfer' ? 'Transfer' : 'Simpan';
    final buttonLabel = _amount > 0
        ? '$buttonPrefix ${formatRupiah(_amount)}'
        : buttonPrefix;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.91,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.transaction == null
                      ? 'Catat $_fullTypeLabel'
                      : 'Edit $_fullTypeLabel',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TransactionTypeSelector(value: _type, onChanged: _changeType),
                const SizedBox(height: AppSpacing.md),
                AmountInput(
                  controller: _amountController,
                  autofocus: widget.transaction == null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      if (_type != 'transfer') ...[
                        _SelectorRow(
                          label: 'Kategori',
                          value: category?.name ?? 'Pilih kategori',
                          icon: category == null
                              ? Icons.category_outlined
                              : iconForName(category.icon),
                          onTap: _pickCategory,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      _SelectorRow(
                        label: _type == 'income'
                            ? 'Akun tujuan'
                            : _type == 'transfer'
                            ? 'Dari akun'
                            : 'Akun',
                        value: account?.name ?? 'Pilih akun',
                        icon: account == null
                            ? Icons.account_balance_wallet_outlined
                            : iconForName(account.icon),
                        onTap: () => _pickAccount(destination: false),
                      ),
                      if (_type == 'transfer') ...[
                        const SizedBox(height: AppSpacing.xs),
                        _SelectorRow(
                          label: 'Ke akun',
                          value: destination?.name ?? 'Pilih akun tujuan',
                          icon: destination == null
                              ? Icons.account_balance_wallet_outlined
                              : iconForName(destination.icon),
                          onTap: () => _pickAccount(destination: true),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SelectorRow(
                  label: 'Tanggal',
                  value: isToday
                      ? 'Hari ini'
                      : DateFormat('d MMMM yyyy', 'id_ID').format(_date),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Catatan (opsional)',
                    prefixIcon: const Icon(Icons.notes_rounded),
                    fillColor: context.isFerikDark
                        ? context.ferikColors.surfaceVariant
                        : context.ferikColors.background,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const Key('transaction-save-button'),
                  onPressed: _canSave ? _save : null,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _type == 'transfer'
                              ? Icons.swap_horiz_rounded
                              : Icons.check_rounded,
                        ),
                  label: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return Material(
      color: colors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: context.isFerikDark
              ? colors.divider.withValues(alpha: 0.7)
              : colors.borderStandard,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.isFerikDark
                      ? colors.surface
                      : colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 19, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class _Choice<T> {
  const _Choice({required this.value, required this.label, required this.icon});

  final T value;
  final String label;
  final IconData icon;
}
