import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/money_repository.dart';
import '../../services/currency_service.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/money_text.dart';
import '../main/money_controller.dart';
import 'budget_controller.dart';

class BudgetsView extends GetView<BudgetController> {
  const BudgetsView({super.key});

  Future<void> _showForm(BuildContext context, {Budget? budget}) async {
    final money = Get.find<MoneyController>();
    final repository = Get.find<BudgetRepository>();
    final currency = Get.find<CurrencyService>();
    final amountController = TextEditingController(
      text: budget == null
          ? ''
          : currency.formatInputDigits(budget.amount.toString()),
    );
    var categoryId = budget?.categoryId;
    final message = await showAppSheet<String>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setState) => AppSheet(
          title: budget == null ? 'Tambah Budget' : 'Edit Budget',
          content: [
            DropdownButtonFormField<String?>(
              initialValue: categoryId,
              decoration: const InputDecoration(
                labelText: 'Cakupan',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Semua pengeluaran'),
                ),
                ...money.activeCategories
                    .where((item) => item.type == 'expense')
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
              ],
              onChanged: (value) => setState(() => categoryId = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter(currency)],
              decoration: InputDecoration(
                labelText: 'Budget bulanan',
                prefixText: '${currency.current.symbol} ',
              ),
            ),
            if (budget != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final confirmed = await confirmDestructive(
                    context,
                    title: 'Hapus budget?',
                    message:
                        'Budget ini dihapus dari daftar. Transaksimu tidak berubah.',
                  );
                  if (!confirmed) return;
                  try {
                    await repository.delete(budget.id);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext, 'Budget dihapus.');
                    }
                  } on MoneyValidationException catch (error) {
                    showFeedback('Budget tidak dapat dihapus', error.message);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus budget'),
              ),
            ],
          ],
          footer: AsyncFilledButton(
            label: 'Simpan Budget',
            icon: Icons.check_rounded,
            onPressed: () async {
              try {
                await repository.save(
                  id: budget?.id,
                  categoryId: categoryId,
                  amount: currency.parseInput(amountController.text),
                );
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext, 'Budget bulanan diperbarui.');
                }
              } on MoneyValidationException catch (error) {
                showFeedback('Budget tidak dapat disimpan', error.message);
              } catch (_) {
                showFeedback(
                  'Terjadi kesalahan',
                  'Budget tidak dapat disimpan.',
                );
              }
            },
          ),
        ),
      ),
    );
    amountController.dispose();
    if (message != null) showFeedback('Berhasil', message);
  }

  @override
  Widget build(BuildContext context) {
    final money = Get.find<MoneyController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Obx(() {
        final progress = controller.progressFor(DateTime.now());
        if (progress.isEmpty) {
          return EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Belum ada budget',
            message:
                'Tetapkan batas bulanan sederhana untuk semua pengeluaran atau kategori tertentu.',
            action: FilledButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Budget'),
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
          itemCount: progress.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = progress[index];
            final category = money.categoryById(item.budget.categoryId);
            final color = switch (item.status) {
              BudgetStatus.safe => context.ferikColors.income,
              BudgetStatus.approaching => context.ferikColors.warning,
              BudgetStatus.over => context.ferikColors.expense,
            };
            return FerikCard(
              onTap: () => _showForm(context, budget: item.budget),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category?.name ?? 'Semua Pengeluaran',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        item.status.label,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: item.ratio.clamp(0, 1),
                      minHeight: 9,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: MoneyText(
                          amount: item.spent,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        'dari ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      MoneyText(
                        amount: item.budget.amount,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
