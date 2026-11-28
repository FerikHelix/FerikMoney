import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/models.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/l10n.dart';

typedef CommitSelection = ({int walletId, int categoryId});

Future<CommitSelection?> showCommitPicker(
  BuildContext context, {
  required CategoryKind kind,
}) {
  return showModalBottomSheet<CommitSelection>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: _CommitPicker(kind: kind),
    ),
  );
}

class _CommitPicker extends ConsumerStatefulWidget {
  const _CommitPicker({required this.kind});

  final CategoryKind kind;

  @override
  ConsumerState<_CommitPicker> createState() => _CommitPickerState();
}

class _CommitPickerState extends ConsumerState<_CommitPicker> {
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  int? _walletId;
  int? _categoryId;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final database = ref.read(databaseProvider);
    final wallets = await database.walletDao.active();
    final categories = await database.transactionDao.listCategories(
      kind: widget.kind,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _wallets = wallets;
      _categories = categories;
      _walletId = wallets.isEmpty ? null : wallets.first.id;
      _categoryId = categories.isEmpty ? null : categories.first.id;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.commitToMoney,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(context.l10n.commitHint),
        const SizedBox(height: 16),
        if (!_ready)
          const Center(child: CircularProgressIndicator())
        else ...[
          WalletDropdown(
            wallets: _wallets,
            value: _walletId,
            label: context.l10n.wallet,
            onChanged: (value) => setState(() => _walletId = value),
          ),
          const SizedBox(height: 12),
          CategoryDropdown(
            categories: _categories,
            value: _categoryId,
            label: context.l10n.category,
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _walletId == null || _categoryId == null
                ? null
                : () => Navigator.of(context)
                      .pop((walletId: _walletId!, categoryId: _categoryId!)),
            child: Text(context.l10n.save),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
