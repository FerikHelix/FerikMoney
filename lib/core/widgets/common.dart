import 'package:material_ui/material_ui.dart';

import '../../core/db/errors.dart';
import '../../core/money/rupiah.dart';
import 'l10n.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class SaveBar extends StatelessWidget {
  const SaveBar({
    required this.label,
    required this.onPressed,
    this.isSaving = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isSaving ? null : onPressed,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

String errorMessage(BuildContext context, Object error) {
  if (error is DomainError) {
    return switch (error.code) {
      ErrorCodes.lastWallet => context.l10n.lastWalletBlocked,
      ErrorCodes.walletHasHistory => context.l10n.walletHasTransactions,
      ErrorCodes.duplicateName => context.l10n.walletNameDuplicate,
      ErrorCodes.sameWallet => context.l10n.sameWallet,
      ErrorCodes.futureDate => context.l10n.futureDate,
      ErrorCodes.amountTooLarge => context.l10n.amountTooLarge,
      ErrorCodes.overpayment => context.l10n.paymentTooLarge(
        error.details is int ? formatRupiah(error.details! as int) : '',
      ),
      ErrorCodes.alreadyCommitted => context.l10n.committedLabel,
      _ => context.l10n.saveFailed,
    };
  }
  return context.l10n.saveFailed;
}

void showSavedMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class DirtyPopScope extends StatelessWidget {
  const DirtyPopScope({required this.dirty, required this.child, super.key});

  final bool dirty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldDiscard = await confirmAction(
          context,
          title: context.l10n.discardChanges,
          body: context.l10n.discardChangesBody,
          confirmLabel: context.l10n.discard,
        );
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
