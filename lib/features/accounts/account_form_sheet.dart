import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../services/currency_service.dart';

Future<void> showAccountForm(BuildContext context, {Account? account}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => AccountFormSheet(account: account),
  );
}

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({super.key, this.account});
  final Account? account;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _type;
  bool _saving = false;
  CurrencyService get _currency => Get.find<CurrencyService>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account == null
          ? ''
          : _currency.formatInputDigits(
              widget.account!.initialBalance.toString(),
            ),
    );
    _type = widget.account?.type ?? 'cash';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String get _icon => switch (_type) {
    'bank' => 'account_balance',
    'ewallet' => 'smartphone',
    'savings' => 'savings',
    'other' => 'savings',
    _ => 'account_balance_wallet',
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Get.find<MoneyRepository>().saveAccount(
        id: widget.account?.id,
        name: _nameController.text,
        type: _type,
        initialBalance: _currency.parseInput(_balanceController.text),
        icon: _icon,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Get.snackbar(
        'Berhasil',
        widget.account == null ? 'Akun ditambahkan.' : 'Akun diperbarui.',
        snackPosition: SnackPosition.BOTTOM,
      );
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
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Jenis'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(
                    value: 'ewallet',
                    child: Text('Dompet digital'),
                  ),
                  DropdownMenuItem(value: 'savings', child: Text('Tabungan')),
                  DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter(_currency)],
                decoration: InputDecoration(
                  labelText: 'Saldo Awal',
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
