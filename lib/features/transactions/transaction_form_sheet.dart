import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../services/app_preferences_service.dart';
import '../../services/currency_service.dart';
import '../../services/privacy_service.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/account_icon_tile.dart';
import '../../widgets/amount_input.dart';
import '../../widgets/feedback.dart';
import '../../widgets/money_text.dart';
import '../../widgets/transaction_type_selector.dart';
import '../main/money_controller.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  MoneyTransaction? transaction,
  bool duplicate = false,
  String? initialCategoryId,
  String? initialAccountId,
  TransactionFormInitialValue? initialValue,
  TransactionFormSubmit? onSubmit,
  String? title,
  String? successMessage,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TransactionFormSheet(
      transaction: transaction,
      duplicate: duplicate,
      initialCategoryId: initialCategoryId,
      initialAccountId: initialAccountId,
      initialValue: initialValue,
      onSubmit: onSubmit,
      title: title,
      successMessage: successMessage,
    ),
  );
}

typedef TransactionFormSubmit =
    Future<void> Function(TransactionFormValue value);

class TransactionFormInitialValue {
  const TransactionFormInitialValue({
    required this.type,
    required this.amount,
    required this.accountId,
    required this.destinationAccountId,
    required this.categoryId,
    required this.note,
    required this.tags,
    required this.date,
  });

  final String type;
  final int amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String? note;
  final List<String> tags;
  final DateTime date;
}

class TransactionFormValue {
  const TransactionFormValue({
    required this.type,
    required this.amount,
    required this.accountId,
    required this.destinationAccountId,
    required this.categoryId,
    required this.note,
    required this.tags,
    required this.date,
  });

