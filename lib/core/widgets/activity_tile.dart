import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../models/models.dart';
import '../money/rupiah.dart';
import 'display.dart';
import 'format.dart';
import 'l10n.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    required this.item,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final ActivityItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.isTransfer
        ? '${item.walletName} → ${item.title}'
        : item.title;
    final subtitleParts = [
      if (!item.isTransfer) item.walletName,
      if (item.note.isNotEmpty) item.note,
      formatDateLabel(context, item.date),
    ];
    final amount = switch (item.kind) {
      ActivityKind.income => '+${formatRupiah(item.amount)}',
      ActivityKind.expense => '-${formatRupiah(item.amount)}',
      ActivityKind.transfer => formatRupiah(item.amount),
    };
    final amountColor = item.kind == ActivityKind.income
        ? theme.colorScheme.primary
        : item.kind == ActivityKind.expense
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      leading: WalletAvatar(
        iconCodePoint: item.iconCodePoint,
        colorValue: item.kind == ActivityKind.income
            ? theme.colorScheme.primary.toARGB32()
            : theme.colorScheme.secondary.toARGB32(),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitleParts.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amount,
            style: theme.textTheme.titleSmall?.copyWith(color: amountColor),
            semanticsLabel: switch (item.kind) {
              ActivityKind.income =>
                '${context.l10n.income} ${formatRupiah(item.amount)}',
              ActivityKind.expense =>
                '${context.l10n.expense} ${formatRupiah(item.amount)}',
              ActivityKind.transfer =>
                '${context.l10n.addTransfer} ${formatRupiah(item.amount)}',
            },
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Symbols.delete_rounded),
              tooltip: context.l10n.deleteTransaction,
            ),
        ],
      ),
    );
  }
}
