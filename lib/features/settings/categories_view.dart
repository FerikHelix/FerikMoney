import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/section_header.dart';
import '../main/money_controller.dart';

class CategoriesView extends GetView<MoneyController> {
  const CategoriesView({super.key});

  Future<void> _add(BuildContext context, {Category? category}) async {
    final name = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? 'expense';
    var icon = category?.icon ?? 'label';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category == null ? 'Tambah Kategori' : 'Edit Kategori',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    icon: Icon(Icons.arrow_downward_rounded),
                    label: Text('Keluar'),
                  ),
                  ButtonSegment(
                    value: 'income',
                    icon: Icon(Icons.arrow_upward_rounded),
                    label: Text('Masuk'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: category == null
                    ? (value) => setState(() => type = value.first)
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: const InputDecoration(
                  labelText: 'Icon',
                  prefixIcon: Icon(Icons.emoji_symbols_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'label', child: Text('Label')),
                  DropdownMenuItem(value: 'restaurant', child: Text('Makanan')),
                  DropdownMenuItem(
                    value: 'directions_car',
                    child: Text('Transportasi'),
                  ),
                  DropdownMenuItem(
                    value: 'shopping_bag',
                    child: Text('Belanja'),
                  ),
                  DropdownMenuItem(
                    value: 'receipt_long',
                    child: Text('Tagihan'),
                  ),
                  DropdownMenuItem(
                    value: 'health_and_safety',
                    child: Text('Kesehatan'),
                  ),
                  DropdownMenuItem(value: 'school', child: Text('Pendidikan')),
                  DropdownMenuItem(
                    value: 'family_restroom',
                    child: Text('Keluarga'),
                  ),
                  DropdownMenuItem(
                    value: 'payments',
                    child: Text('Pendapatan'),
                  ),
                  DropdownMenuItem(
                    value: 'trending_up',
                    child: Text('Investasi'),
                  ),
                ],
                onChanged: (value) => setState(() => icon = value ?? icon),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () async {
                  try {
                    await Get.find<MoneyRepository>().saveCategory(
                      id: category?.id,
                      name: name.text,
                      type: type,
                      icon: icon,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } on MoneyValidationException catch (error) {
                    Get.snackbar('Periksa kategori', error.message);
                  } catch (_) {
                    Get.snackbar(
                      'Terjadi kesalahan',
                      'Kategori tidak dapat disimpan.',
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    if (saved == true) {
      Get.snackbar(
        'Berhasil',
        category == null ? 'Kategori ditambahkan.' : 'Kategori diperbarui.',
      );
    }
  }

  Future<void> _archive(Category category) async {
    try {
      await Get.find<MoneyRepository>().archiveCategory(
        category.id,
        archived: !category.isArchived,
      );
      Get.snackbar(
        'Berhasil',
        category.isArchived ? 'Kategori dipulihkan.' : 'Kategori diarsipkan.',
      );
    } on MoneyValidationException catch (error) {
      Get.snackbar('Kategori tidak dapat diperbarui', error.message);
    } catch (_) {
      Get.snackbar('Terjadi kesalahan', 'Kategori tidak dapat diperbarui.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Kategori',
        onPressed: () => _add(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        final expense = controller.userCategories
            .where((item) => item.type == 'expense' && !item.isArchived)
            .toList();
        final income = controller.userCategories
            .where((item) => item.type == 'income' && !item.isArchived)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            100,
          ),
          children: [
            const SectionHeader(title: 'Pengeluaran'),
            const SizedBox(height: AppSpacing.xs),
            FerikCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < expense.length; index++) ...[
                    _CategoryTile(
                      name: expense[index].name,
                      icon: iconForName(expense[index].icon),
                      onTap: () => _add(context, category: expense[index]),
                      onArchive: () => _archive(expense[index]),
                    ),
                    if (index < expense.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Pemasukan'),
            const SizedBox(height: AppSpacing.xs),
            FerikCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < income.length; index++) ...[
                    _CategoryTile(
                      name: income[index].name,
                      icon: iconForName(income[index].icon),
                      onTap: () => _add(context, category: income[index]),
                      onArchive: () => _archive(income[index]),
                    ),
                    if (index < income.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
            if (controller.userCategories.any((item) => item.isArchived)) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Diarsipkan'),
              const SizedBox(height: AppSpacing.xs),
              FerikCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final item in controller.userCategories.where(
                      (value) => value.isArchived,
                    ))
                      _CategoryTile(
                        name: item.name,
                        icon: iconForName(item.icon),
                        onTap: () => _add(context, category: item),
                        onArchive: () => _archive(item),
                        archived: true,
                      ),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.onTap,
    required this.onArchive,
    this.archived = false,
  });

  final String name;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.ferikColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 20, color: context.ferikColors.primary),
      ),
      title: Text(name),
      onTap: onTap,
      trailing: IconButton(
        tooltip: archived ? 'Pulihkan' : 'Arsipkan',
        onPressed: onArchive,
        icon: Icon(
          archived ? Icons.unarchive_outlined : Icons.archive_outlined,
        ),
      ),
    );
  }
}
