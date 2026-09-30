import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/money_repository.dart';
import '../../repositories/savings_repository.dart';
import '../../services/currency_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../main/money_controller.dart';
import 'savings_controller.dart';

class SavingsGoalsView extends GetView<SavingsController> {
  const SavingsGoalsView({super.key});

  Future<void> _showGoalForm(BuildContext context, {SavingsGoal? goal}) async {
    final repository = Get.find<SavingsRepository>();
    final currency = Get.find<CurrencyService>();
    final name = TextEditingController(text: goal?.name ?? '');
    final amount = TextEditingController(
      text: goal == null
          ? ''
          : currency.formatInputDigits(goal.targetAmount.toString()),
    );
    var targetDate = goal?.targetDate;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                goal == null ? 'Tambah Target' : 'Edit Target',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama target'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter(currency)],
                decoration: InputDecoration(
                  labelText: 'Jumlah target',
                  prefixText: '${currency.current.symbol} ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: targetDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 36500)),
                  );
                  if (selected != null) setState(() => targetDate = selected);
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  targetDate == null
                      ? 'Tanpa target tanggal'
                      : DateFormat('d MMMM yyyy', 'id_ID').format(targetDate!),
                ),
              ),
              if (targetDate != null)
                TextButton(
                  onPressed: () => setState(() => targetDate = null),
                  child: const Text('Hapus target tanggal'),
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () async {
                  try {
                    await repository.saveGoal(
                      id: goal?.id,
                      name: name.text,
                      targetAmount: currency.parseInput(amount.text),
                      targetDate: targetDate,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } on MoneyValidationException catch (error) {
                    Get.snackbar('Target tidak dapat disimpan', error.message);
                  }
                },
                child: const Text('Simpan Target'),
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    amount.dispose();
  }

  Future<void> _showTransfer(
    BuildContext context,
    SavingsGoalWithProgress item,
  ) async {
    final money = Get.find<MoneyController>();
    final repository = Get.find<SavingsRepository>();
    final currency = Get.find<CurrencyService>();
    var type = GoalTransferType.deposit;
    var accountId = money.activeAccounts.isEmpty
        ? null
        : money.activeAccounts.first.account.id;
    final amount = TextEditingController();
    final note = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.goal.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<GoalTransferType>(
                segments: const [
                  ButtonSegment(
                    value: GoalTransferType.deposit,
                    icon: Icon(Icons.south_west_rounded),
                    label: Text('Setor'),
                  ),
                  ButtonSegment(
                    value: GoalTransferType.withdrawal,
                    icon: Icon(Icons.north_east_rounded),
                    label: Text('Tarik'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) =>
                    setState(() => type = value.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: accountId,
                decoration: const InputDecoration(
                  labelText: 'Wallet',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: money.activeAccounts
                    .map(
                      (value) => DropdownMenuItem(
                        value: value.account.id,
                        child: Text(value.account.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => accountId = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter(currency)],
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  prefixText: '${currency.current.symbol} ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: accountId == null
                    ? null
                    : () async {
                        try {
                          await repository.transfer(
                            goalId: item.goal.id,
                            accountId: accountId!,
                            type: type,
                            amount: currency.parseInput(amount.text),
                            note: note.text,
                            date: DateTime.now(),
                          );
                          if (context.mounted) Navigator.pop(context);
                        } on MoneyValidationException catch (error) {
                          Get.snackbar('Transfer gagal', error.message);
                        }
                      },
                child: Text(
                  type == GoalTransferType.deposit
                      ? 'Transfer ke Target'
                      : 'Tarik ke Wallet',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Target Tabungan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Obx(() {
        final goals = controller.goals
            .where((item) => !item.goal.isArchived)
            .toList();
        if (goals.isEmpty) {
          return EmptyState(
            icon: Icons.flag_outlined,
            title: 'Belum ada target tabungan',
            message:
                'Buat target, lalu pindahkan dana dari wallet sedikit demi sedikit.',
            action: FilledButton.icon(
              onPressed: () => _showGoalForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Target'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            100,
          ),
          itemCount: goals.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = goals[index];
            final ratio = item.goal.targetAmount == 0
                ? 0.0
                : item.saved / item.goal.targetAmount;
            return FerikCard(
              onTap: () => _showTransfer(context, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.goal.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showGoalForm(context, goal: item.goal);
                          } else {
                            Get.find<SavingsRepository>().archiveGoal(
                              item.goal.id,
                              archived: true,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'archive',
                            child: Text('Arsipkan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: MoneyText(amount: item.saved)),
                      Text(' / ', style: Theme.of(context).textTheme.bodySmall),
                      MoneyText(
                        amount: item.goal.targetAmount,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(value: ratio.clamp(0.0, 1.0)),
                  if (item.goal.targetDate != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Target ${DateFormat('d MMM yyyy', 'id_ID').format(item.goal.targetDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
