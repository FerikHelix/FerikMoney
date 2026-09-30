import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../services/privacy_service.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../main/money_controller.dart';
import 'transaction_form_sheet.dart';

Future<void> showTransactionDetail(
  BuildContext context,
  MoneyTransaction transaction,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _TransactionDetail(transaction: transaction),
  );
}

class _TransactionDetail extends StatelessWidget {
  const _TransactionDetail({required this.transaction});

  final MoneyTransaction transaction;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Saldo akun akan dihitung ulang secara otomatis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final money = Get.find<MoneyController>();
      final repository = Get.find<MoneyRepository>();
      final tagNames = money
          .tagsForTransaction(transaction.id)
          .map((item) => item.name)
          .toList();
      await repository.deleteTransaction(transaction.id);
      if (context.mounted) Navigator.pop(context);
      Get.snackbar(
        'Transaksi dihapus',
        'Saldo telah diperbarui.',
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () async {
            await repository.restoreTransaction(transaction, tags: tagNames);
            Get.closeCurrentSnackbar();
            Get.snackbar('Dipulihkan', 'Transaksi dikembalikan.');
          },
          child: const Text('UNDO'),
        ),
      );
    } catch (_) {
      Get.snackbar('Terjadi kesalahan', 'Transaksi tidak dapat dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = Get.find<MoneyController>();
    final privacy = Get.find<PrivacyService>();
    final account =
        money.accountById(transaction.accountId)?.account.name ?? '-';
    final destination = money
        .accountById(transaction.destinationAccountId)
        ?.account
        .name;
    final category = money.categoryById(transaction.categoryId)?.name;
    final tags = money.tagsForTransaction(transaction.id);
    final typeLabel = switch (transaction.type) {
      'income' => 'Pemasukan',
      'transfer' => 'Transfer',
      _ => 'Pengeluaran',
    };
    final tone = switch (transaction.type) {
      'income' => MoneyTone.income,
      'expense' => MoneyTone.expense,
      _ => MoneyTone.transfer,
    };
    final color = switch (tone) {
      MoneyTone.income => context.ferikColors.income,
      MoneyTone.expense => context.ferikColors.expense,
      MoneyTone.transfer => context.ferikColors.transfer,
      MoneyTone.neutral => context.ferikColors.mainText,
    };
    final icon = switch (transaction.type) {
      'income' => Icons.arrow_upward_rounded,
      'expense' => Icons.arrow_downward_rounded,
      _ => Icons.swap_horiz_rounded,
    };
    return SingleChildScrollView(
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
            'Detail Transaksi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          FerikCard(
            color: color.withValues(alpha: 0.1),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(typeLabel, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Obx(
                  () => MoneyText(
                    amount: transaction.amount,
                    visible: privacy.showMoney.value,
                    tone: tone,
                    showSign: transaction.type != 'transfer',
                    scaleDown: true,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FerikCard(
            child: Column(
              children: [
                _DetailRow(label: 'Akun', value: account),
                if (destination != null)
                  _DetailRow(label: 'Akun tujuan', value: destination),
                if (category != null)
                  _DetailRow(label: 'Kategori', value: category),
                _DetailRow(
                  label: 'Tanggal',
                  value: DateFormat(
                    'd MMMM yyyy, HH:mm',
                    'id_ID',
                  ).format(transaction.transactionDate),
                ),
                if (transaction.note?.isNotEmpty == true)
                  _DetailRow(label: 'Catatan', value: transaction.note!),
                if (tags.isNotEmpty)
                  _DetailRow(
                    label: 'Tags',
                    value: tags.map((item) => '#${item.name}').join('  '),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await showTransactionForm(
                      Get.context!,
                      transaction: transaction,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await showTransactionForm(
                      Get.context!,
                      transaction: transaction,
                      duplicate: true,
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Duplikat'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Transaksi'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
