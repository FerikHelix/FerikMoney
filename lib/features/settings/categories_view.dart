import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../repositories/money_repository.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/section_header.dart';
import '../main/money_controller.dart';

class CategoriesView extends GetView<MoneyController> {
  const CategoriesView({super.key});

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    var type = 'expense';
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
                'Tambah Kategori',
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
                onSelectionChanged: (value) =>
                    setState(() => type = value.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama kategori'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () async {
                  try {
                    await Get.find<MoneyRepository>().saveCategory(
                      name: name.text,
                      type: type,
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
    if (saved == true) Get.snackbar('Berhasil', 'Kategori ditambahkan.');
  }

  Future<void> _delete(String id) async {
    try {
      await Get.find<MoneyRepository>().deleteCategory(id);
      Get.snackbar('Berhasil', 'Kategori dihapus.');
    } on MoneyValidationException catch (error) {
      Get.snackbar('Kategori tidak dapat dihapus', error.message);
    } catch (_) {
      Get.snackbar('Terjadi kesalahan', 'Kategori tidak dapat dihapus.');
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
        final expense = controller.categories
            .where((item) => item.type == 'expense')
            .toList();
        final income = controller.categories
            .where((item) => item.type == 'income')
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
                      onDelete: () => _delete(expense[index].id),
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
                      onDelete: () => _delete(income[index].id),
                    ),
                    if (index < income.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
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
    required this.onDelete,
  });

  final String name;
  final IconData icon;
  final VoidCallback onDelete;

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
      trailing: IconButton(
        tooltip: 'Hapus',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}
