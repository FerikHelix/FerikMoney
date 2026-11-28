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

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({required this.direction, super.key});

  final String direction;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _counterparty = TextEditingController();
  final _principal = TextEditingController();
  final _note = TextEditingController();
  String _startDate = todayKey();
  String _dueDate = todayKey();
  bool _hasDueDate = false;
  bool _commit = false;
  int? _walletId;
  int? _commitCategoryId;
  List<Wallet> _wallets = const [];
  List<Category> _incomeCategories = const [];
  List<Category> _expenseCategories = const [];
  bool _ready = false;
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  String? _nameError;
  String? _amountError;
  String? _walletError;
  String? _categoryError;

  bool get _isUtang => widget.direction == 'utang';
  CategoryKind get _commitKind =>
      _isUtang ? CategoryKind.income : CategoryKind.expense;
  List<Category> get _commitCategories =>
      _isUtang ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _counterparty.addListener(_markDirty);
    _principal.addListener(_markDirty);
    _note.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    _counterparty.dispose();
    _principal.dispose();
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
    final wallets = await database.walletDao.active();
    final income = await database.transactionDao.listCategories(
      kind: CategoryKind.income,
    );
    final expense = await database.transactionDao.listCategories(
      kind: CategoryKind.expense,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _wallets = wallets;
      _incomeCategories = income;
      _expenseCategories = expense;
      _walletId = wallets.isEmpty ? null : wallets.first.id;
      _ready = true;
      _dirty = false;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDateKey(_startDate),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = dateKey(picked);
        if (_dueDate.compareTo(_startDate) < 0) {
          _dueDate = _startDate;
        }
      });
      _markDirty();
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDateKey(_dueDate),
      firstDate: parseDateKey(_startDate),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = dateKey(picked));
      _markDirty();
    }
  }

  bool _validate() {
    var valid = true;
    if (_counterparty.text.trim().isEmpty) {
      _nameError = context.l10n.counterpartyRequired;
      valid = false;
    } else {
      _nameError = null;
    }
    final amount = parseRupiah(_principal.text) ?? 0;
    if (amount <= 0) {
      _amountError = context.l10n.amountRequired;
      valid = false;
    } else if (amount > maxTransactionAmount) {
      _amountError = context.l10n.amountTooLarge;
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
    if (_commit && _commitCategoryId == null) {
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
          .createEntry(
            direction: widget.direction,
            counterparty: _counterparty.text,
            principal: parseRupiah(_principal.text)!,
            startDate: _startDate,
            dueDate: _hasDueDate ? _dueDate : null,
            note: _note.text,
            commitWalletId: _commit ? _walletId : null,
            commitCategoryId: _commit ? _commitCategoryId : null,
          );
      if (!mounted) {
        return;
      }
      _saved = true;
      showSavedMessage(
        context,
        _isUtang ? context.l10n.debtSaved : context.l10n.receivableSaved,
      );
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
    return DirtyPopScope(
      dirty: _dirty && !_saved,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isUtang ? context.l10n.newDebt : context.l10n.newReceivable,
          ),
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _counterparty,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.counterparty,
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RupiahField(
                    controller: _principal,
                    label: context.l10n.principal,
                    errorText: _amountError,
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: context.l10n.startDate,
                    value: _startDate,
                    onTap: _pickStartDate,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.dueDate),
                    value: _hasDueDate,
                    onChanged: (value) {
                      setState(() => _hasDueDate = value);
                      _markDirty();
                    },
                  ),
                  if (_hasDueDate)
                    DateField(
                      label: context.l10n.dueDate,
                      value: _dueDate,
                      onTap: _pickDueDate,
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
                      setState(() {
                        _commit = value;
                        if (value &&
                            _commitCategoryId == null &&
                            _commitCategories.isNotEmpty) {
                          _commitCategoryId = _commitCategories.first.id;
                        }
                      });
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
                      categories: _commitCategories,
                      value: _commitCategoryId,
                      label: context.l10n.category,
                      errorText: _categoryError,
                      onChanged: (value) =>
                          setState(() => _commitCategoryId = value),
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
