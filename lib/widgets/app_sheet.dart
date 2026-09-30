import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';

/// Opens a bottom sheet with the app's standard behavior: full-height aware,
/// safe-area padded, with a drag handle.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// Disposes [controllers] once a closing sheet has finished animating away.
///
/// Disposing right after `await showAppSheet(...)` returns is too early: the
/// sheet is still on screen for its exit animation, and its text fields would
/// rebuild with a disposed controller.
void disposeAfterSheet(List<ChangeNotifier> controllers) {
  Future<void>.delayed(const Duration(milliseconds: 500), () {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
}

/// Standard bottom-sheet layout: a title, scrollable [content], and an
/// optional [footer] (usually the primary button) that stays pinned so it is
/// never pushed off screen by the keyboard or a long form.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.content,
    this.footer,
  });

  final String title;
  final List<Widget> content;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.91,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxs,
                    AppSpacing.lg,
                    0,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...content,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: footer ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A filled button for async actions: shows a spinner and ignores further taps
/// while [onPressed] is running, so a double tap can never submit twice.
class AsyncFilledButton extends StatefulWidget {
  const AsyncFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;

  /// Null disables the button.
  final Future<void> Function()? onPressed;

  @override
  State<AsyncFilledButton> createState() => _AsyncFilledButtonState();
}

class _AsyncFilledButtonState extends State<AsyncFilledButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !_busy;
    final icon = _busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : widget.icon == null
        ? null
        : Icon(widget.icon);
    return FilledButton.icon(
      onPressed: enabled ? _run : null,
      icon: icon ?? const SizedBox.shrink(),
      label: Text(widget.label),
    );
  }
}
