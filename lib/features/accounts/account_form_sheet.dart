import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../services/currency_service.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/account_icon_tile.dart';
import '../main/money_controller.dart';

Future<void> showAccountForm(
  BuildContext context, {
  Account? account,
  String? suggestedName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        AccountFormSheet(account: account, suggestedName: suggestedName),
  );
}

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({super.key, this.account, this.suggestedName});
  final Account? account;

  /// Pre-filled (and selected, so typing replaces it) name for a new account.
  final String? suggestedName;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  static const _types = ['cash', 'bank', 'ewallet', 'savings', 'other'];

  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _type;
  bool _saving = false;
  bool _balanceEdited = false;
  // When editing, the balance field shows the wallet's *current* balance and
  // any change is recorded in History as a balance adjustment.
  int _currentBalance = 0;
  CurrencyService get _currency => Get.find<CurrencyService>();
  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    final initialName = account?.name ?? widget.suggestedName ?? '';
    _nameController = TextEditingController(text: initialName)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: initialName.length,
      );
    if (account != null) {
      _currentBalance =
          Get.find<MoneyController>().accountById(account.id)?.balance ??
          account.initialBalance;
    }
    _balanceController = TextEditingController(
      text: account == null || _currentBalance < 0
          ? ''
          : _currency.formatInputDigits(_currentBalance.toString()),
    );
    _type = account?.type ?? 'cash';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  // The stored icon name is kept for data compatibility; the UI draws account
  // icons from the type (see accountTypeIcon).
  String get _icon => switch (_type) {
    'bank' => 'account_balance',
    'ewallet' => 'smartphone',
    'savings' => 'savings',
    _ => 'account_balance_wallet',
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repository = Get.find<MoneyRepository>();
      final account = widget.account;
      var message = account == null ? 'Akun ditambahkan.' : 'Akun diperbarui.';
      if (account == null) {
        await repository.saveAccount(
          name: _nameController.text,
          type: _type,
          initialBalance: _currency.parseInput(_balanceController.text),
          icon: _icon,
        );
      } else {
        // The opening balance is never edited: a changed balance becomes a
        // visible "Penyesuaian saldo" transaction instead.
        await repository.saveAccount(
          id: account.id,
          name: _nameController.text,
          type: _type,
          initialBalance: account.initialBalance,
          icon: _icon,
        );
        final newBalance = _currency.parseInput(_balanceController.text);
        if (_balanceEdited && newBalance != _currentBalance) {
          final delta = await repository.adjustBalance(
            accountId: account.id,
            newBalance: newBalance,
            note:
                '${_currency.format(_currentBalance)} → '
                '${_currency.format(newBalance)}',
          );
          if (delta != 0) {
            message =
                'Saldo ${delta > 0 ? 'bertambah' : 'berkurang'} '
                '${_currency.format(delta.abs())}, dicatat di riwayat.';
          }
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
      Get.snackbar('Berhasil', message, snackPosition: SnackPosition.BOTTOM);
    } on MoneyValidationException catch (error) {
      Get.snackbar('Tidak dapat menyimpan', error.message);
    } catch (_) {
      Get.snackbar('Terjadi kesalahan', 'Akun tidak dapat disimpan.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.account == null ? 'Tambah Akun' : 'Edit Akun',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Contoh: Bank Jago',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Jenis', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final type in _types)
                    ChoiceChip(
                      key: Key('account-type-$type'),
                      avatar: Icon(
                        accountTypeIcon(type),
                        size: 18,
                        color: accountTypeColor(context, type),
                      ),
                      label: Text(accountTypeLabel(type)),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('account-balance-input'),
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter(_currency)],
                onChanged: (_) => _balanceEdited = true,
                decoration: InputDecoration(
                  labelText: _editing ? 'Saldo saat ini' : 'Saldo awal',
                  helperText: _editing
                      ? 'Selisihnya akan dicatat di riwayat.'
                      : 'Opsional. Saldo saat mulai memakai FerikMoney.',
                  prefixText: '${_currency.current.symbol} ',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
