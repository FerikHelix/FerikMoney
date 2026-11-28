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

enum TransactionFormType { expense, income, transfer }

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    required this.type,
    this.transactionId,
    this.subscriptionId,
    this.prefillAmount,
    this.prefillWalletId,
    this.prefillCategoryId,
    super.key,
  });

  final TransactionFormType type;
  final int? transactionId;
  final int? subscriptionId;
  final int? prefillAmount;
  final int? prefillWalletId;
  final int? prefillCategoryId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _amount = TextEditingController();
  final _fee = TextEditingController();
  final _note = TextEditingController();
  final _amountFocus = FocusNode();

  String _date = todayKey();
  int? _walletId;
  int? _categoryId;
  int? _sourceId;
  int? _destinationId;
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  bool _ready = false;
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  String? _amountError;
  String? _walletError;
  String? _categoryError;
  String? _walletPairError;

  bool get _isTransfer => widget.type == TransactionFormType.transfer;
  bool get _isEditing => widget.transactionId != null;
  CategoryKind get _kind => widget.type == TransactionFormType.income
      ? CategoryKind.income
      : CategoryKind.expense;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_markDirty);
    _fee.addListener(_markDirty);
    _note.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _fee.dispose();
    _note.dispose();
    _amountFocus.dispose();
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
    final categories = await database.transactionDao.listCategories(
      kind: _kind,
    );
    final loadedWallets = [...wallets];
    final loadedCategories = [...categories];

    if (_isEditing) {
      if (_isTransfer) {
        final transfer = await database.transactionDao.transferById(
          widget.transactionId!,
        );
        if (transfer != null) {
          _sourceId = transfer.sourceWalletId;
          _destinationId = transfer.destinationWalletId;
          _amount.text = formatGrouped(transfer.amount);
          _fee.text = transfer.fee == 0 ? '' : formatGrouped(transfer.fee);
          _note.text = transfer.note;
          _date = transfer.date;
          await _ensureWallets(database, loadedWallets, [
            transfer.sourceWalletId,
            transfer.destinationWalletId,
          ]);
        }
      } else {
        final entry = await database.transactionDao.transactionById(
          widget.transactionId!,
        );
        if (entry != null) {
          _walletId = entry.walletId;
          _categoryId = entry.categoryId;
          _amount.text = formatGrouped(entry.amount);
          _note.text = entry.note;
          _date = entry.date;
          if (!loadedCategories.any((c) => c.id == entry.categoryId)) {
            final category = await database.transactionDao.categoryById(
              entry.categoryId,
            );
            if (category != null) {
              loadedCategories.add(category);
            }
          }
          if (!loadedWallets.any((w) => w.id == entry.walletId)) {
            final wallet = await database.walletDao.byId(entry.walletId);
            if (wallet != null) {
              loadedWallets.add(wallet);
            }
          }
        }
      }
    } else if (_isTransfer) {
      _sourceId = null;
      _destinationId = null;
    } else {
      final last = await database.transactionDao.lastTransactionOfKind(_kind);
      final activeWalletIds = loadedWallets.map((w) => w.id).toSet();
      final activeCategoryIds = loadedCategories.map((c) => c.id).toSet();
      _walletId =
          widget.prefillWalletId ??
          (last != null && activeWalletIds.contains(last.walletId)
              ? last.walletId
              : loadedWallets.isEmpty
              ? null
              : loadedWallets.first.id);
      _categoryId =
          widget.prefillCategoryId ??
          (last != null && activeCategoryIds.contains(last.categoryId)
              ? last.categoryId
              : loadedCategories.isEmpty
              ? null
              : loadedCategories.first.id);
      if (widget.prefillAmount != null) {
        _amount.text = formatGrouped(widget.prefillAmount!);
      }
      if (_walletId != null && !activeWalletIds.contains(_walletId)) {
        final wallet = await database.walletDao.byId(_walletId!);
        if (wallet != null) {
          loadedWallets.add(wallet);
        }
      }
      if (_categoryId != null && !activeCategoryIds.contains(_categoryId)) {
        final category = await database.transactionDao.categoryById(
          _categoryId!,
        );
        if (category != null) {
          loadedCategories.add(category);
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _wallets = loadedWallets;
      _categories = loadedCategories;
      _ready = true;
      _dirty = false;
    });
    if (!_isEditing) {
      _amountFocus.requestFocus();
    }
  }

  Future<void> _ensureWallets(
    AppDatabase database,
    List<Wallet> target,
    List<int> ids,
  ) async {
    for (final id in ids) {
      if (!target.any((w) => w.id == id)) {
        final wallet = await database.walletDao.byId(id);
        if (wallet != null) {
          target.add(wallet);
        }
      }
    }
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
    if (amount <= 0) {
      _amountError = context.l10n.amountRequired;
      valid = false;
    } else if (amount > maxTransactionAmount) {
      _amountError = context.l10n.amountTooLarge;
      valid = false;
    } else {
      _amountError = null;
    }

    if (_isTransfer) {
      if (_sourceId == null) {
        _walletError = context.l10n.requiredField;
        valid = false;
      } else {
        _walletError = null;
      }
      if (_destinationId == null) {
        _categoryError = context.l10n.requiredField;
        valid = false;
      } else {
        _categoryError = null;
      }
      if (_sourceId != null && _sourceId == _destinationId) {
        _walletPairError = context.l10n.sameWallet;
        valid = false;
      } else {
        _walletPairError = null;
      }
    } else {
      if (_walletId == null) {
        _walletError = context.l10n.requiredField;
        valid = false;
      } else {
        _walletError = null;
      }
      if (_categoryId == null) {
        _categoryError = context.l10n.requiredField;
        valid = false;
      } else {
        _categoryError = null;
      }
    }
    setState(() {});
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) {
      return;
    }
    final database = ref.read(databaseProvider);
    final amount = parseRupiah(_amount.text)!;
    final fee = _isTransfer ? (parseRupiah(_fee.text) ?? 0) : 0;

    if (_isTransfer) {
      if (fee > maxTransactionAmount) {
        setState(() => _amountError = context.l10n.amountTooLarge);
        return;
      }
      final balance = await database.walletDao.currentBalance(_sourceId!);
      if (amount + fee > balance) {
        if (!mounted) {
          return;
        }
        final confirmed = await confirmAction(
          context,
          title: context.l10n.negativeBalance,
          body: context.l10n.negativeBalanceConfirm,
          confirmLabel: context.l10n.continueLabel,
        );
        if (!confirmed) {
          return;
        }
      }
    } else if (widget.type == TransactionFormType.expense) {
      final balance = await database.walletDao.currentBalance(_walletId!);
      if (amount > balance) {
        if (!mounted) {
          return;
        }
        final confirmed = await confirmAction(
          context,
          title: context.l10n.negativeBalance,
          body: context.l10n.negativeBalanceConfirm,
          confirmLabel: context.l10n.continueLabel,
        );
        if (!confirmed) {
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        if (_isTransfer) {
          await database.transactionDao.updateTransfer(
            id: widget.transactionId!,
            sourceWalletId: _sourceId!,
            destinationWalletId: _destinationId!,
            amount: amount,
            fee: fee,
            date: _date,
            note: _note.text,
          );
        } else {
          await database.transactionDao.updateTransaction(
            id: widget.transactionId!,
            kind: _kind,
            amount: amount,
            walletId: _walletId!,
            categoryId: _categoryId!,
            date: _date,
            note: _note.text,
          );
        }
      } else if (widget.subscriptionId != null) {
        await database.transaction(() async {
          await database.transactionDao.createTransaction(
            kind: CategoryKind.expense,
            amount: amount,
            walletId: _walletId!,
            categoryId: _categoryId!,
            date: _date,
            note: _note.text,
          );
          await database.subscriptionDao.completeCycle(widget.subscriptionId!);
        });
      } else if (_isTransfer) {
        await database.transactionDao.createTransfer(
          sourceWalletId: _sourceId!,
          destinationWalletId: _destinationId!,
          amount: amount,
          fee: fee,
          date: _date,
          note: _note.text,
        );
      } else {
        await database.transactionDao.createTransaction(
          kind: _kind,
          amount: amount,
          walletId: _walletId!,
          categoryId: _categoryId!,
          date: _date,
          note: _note.text,
        );
      }
      if (!mounted) {
        return;
      }
      _saved = true;
      final message = switch (widget.type) {
        TransactionFormType.expense => context.l10n.expenseSaved,
        TransactionFormType.income => context.l10n.incomeSaved,
        TransactionFormType.transfer => context.l10n.transferSaved,
      };
      showSavedMessage(context, message);
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

  String get _title => switch (widget.type) {
    TransactionFormType.expense =>
      _isEditing ? context.l10n.edit : context.l10n.newExpense,
    TransactionFormType.income =>
      _isEditing ? context.l10n.edit : context.l10n.newIncome,
    TransactionFormType.transfer =>
      _isEditing ? context.l10n.edit : context.l10n.newTransfer,
  };

  String get _saveLabel => switch (widget.type) {
    TransactionFormType.expense => context.l10n.saveExpense,
    TransactionFormType.income => context.l10n.saveIncome,
    TransactionFormType.transfer => context.l10n.saveTransfer,
  };

  @override
  Widget build(BuildContext context) {
    return DirtyPopScope(
      dirty: _dirty && !_saved,
      child: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RupiahField(
                    controller: _amount,
                    label: context.l10n.amount,
                    autofocus: !_isEditing,
                    focusNode: _amountFocus,
                    errorText: _amountError,
                  ),
                  const SizedBox(height: 16),
                  if (_isTransfer) ...[
                    WalletDropdown(
                      wallets: _wallets,
                      value: _sourceId,
                      label: context.l10n.sourceWallet,
                      errorText: _walletError,
                      onChanged: (value) => setState(() => _sourceId = value),
                    ),
                    const SizedBox(height: 16),
                    WalletDropdown(
                      wallets: _wallets,
                      value: _destinationId,
                      label: context.l10n.destinationWallet,
                      errorText: _walletPairError ?? _categoryError,
                      onChanged: (value) =>
                          setState(() => _destinationId = value),
                    ),
                    const SizedBox(height: 16),
                    RupiahField(
                      controller: _fee,
                      label: context.l10n.transferFee,
                    ),
                  ] else ...[
                    WalletDropdown(
                      wallets: _wallets,
                      value: _walletId,
                      label: context.l10n.wallet,
                      errorText: _walletError,
                      onChanged: (value) => setState(() => _walletId = value),
                    ),
                    const SizedBox(height: 16),
                    CategoryDropdown(
                      categories: _categories,
                      value: _categoryId,
                      label: context.l10n.category,
                      errorText: _categoryError,
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DateField(
                    label: context.l10n.date,
                    value: _date,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  NoteField(controller: _note),
                  const SizedBox(height: 96),
                ],
              ),
        bottomNavigationBar: SaveBar(
          label: _saveLabel,
          onPressed: _save,
          isSaving: _saving,
        ),
      ),
    );
  }
}
