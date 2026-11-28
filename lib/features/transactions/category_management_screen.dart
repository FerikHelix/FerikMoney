import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/db/errors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/display.dart';
import '../../core/widgets/l10n.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  CategoryKind _kind = CategoryKind.expense;

  Future<void> _create() async {
    final name = await _askName(title: context.l10n.newCategory, initial: '');
    if (name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await ref
          .read(databaseProvider)
          .transactionDao
          .createCategory(
            name: name,
            kind: _kind,
            iconCodePoint: _kind == CategoryKind.expense
                ? Symbols.shopping_bag_rounded.codePoint
                : Symbols.payments_rounded.codePoint,
            colorValue: _kind == CategoryKind.expense ? 0xFFE07A5F : 0xFF2E7D32,
          );
      if (mounted) {
        showSavedMessage(context, context.l10n.categorySaved);
      }
    } on DomainError {
      if (mounted) {
        showSavedMessage(context, context.l10n.duplicateName);
      }
    }
  }

  Future<void> _rename(Category category) async {
    final name = await _askName(
      title: context.l10n.categoryName,
      initial: category.name,
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await ref
          .read(databaseProvider)
          .transactionDao
          .renameCategory(category.id, name);
      if (mounted) {
        showSavedMessage(context, context.l10n.categorySaved);
      }
    } on DomainError {
      if (mounted) {
        showSavedMessage(context, context.l10n.duplicateName);
      }
    }
  }

  Future<void> _archive(Category category) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.archiveCategory,
      body: category.name,
      confirmLabel: context.l10n.archive,
    );
    if (!confirmed) {
      return;
    }
    await ref
        .read(databaseProvider)
        .transactionDao
        .archiveCategory(category.id);
    if (mounted) {
      showSavedMessage(context, context.l10n.categoryArchived);
    }
  }

  Future<String?> _askName({
    required String title,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: context.l10n.categoryName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider(_kind));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.categoryManagement)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-categories',
        onPressed: _create,
        tooltip: context.l10n.newCategory,
        child: const Icon(Symbols.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<CategoryKind>(
              segments: [
                ButtonSegment(
                  value: CategoryKind.expense,
                  label: Text(context.l10n.expenseCategory),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text(context.l10n.incomeCategory),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) {
                setState(() => _kind = value.first);
              },
            ),
          ),
          Expanded(
            child: categories.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Symbols.category_rounded,
                    title: context.l10n.categoryManagement,
                    body: context.l10n.noCategoriesBody,
                    actionLabel: context.l10n.newCategory,
                    onAction: _create,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: [
                    for (final category in items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: WalletAvatar(
                            iconCodePoint: category.iconCodePoint,
                            colorValue: category.colorValue,
                          ),
                          title: Text(category.name),
                          subtitle: category.isSystem
                              ? Text(context.l10n.transferCategory)
                              : null,
                          trailing: category.isSystem
                              ? const Icon(Symbols.lock_rounded)
                              : PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'rename') {
                                      _rename(category);
                                    } else {
                                      _archive(category);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text(context.l10n.edit),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Text(context.l10n.archive),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text(context.l10n.loadFailed)),
            ),
          ),
        ],
      ),
    );
  }
}
