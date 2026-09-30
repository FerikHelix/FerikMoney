import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/money_repository.dart';
import '../../repositories/recurring_repository.dart';
import '../../services/currency_service.dart';
import '../../widgets/amount_input.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../../widgets/transaction_type_selector.dart';
import '../main/money_controller.dart';
import '../transactions/transaction_form_sheet.dart';
import 'recurring_controller.dart';

class RecurringView extends GetView<RecurringController> {
  const RecurringView({super.key});

  Future<void> _reviewOccurrence(
    BuildContext context,
    RecurringOccurrence occurrence,
    RecurringRule rule,
  ) async {
    final repository = Get.find<RecurringRepository>();
    final tags = await repository.tagsForRule(rule.id);
    if (!context.mounted) return;
    await showTransactionForm(
      context,
      title: 'Review ${rule.name}',
      successMessage: 'Transaksi berulang berhasil dikonfirmasi.',
      initialValue: TransactionFormInitialValue(
        type: rule.type,
        amount: rule.amount,
        accountId: rule.accountId,
        destinationAccountId: rule.destinationAccountId,
        categoryId: rule.categoryId,
        note: rule.note,
        tags: tags,
        date: occurrence.dueAt,
      ),
      onSubmit: (value) => repository.createOccurrence(
        occurrence.id,
        type: value.type,
        amount: value.amount,
        accountId: value.accountId,
        destinationAccountId: value.destinationAccountId,
        categoryId: value.categoryId,
        note: value.note,
        tags: value.tags,
        transactionDate: value.date,
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {RecurringRule? rule}) async {
    final repository = Get.find<RecurringRepository>();
    final money = Get.find<MoneyController>();
    final currency = Get.find<CurrencyService>();
    final name = TextEditingController(text: rule?.name ?? '');
    final amount = TextEditingController(
      text: rule == null
          ? ''
          : currency.formatInputDigits(rule.amount.toString()),
    );
    final note = TextEditingController(text: rule?.note ?? '');
    var type = rule?.type ?? 'expense';
    var accountId =
        rule?.accountId ??
        (money.activeAccounts.isEmpty
            ? null
            : money.activeAccounts.first.account.id);
    var destinationId = rule?.destinationAccountId;
    var categoryId =
        rule?.categoryId ??
        money.activeCategories
            .where((item) => item.type == type)
            .map((item) => item.id)
            .firstOrNull;
    var frequency = rule == null
        ? RecurrenceFrequency.monthly
        : RecurrenceFrequency.values.byName(rule.frequency);
    var startDate = rule?.startDate ?? DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                rule == null
                    ? 'Tambah Transaksi Berulang'
                    : 'Edit Transaksi Berulang',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Contoh: Internet bulanan',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TransactionTypeSelector(
                value: type,
                onChanged: (value) => setState(() {
                  type = value;
                  categoryId = value == 'transfer'
                      ? null
                      : money.activeCategories
                            .where((item) => item.type == value)
                            .map((item) => item.id)
                            .firstOrNull;
                  if (value != 'transfer') destinationId = null;
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
              AmountInput(controller: amount, autofocus: rule == null),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: accountId,
                decoration: InputDecoration(
                  labelText: type == 'transfer' ? 'Dari wallet' : 'Wallet',
                ),
                items: money.activeAccounts
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.account.id,
                        child: Text(item.account.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => accountId = value),
              ),
              if (type == 'transfer') ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: destinationId,
                  decoration: const InputDecoration(labelText: 'Ke wallet'),
                  items: money.activeAccounts
                      .where((item) => item.account.id != accountId)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.account.id,
                          child: Text(item.account.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => destinationId = value),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: money.activeCategories
                      .where((item) => item.type == type)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: frequency,
                decoration: const InputDecoration(labelText: 'Frekuensi'),
                items: RecurrenceFrequency.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => frequency = value ?? frequency),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 36500)),
                  );
                  if (value != null) {
                    setState(() {
                      startDate = DateTime(
                        value.year,
                        value.month,
                        value.day,
                        startDate.hour,
                        startDate.minute,
                      );
                    });
                  }
                },
                icon: const Icon(Icons.event_repeat_outlined),
                label: Text(
                  'Mulai ${DateFormat('d MMMM yyyy', 'id_ID').format(startDate)}',
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
                          await repository.saveRule(
                            id: rule?.id,
                            name: name.text,
                            type: type,
                            amount: currency.parseInput(amount.text),
                            accountId: accountId!,
                            destinationAccountId: destinationId,
                            categoryId: categoryId,
                            note: note.text,
                            frequency: frequency,
                            startDate: startDate,
                          );
                          await repository.generateDue();
                          if (context.mounted) Navigator.pop(context);
                        } on MoneyValidationException catch (error) {
                          Get.snackbar('Tidak dapat menyimpan', error.message);
                        }
                      },
                child: const Text('Simpan Jadwal'),
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Obx(() {
        if (controller.rules.isEmpty && controller.pending.isEmpty) {
          return EmptyState(
            icon: Icons.event_repeat_outlined,
            title: 'Belum ada transaksi berulang',
            message:
                'Buat jadwal untuk tagihan, gaji, atau transaksi rutin lainnya.',
            action: FilledButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Jadwal'),
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
            if (controller.pending.isNotEmpty) ...[
              Text(
                'Menunggu Konfirmasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final occurrence in controller.pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _PendingCard(
                    occurrence: occurrence,
                    rule: controller.ruleById(occurrence.ruleId),
                    onReview: controller.ruleById(occurrence.ruleId) == null
                        ? null
                        : () => _reviewOccurrence(
                            context,
                            occurrence,
                            controller.ruleById(occurrence.ruleId)!,
                          ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Semua Jadwal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            for (final rule in controller.rules)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: FerikCard(
                  onTap: () => _showForm(context, rule: rule),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${RecurrenceFrequency.values.byName(rule.frequency).label} • berikutnya ${DateFormat('d MMM', 'id_ID').format(rule.nextDueAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            MoneyText(
                              amount: rule.amount,
                              visible: true,
                              tone: rule.type == 'income'
                                  ? MoneyTone.income
                                  : rule.type == 'expense'
                                  ? MoneyTone.expense
                                  : MoneyTone.transfer,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !rule.isPaused,
                        onChanged: (value) => Get.find<RecurringRepository>()
                            .setPaused(rule.id, paused: !value),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showForm(context, rule: rule);
                          } else {
                            Get.find<RecurringRepository>().deleteRule(rule.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.occurrence,
    required this.rule,
    required this.onReview,
  });

  final RecurringOccurrence occurrence;
  final RecurringRule? rule;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final repository = Get.find<RecurringRepository>();
    return FerikCard(
      color: context.ferikColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rule?.name ?? 'Jadwal tidak ditemukan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Jatuh tempo ${DateFormat('d MMMM yyyy', 'id_ID').format(occurrence.dueAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (rule != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            MoneyText(
              amount: rule!.amount,
              visible: true,
              tone: rule!.type == 'income'
                  ? MoneyTone.income
                  : rule!.type == 'expense'
                  ? MoneyTone.expense
                  : MoneyTone.transfer,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => repository.skipOccurrence(occurrence.id),
                  child: const Text('Lewati'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FilledButton(
                  onPressed: onReview,
                  child: const Text('Review & Buat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
