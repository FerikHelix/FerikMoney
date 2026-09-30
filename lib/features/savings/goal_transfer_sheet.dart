import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/money_repository.dart';
import '../../repositories/savings_repository.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../main/money_controller.dart';
import 'savings_controller.dart';

/// Details of a savings-goal deposit/withdrawal, with a way to remove it.
Future<void> showGoalTransferDetail(
  BuildContext context,
  SavingsGoalTransfer transfer,
) {
  return showAppSheet<void>(
    context,
    (sheetContext) => _GoalTransferDetail(transfer: transfer),
  );
}

class _GoalTransferDetail extends StatelessWidget {
  const _GoalTransferDetail({required this.transfer});

  final SavingsGoalTransfer transfer;

  Future<void> _delete(BuildContext context) async {
    final repository = Get.find<SavingsRepository>();
    try {
      await repository.deleteTransfer(transfer.id);
      if (context.mounted) Navigator.pop(context);
      showFeedback(
        'Transfer dihapus',
        'Saldo dompet dan target telah diperbarui.',
        duration: const Duration(seconds: 5),
        actionLabel: 'UNDO',
        onAction: () async {
          await repository.restoreTransfer(transfer);
          Get.closeCurrentSnackbar();
          showFeedback('Dipulihkan', 'Transfer dikembalikan.');
        },
      );
    } on MoneyValidationException catch (error) {
      showFeedback('Tidak dapat menghapus', error.message);
    } catch (_) {
      showFeedback('Terjadi kesalahan', 'Transfer tidak dapat dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = Get.find<MoneyController>();
    final goal = Get.find<SavingsController>().goalById(transfer.goalId);
    final wallet = money.accountById(transfer.accountId)?.account.name ?? '-';
    final deposit = transfer.type == GoalTransferType.deposit.name;
    final color = context.ferikColors.transfer;
    return AppSheet(
      title: 'Detail Tabungan',
      content: [
        FerikCard(
          color: color.withValues(alpha: 0.1),
          child: Column(
            children: [
              Icon(
                deposit ? Icons.savings_outlined : Icons.wallet_outlined,
                color: color,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                deposit ? 'Setor ke target' : 'Tarik dari target',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              MoneyText(
                amount: transfer.amount,
                tone: MoneyTone.transfer,
                scaleDown: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FerikCard(
          child: Column(
            children: [
              DetailRow(label: 'Target', value: goal?.goal.name ?? '-'),
              DetailRow(label: 'Akun', value: wallet),
              DetailRow(
                label: 'Tanggal',
                value: DateFormat(
                  'd MMMM yyyy, HH:mm',
                  'id_ID',
                ).format(transfer.transferDate),
              ),
              if (transfer.note?.isNotEmpty == true)
                DetailRow(label: 'Catatan', value: transfer.note!),
            ],
          ),
        ),
      ],
      footer: FilledButton.tonalIcon(
        onPressed: () => _delete(context),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Hapus Transfer'),
      ),
    );
  }
}
