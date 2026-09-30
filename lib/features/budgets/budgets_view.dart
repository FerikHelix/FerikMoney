import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../models/finance_models.dart';
import '../../repositories/budget_repository.dart';
import '../../repositories/money_repository.dart';
import '../../services/currency_service.dart';
import '../../widgets/empty_state.dart';
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
    final saved = await showModalBottomSheet<bool>(
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
                budget == null ? 'Tambah Budget' : 'Edit Budget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  try {
                    await repository.save(
                      id: budget?.id,
                      categoryId: categoryId,
                      amount: currency.parseInput(amountController.text),
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } on MoneyValidationException catch (error) {
                    Get.snackbar('Budget tidak dapat disimpan', error.message);
                  }
                },
                child: const Text('Simpan Budget'),
              ),
            ],
          ),
        ),
      ),
    );
    amountController.dispose();
    if (saved == true) Get.snackbar('Tersimpan', 'Budget bulanan diperbarui.');
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
              BudgetStatus.approaching => const Color(0xFFD49A3A),
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
                    borderRadius: BorderRadius.circular(8),
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
