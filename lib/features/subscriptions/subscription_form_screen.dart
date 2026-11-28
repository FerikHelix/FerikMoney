import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/dates/subscription_due.dart';
import '../../core/db/database.dart';
import '../../core/models/models.dart';
import '../../core/money/rupiah.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/l10n.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({this.subscriptionId, super.key});

  final int? subscriptionId;

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _dueDay = TextEditingController(text: '1');
  final _leadDays = TextEditingController(text: '3');
  final _note = TextEditingController();

  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  int? _walletId;
  int? _categoryId;
  SubscriptionCycle _cycle = SubscriptionCycle.monthly;
  int _dueMonth = DateTime.now().month;
  bool _active = true;
  bool _ready = false;
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  String? _nameError;
  String? _amountError;
  String? _dayError;
  String? _leadError;
  String? _walletError;
  String? _categoryError;

  bool get _isEditing => widget.subscriptionId != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(_markDirty);
    _amount.addListener(_markDirty);
    _dueDay.addListener(_markDirty);
    _leadDays.addListener(_markDirty);
    _note.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _dueDay.dispose();
    _leadDays.dispose();
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
    final categories = await database.transactionDao.listCategories(
      kind: CategoryKind.expense,
    );
    if (_isEditing) {
      final entry = await database.subscriptionDao.byId(widget.subscriptionId!);
      if (entry != null) {
        _name.text = entry.name;
        _amount.text = formatGrouped(entry.amount);
        _dueDay.text = entry.anchorDay.toString();
        _leadDays.text = entry.leadDays.toString();
        _note.text = entry.note;
        _walletId = entry.walletId;
        _categoryId = entry.categoryId;
        _cycle = SubscriptionCycle.parse(entry.cycle);
        _dueMonth = entry.anchorMonth ?? _dueMonth;
        _active = entry.active;
        if (!wallets.any((w) => w.id == entry.walletId)) {
          final wallet = await database.walletDao.byId(entry.walletId);
          if (wallet != null) {
            wallets.add(wallet);
          }
        }
        if (!categories.any((c) => c.id == entry.categoryId)) {
          final category = await database.transactionDao.categoryById(
            entry.categoryId,
          );
          if (category != null) {
            categories.add(category);
          }
        }
      }
    } else {
      _walletId = wallets.isEmpty ? null : wallets.first.id;
      _categoryId = categories.isEmpty ? null : categories.first.id;
      _dueDay.text = DateTime.now().day.toString();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _wallets = wallets;
      _categories = categories;
      _ready = true;
      _dirty = false;
    });
  }

  bool _validate() {
    var valid = true;
    if (_name.text.trim().isEmpty) {
      _nameError = context.l10n.subscriptionNameRequired;
      valid = false;
    } else {
      _nameError = null;
    }
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
    final day = int.tryParse(_dueDay.text) ?? 0;
    if (day < 1 || day > 31) {
      _dayError = context.l10n.dueDayInvalid;
      valid = false;
    } else {
      _dayError = null;
    }
    final lead = int.tryParse(_leadDays.text);
    if (lead == null || lead < 0 || lead > 30) {
      _leadError = context.l10n.leadDaysInvalid;
      valid = false;
    } else {
      _leadError = null;
    }
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
    setState(() {});
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) {
      return;
    }
    setState(() => _saving = true);
    final database = ref.read(databaseProvider);
    try {
      if (_isEditing) {
        await database.subscriptionDao.updateSubscription(
          id: widget.subscriptionId!,
          name: _name.text,
          amount: parseRupiah(_amount.text)!,
          walletId: _walletId!,
          categoryId: _categoryId!,
          cycle: _cycle,
          anchorDay: int.parse(_dueDay.text),
          anchorMonth: _cycle == SubscriptionCycle.yearly ? _dueMonth : null,
          leadDays: int.tryParse(_leadDays.text) ?? 3,
          active: _active,
          note: _note.text,
        );
      } else {
        await database.subscriptionDao.createSubscription(
          name: _name.text,
          amount: parseRupiah(_amount.text)!,
          walletId: _walletId!,
          categoryId: _categoryId!,
          cycle: _cycle,
          anchorDay: int.parse(_dueDay.text),
          anchorMonth: _cycle == SubscriptionCycle.yearly ? _dueMonth : null,
          leadDays: int.tryParse(_leadDays.text) ?? 3,
          note: _note.text,
        );
      }
      if (!mounted) {
        return;
      }
      _saved = true;
      showSavedMessage(context, context.l10n.subscriptionSaved);
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

  @override
  Widget build(BuildContext context) {
    return DirtyPopScope(
      dirty: _dirty && !_saved,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? context.l10n.editSubscription
                : context.l10n.newSubscription,
          ),
        ),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _name,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.subscriptionName,
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RupiahField(
                    controller: _amount,
                    label: context.l10n.amount,
                    errorText: _amountError,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.cycle,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<SubscriptionCycle>(
                    segments: [
                      ButtonSegment(
                        value: SubscriptionCycle.monthly,
                        label: Text(context.l10n.monthly),
                      ),
                      ButtonSegment(
                        value: SubscriptionCycle.yearly,
                        label: Text(context.l10n.yearly),
                      ),
                    ],
                    selected: {_cycle},
                    onSelectionChanged: (value) {
                      setState(() => _cycle = value.first);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dueDay,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.l10n.dueDay,
                      errorText: _dayError,
                    ),
                  ),
                  if (_cycle == SubscriptionCycle.yearly) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey('due-month-$_dueMonth'),
                      initialValue: _dueMonth,
                      decoration: InputDecoration(
                        labelText: context.l10n.dueMonth,
                      ),
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text(monthName(month)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _dueMonth = value);
                          _markDirty();
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _leadDays,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.l10n.leadDays,
                      errorText: _leadError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  NoteField(controller: _note),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.activeLabel),
                      value: _active,
                      onChanged: (value) {
                        setState(() => _active = value);
                        _markDirty();
                      },
                    ),
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
