import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/design_tokens.dart';
import '../../database/app_database.dart';
import '../../repositories/money_repository.dart';
import '../../utils/icon_mapper.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/feedback.dart';
import '../../widgets/ferik_card.dart';
import '../../widgets/section_header.dart';
import '../main/money_controller.dart';

/// Icons a user can pick for a category, in display order.
const _categoryIcons = <String>[
  'label',
  'restaurant',
  'directions_car',
  'shopping_bag',
  'receipt_long',
  'movie',
  'health_and_safety',
  'school',
  'family_restroom',
  'person',
  'sports_esports',
  'payments',
  'work',
  'stars',
  'card_giftcard',
  'trending_up',
];

class CategoriesView extends GetView<MoneyController> {
  const CategoriesView({super.key});

  Future<void> _showForm(BuildContext context, {Category? category}) async {
    final name = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? 'expense';
    var icon = category?.icon ?? 'label';
    final message = await showAppSheet<String>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (context, setState) => AppSheet(
          title: category == null ? 'Tambah Kategori' : 'Edit Kategori',
          content: [
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
              autofocus: category == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Ikon', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final option in _categoryIcons)
                  _IconChoice(
                    icon: iconForName(option),
                    selected: icon == option,
                    onTap: () => setState(() => icon = option),
                  ),
              ],
            ),
            if (category != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () async {
                  final archived = await _toggleArchive(category);
                  if (archived && sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                },
                icon: Icon(
                  category.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                label: Text(
                  category.isArchived
                      ? 'Pulihkan kategori'
                      : 'Arsipkan kategori',
                ),
              ),
            ],
          ],
          footer: AsyncFilledButton(
            label: 'Simpan',
            icon: Icons.check_rounded,
            onPressed: () async {
              try {
                await Get.find<MoneyRepository>().saveCategory(
                  id: category?.id,
                  name: name.text,
                  type: type,
                  icon: icon,
                );
                if (sheetContext.mounted) {
                  Navigator.pop(
                    sheetContext,
                    category == null
                        ? 'Kategori ditambahkan.'
                        : 'Kategori diperbarui.',
                  );
                }
              } on MoneyValidationException catch (error) {
                showFeedback('Periksa kategori', error.message);
              } catch (_) {
                showFeedback(
                  'Terjadi kesalahan',
                  'Kategori tidak dapat disimpan.',
                );
              }
            },
          ),
        ),
      ),
    );
    disposeAfterSheet([name]);
    if (message != null) showFeedback('Berhasil', message);
  }

  /// Archives (or restores) a category right away, with Undo. Returns true
  /// when the change was applied.
  Future<bool> _toggleArchive(Category category) async {
    final repository = Get.find<MoneyRepository>();
    final archive = !category.isArchived;
    try {
      await repository.archiveCategory(category.id, archived: archive);
      showFeedback(
        archive ? 'Kategori diarsipkan' : 'Kategori dipulihkan',
        archive
            ? '${category.name} disembunyikan dari pilihan baru. Histori tetap aman.'
            : '${category.name} kembali tersedia.',
        duration: const Duration(seconds: 5),
        actionLabel: 'UNDO',
        onAction: () async {
          await repository.archiveCategory(category.id, archived: !archive);
          Get.closeCurrentSnackbar();
        },
      );
      return true;
    } on MoneyValidationException catch (error) {
      showFeedback('Kategori tidak dapat diperbarui', error.message);
    } catch (_) {
      showFeedback('Terjadi kesalahan', 'Kategori tidak dapat diperbarui.');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: Obx(() {
        final all = controller.userCategories;
        final expense = all
            .where((item) => item.type == 'expense' && !item.isArchived)
            .toList();
        final income = all
            .where((item) => item.type == 'income' && !item.isArchived)
            .toList();
        final archived = all.where((item) => item.isArchived).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            100,
          ),
          children: [
            _CategorySection(
              title: 'Pengeluaran',
              emptyText: 'Belum ada kategori pengeluaran.',
              categories: expense,
              onTap: (item) => _showForm(context, category: item),
            ),
            const SizedBox(height: AppSpacing.xl),
            _CategorySection(
              title: 'Pemasukan',
              emptyText: 'Belum ada kategori pemasukan.',
              categories: income,
              onTap: (item) => _showForm(context, category: item),
            ),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _CategorySection(
                title: 'Diarsipkan',
                emptyText: '',
                categories: archived,
                onTap: (item) => _showForm(context, category: item),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.emptyText,
    required this.categories,
    required this.onTap,
  });

  final String title;
  final String emptyText;
  final List<Category> categories;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        FerikCard(
          padding: EdgeInsets.zero,
          child: categories.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    emptyText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < categories.length; index++) ...[
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.ferikColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            iconForName(categories[index].icon),
                            size: 20,
                            color: context.ferikColors.primary,
                          ),
                        ),
                        title: Text(categories[index].name),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => onTap(categories[index]),
                      ),
                      if (index < categories.length - 1) const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? colors.primary : colors.secondaryText,
          ),
        ),
      ),
    );
  }
}
