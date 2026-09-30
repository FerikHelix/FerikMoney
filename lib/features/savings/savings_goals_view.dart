import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/money_repository.dart';
import '../../repositories/savings_repository.dart';
import '../../services/app_preferences_service.dart';
import '../../services/currency_service.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/section_header.dart';
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
    final message = await showAppSheet<String>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setState) => AppSheet(
          title: goal == null ? 'Tambah Target' : 'Edit Target',
          content: [
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
          ],
          footer: AsyncFilledButton(
            label: 'Simpan Target',
            icon: Icons.check_rounded,
            onPressed: () async {
              try {
                await repository.saveGoal(
                  id: goal?.id,
                  name: name.text,
                  targetAmount: currency.parseInput(amount.text),
                  targetDate: targetDate,
                );
                if (sheetContext.mounted) {
                  Navigator.pop(
                    sheetContext,
                    goal == null ? 'Target ditambahkan.' : 'Target diperbarui.',
                  );
                }
              } on MoneyValidationException catch (error) {
                showFeedback('Target tidak dapat disimpan', error.message);
              } catch (_) {
                showFeedback(
                  'Terjadi kesalahan',
                  'Target tidak dapat disimpan.',
                );
              }
            },
          ),
        ),
      ),
    );
    disposeAfterSheet([name, amount]);
    if (message != null) showFeedback('Berhasil', message);
  }

  String? _defaultWalletId(MoneyController money) {
    final preferences = Get.find<AppPreferencesService>();
    final active = money.activeAccounts;
    for (final id in [
      preferences.defaultAccountId.value,
      preferences.lastAccountId.value,
    ]) {
      if (id != null && active.any((item) => item.account.id == id)) return id;
    }
    return active.isEmpty ? null : active.first.account.id;
  }

  Future<void> _showTransfer(
    BuildContext context,
    SavingsGoalWithProgress item,
  ) async {
    final money = Get.find<MoneyController>();
    final repository = Get.find<SavingsRepository>();
    final currency = Get.find<CurrencyService>();
    var type = GoalTransferType.deposit;
    var accountId = _defaultWalletId(money);
    final amount = TextEditingController();
    final note = TextEditingController();
    final message = await showAppSheet<String>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setState) => AppSheet(
          title: item.goal.name,
          content: [
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
              onSelectionChanged: (value) => setState(() => type = value.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: accountId,
              decoration: const InputDecoration(
                labelText: 'Akun',
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
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
          footer: AsyncFilledButton(
            label: type == GoalTransferType.deposit
                ? 'Transfer ke Target'
                : 'Tarik ke Akun',
            icon: Icons.check_rounded,
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
                      if (sheetContext.mounted) {
                        Navigator.pop(
                          sheetContext,
                          type == GoalTransferType.deposit
                              ? 'Dana dipindahkan ke target.'
                              : 'Dana ditarik ke akun.',
                        );
                      }
                    } on MoneyValidationException catch (error) {
                      showFeedback('Transfer gagal', error.message);
                    } catch (_) {
                      showFeedback(
                        'Terjadi kesalahan',
                        'Transfer tidak dapat diproses.',
                      );
                    }
                  },
          ),
        ),
      ),
    );
    disposeAfterSheet([amount, note]);
    if (message != null) showFeedback('Berhasil', message);
  }

  Future<void> _archive(SavingsGoalWithProgress item) async {
    final repository = Get.find<SavingsRepository>();
    await repository.archiveGoal(item.goal.id, archived: true);
    showFeedback(
      'Target diarsipkan',
      '${item.goal.name} dipindah ke Diarsipkan.',
      duration: const Duration(seconds: 5),
      actionLabel: 'UNDO',
      onAction: () async {
        await repository.archiveGoal(item.goal.id, archived: false);
        Get.closeCurrentSnackbar();
      },
    );
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
        final archived = controller.goals
            .where((item) => item.goal.isArchived)
            .toList();
        if (goals.isEmpty && archived.isEmpty) {
          return EmptyState(
            icon: Icons.flag_outlined,
            title: 'Belum ada target tabungan',
            message:
                'Buat target, lalu pindahkan dana dari akun sedikit demi sedikit.',
            action: FilledButton.icon(
              onPressed: () => _showGoalForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Target'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            100,
          ),
          children: [
            for (final item in goals) ...[
              _GoalCard(
                item: item,
                onTap: () => _showTransfer(context, item),
                onEdit: () => _showGoalForm(context, goal: item.goal),
                onArchive: () => _archive(item),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Diarsipkan'),
              const SizedBox(height: AppSpacing.xs),
              FerikCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < archived.length; index++) ...[
                      ListTile(
                        title: Text(archived[index].goal.name),
                        subtitle: MoneyText(
                          amount: archived[index].saved,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: TextButton(
                          onPressed: () =>
                              Get.find<SavingsRepository>().archiveGoal(
                                archived[index].goal.id,
                                archived: false,
                              ),
                          child: const Text('Pulihkan'),
                        ),
                      ),
                      if (index < archived.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
  });

  final SavingsGoalWithProgress item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final ratio = item.goal.targetAmount == 0
        ? 0.0
        : item.saved / item.goal.targetAmount;
    return FerikCard(
      onTap: onTap,
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
              // Tapping the card deposits/withdraws; the menu holds only the
              // rarer actions.
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onArchive(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
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
  }
}
