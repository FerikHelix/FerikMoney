import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/dates/date_keys.dart';
import '../../core/db/database.dart';
import '../../core/models/models.dart';
import '../../core/money/rupiah.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/l10n.dart';

class DebtPaymentScreen extends ConsumerStatefulWidget {
  const DebtPaymentScreen({required this.debtId, super.key});

  final int debtId;

  @override
  ConsumerState<DebtPaymentScreen> createState() => _DebtPaymentScreenState();
}

class _DebtPaymentScreenState extends ConsumerState<DebtPaymentScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _date = todayKey();
  bool _commit = false;
  int? _walletId;
  int? _categoryId;
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  DebtStatus? _status;
  bool _ready = false;
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  String? _amountError;
  String? _walletError;
  String? _categoryError;

  CategoryKind get _commitKind =>
      _status?.isUtang ?? true ? CategoryKind.expense : CategoryKind.income;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_markDirty);
    _note.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      _dirty = true;
    }
  }

  Future<void> _load() async {
    final database = ref.read(databaseProvider);
    final status = await database.debtDao.statusById(widget.debtId);
    final wallets = await database.walletDao.active();
    final categories = await database.transactionDao.listCategories(
      kind: status?.isUtang ?? true
          ? CategoryKind.expense
          : CategoryKind.income,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _status = status;
      _wallets = wallets;
      _categories = categories;
      _walletId = wallets.isEmpty ? null : wallets.first.id;
      _categoryId = categories.isEmpty ? null : categories.first.id;
      _ready = true;
      _dirty = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDateKey(_date),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = dateKey(picked));
      _markDirty();
    }
  }

  bool _validate() {
    var valid = true;
    final amount = parseRupiah(_amount.text) ?? 0;
    final remaining = _status?.remaining ?? 0;
    if (amount <= 0) {
      _amountError = context.l10n.amountRequired;
      valid = false;
    } else if (amount > remaining) {
      _amountError = context.l10n.paymentTooLarge(formatRupiah(remaining));
      valid = false;
    } else {
      _amountError = null;
    }
    if (_commit && _walletId == null) {
      _walletError = context.l10n.requiredField;
      valid = false;
    } else {
      _walletError = null;
    }
    if (_commit && _categoryId == null) {
      _categoryError = context.l10n.requiredField;
      valid = false;
    } else {
      _categoryError = null;
    }
    setState(() {});
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(databaseProvider)
          .debtDao
          .recordPayment(
            debtId: widget.debtId,
            amount: parseRupiah(_amount.text)!,
            date: _date,
            note: _note.text,
            commitWalletId: _commit ? _walletId : null,
            commitCategoryId: _commit ? _categoryId : null,
          );
      if (!mounted) {
        return;
      }
      _saved = true;
      showSavedMessage(context, context.l10n.paymentSaved);
      context.pop();
    } catch (error) {
      if (mounted) {
        showSavedMessage(context, errorMessage(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? get _walletName {
    for (final wallet in _wallets) {
      if (wallet.id == _walletId) {
        return wallet.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _status?.remaining ?? 0;
    return DirtyPopScope(
      dirty: _dirty && !_saved,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.recordPayment)),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${context.l10n.remaining}: ${formatRupiah(remaining)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  RupiahField(
                    controller: _amount,
                    label: context.l10n.paymentAmount,
                    autofocus: true,
                    errorText: _amountError,
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: context.l10n.date,
                    value: _date,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  NoteField(controller: _note),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.commitToMoney),
                    subtitle: Text(context.l10n.commitHint),
                    value: _commit,
                    onChanged: (value) {
                      setState(() => _commit = value);
                      _markDirty();
                    },
                  ),
                  if (_commit) ...[
                    WalletDropdown(
                      wallets: _wallets,
                      value: _walletId,
                      label: context.l10n.wallet,
                      errorText: _walletError,
                      onChanged: (value) => setState(() => _walletId = value),
                    ),
                    const SizedBox(height: 12),
                    CategoryDropdown(
                      categories: _categories,
                      value: _categoryId,
                      label: context.l10n.category,
                      errorText: _categoryError,
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                    if (_walletName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _commitKind == CategoryKind.income
                            ? context.l10n.commitIncomeTo(_walletName!)
                            : context.l10n.commitExpenseFrom(_walletName!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                  const SizedBox(height: 96),
                ],
              ),
        bottomNavigationBar: SaveBar(
          label: context.l10n.save,
          onPressed: _save,
          isSaving: _saving,
        ),
      ),
    );
  }
}