  final String type;
  final int amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String? note;
  final List<String> tags;
  final DateTime date;
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    this.transaction,
    this.duplicate = false,
    this.initialCategoryId,
    this.initialAccountId,
    this.initialValue,
    this.onSubmit,
    this.title,
    this.successMessage,
  });

  final MoneyTransaction? transaction;
  final bool duplicate;
  final String? initialCategoryId;
  final String? initialAccountId;
  final TransactionFormInitialValue? initialValue;
  final TransactionFormSubmit? onSubmit;
  final String? title;
  final String? successMessage;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _money = Get.find<MoneyController>();
  final _preferences = Get.find<AppPreferencesService>();
  final _currency = Get.find<CurrencyService>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _type;
  String? _accountId;
  String? _destinationAccountId;
  String? _categoryId;
  late DateTime _date;
  // Tags no longer have UI, but existing ones are kept when a transaction is
  // edited so old data is never dropped silently.
  final _tags = <String>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    final initialValue = widget.initialValue;
    _type = transaction?.type ?? initialValue?.type ?? 'expense';
    _amountController = TextEditingController(
      text: transaction == null && initialValue == null
          ? ''
          : _currency.formatInputDigits(
              (transaction?.amount ?? initialValue!.amount).toString(),
            ),
    );
    _noteController = TextEditingController(
      text: transaction?.note ?? initialValue?.note ?? '',
    );
    if (transaction != null) {
      _tags.addAll(
        _money.tagsForTransaction(transaction.id).map((item) => item.name),
      );
    } else if (initialValue != null) {
      _tags.addAll(initialValue.tags);
    }
    final preferredAccount =
        widget.initialAccountId ??
        _preferences.defaultAccountId.value ??
        _preferences.lastAccountId.value;
    _accountId =
        transaction?.accountId ??
        initialValue?.accountId ??
        _activeAccountId(preferredAccount);
    _destinationAccountId =
        transaction?.destinationAccountId ?? initialValue?.destinationAccountId;
    _categoryId =
        transaction?.categoryId ??
        initialValue?.categoryId ??
        widget.initialCategoryId ??
        _rememberedCategoryId(_type) ??
        _firstCategoryId(_type);
    _date = widget.duplicate
        ? DateTime.now()
        : transaction?.transactionDate ?? initialValue?.date ?? DateTime.now();
  }

  String? _activeAccountId(String? preferred) {
    if (preferred != null &&
        _money.activeAccounts.any((item) => item.account.id == preferred)) {
      return preferred;
    }
    return _money.activeAccounts.isEmpty
        ? null
        : _money.activeAccounts.first.account.id;
  }

  String? _rememberedCategoryId(String type) {
    final value = type == 'income'
        ? _preferences.lastIncomeCategoryId.value
        : _preferences.lastExpenseCategoryId.value;
    if (value != null &&
        _money.activeCategories.any(
          (item) => item.id == value && item.type == type,
        )) {
      return value;
    }
    return null;
  }

  String? _firstCategoryId(String type) {
    for (final category in _money.activeCategories) {
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

  int get _amount => _currency.parseInput(_amountController.text);

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
      _categoryId = value == 'transfer'
          ? null
          : _rememberedCategoryId(value) ?? _firstCategoryId(value);
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
                  final isSelected = choice.value == selected;
                  return ListTile(
                    minTileHeight: 60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    leading: choice.leading ?? Icon(choice.icon),
                    title: Text(choice.label),
                    subtitle: choice.subtitle == null
                        ? null
                        : Text(choice.subtitle!),
                    trailing: choice.trailing == null && !isSelected
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ?choice.trailing,
                              if (isSelected) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: context.ferikColors.primary,
                                ),
                              ],
                            ],
                          ),
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
    final frequent = _money.frequentCategories(_type);
    final categories =
        _money.activeCategories
            .where((category) => category.type == _type)
            .toList()
          ..sort((a, b) {
            final aIndex = frequent.indexWhere((item) => item.id == a.id);
            final bIndex = frequent.indexWhere((item) => item.id == b.id);
            if (aIndex >= 0 || bIndex >= 0) {
              if (aIndex < 0) return 1;
              if (bIndex < 0) return -1;
              return aIndex.compareTo(bIndex);
            }
            return a.name.compareTo(b.name);
          });
    final choices = categories
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
    final visible = Get.find<PrivacyService>().showMoney.value;
    final choices = _money.activeAccounts
        .where((item) => !destination || item.account.id != _accountId)
        .map(
          (item) => _Choice(
            value: item.account.id,
            label: item.account.name,
            icon: accountTypeIcon(item.account.type),
            leading: AccountIconTile(type: item.account.type, size: 44),
            subtitle: accountTypeLabel(item.account.type),
            trailing: SizedBox(
              width: 108,
              child: MoneyText(
                amount: item.balance,
                visible: visible,
                scaleDown: true,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
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

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _setDateShortcut(int dayOffset) {
    final target = DateTime.now().subtract(Duration(days: dayOffset));
    setState(() {
      _date = DateTime(
        target.year,
        target.month,
        target.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final value = TransactionFormValue(
        type: _type,
        amount: _amount,
        accountId: _accountId ?? '',
        destinationAccountId: _destinationAccountId,
        categoryId: _categoryId,
        note: _noteController.text,
        tags: List.unmodifiable(_tags),
        date: _date,
      );
      if (widget.onSubmit case final submit?) {
        await submit(value);
      } else {
        await Get.find<MoneyRepository>().saveTransaction(
          id: widget.duplicate ? null : widget.transaction?.id,
          type: value.type,
          amount: value.amount,
          accountId: value.accountId,
          destinationAccountId: value.destinationAccountId,
          categoryId: value.categoryId,
          note: value.note,
          tags: value.tags,
          transactionDate: value.date,
        );
      }
      await _preferences.rememberTransaction(
        type: _type,
        accountId: _accountId!,
        categoryId: _categoryId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showFeedback(
        'Tersimpan',
        widget.successMessage ??
            (widget.transaction == null || widget.duplicate
                ? 'Transaksi berhasil dicatat.'
                : 'Transaksi berhasil diperbarui.'),
        duration: const Duration(seconds: 2),
      );
    } on MoneyValidationException catch (error) {
      showFeedback('Periksa transaksi', error.message);
    } catch (_) {
      showFeedback('Terjadi kesalahan', 'Transaksi tidak dapat disimpan.');
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
    final isToday = _isSameDay(_date, today);
    final isYesterday = _isSameDay(
      _date,
      today.subtract(const Duration(days: 1)),
    );
    final buttonPrefix = _type == 'transfer' ? 'Transfer' : 'Simpan';
    final buttonLabel = _amount > 0
        ? '$buttonPrefix ${_currency.format(_amount)}'
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
          child: Column(
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.title ??
                            (widget.duplicate
                                ? 'Duplikat $_fullTypeLabel'
                                : widget.transaction == null
                                ? 'Catat $_fullTypeLabel'
                                : 'Edit $_fullTypeLabel'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TransactionTypeSelector(
                        value: _type,
                        onChanged: _changeType,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AmountInput(
                        controller: _amountController,
                        autofocus:
                            widget.transaction == null || widget.duplicate,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const Key('transaction-note-input'),
                        controller: _noteController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Catatan (opsional)',
                          prefixIcon: const Icon(Icons.notes_rounded),
                          fillColor: context.ferikFieldFill,
                        ),
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
                              icon: Icons.account_balance_wallet_outlined,
                              leading: account == null
                                  ? null
                                  : AccountIconTile(
                                      type: account.type,
                                      size: 36,
                                    ),
                              onTap: () => _pickAccount(destination: false),
                            ),
                            if (_type == 'transfer') ...[
                              const SizedBox(height: AppSpacing.xs),
                              _SelectorRow(
                                label: 'Ke akun',
                                value: destination?.name ?? 'Pilih akun tujuan',
                                icon: Icons.account_balance_wallet_outlined,
                                leading: destination == null
                                    ? null
                                    : AccountIconTile(
                                        type: destination.type,
                                        size: 36,
                                      ),
                                onTap: () => _pickAccount(destination: true),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            key: const Key('transaction-date-today'),
                            avatar: const Icon(Icons.today_outlined, size: 18),
                            label: const Text('Hari ini'),
                            selected: isToday,
                            onSelected: (_) => _setDateShortcut(0),
                          ),
                          ChoiceChip(
                            key: const Key('transaction-date-yesterday'),
                            avatar: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('Kemarin'),
                            selected: isYesterday,
                            onSelected: (_) => _setDateShortcut(1),
                          ),
                          ChoiceChip(
                            key: const Key('transaction-date-pick'),
                            avatar: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                            label: Text(
                              isToday || isYesterday
                                  ? 'Pilih tanggal'
                                  : DateFormat(
                                      'd MMM yyyy',
                                      'id_ID',
                                    ).format(_date),
                            ),
                            selected: !isToday && !isYesterday,
                            onSelected: (_) => _pickDate(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Pinned so Simpan never scrolls out of reach on small phones.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: FilledButton.icon(
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
              ),
            ],
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
    this.leading,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  /// Replaces the default icon tile, e.g. with an [AccountIconTile].
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return Material(
      color: colors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: context.ferikSelectorBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.ferikSelectorIconBackground,
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
  const _Choice({
    required this.value,
    required this.label,
    required this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
  });

  final T value;
  final String label;
  final IconData icon;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
}
