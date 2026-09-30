import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';

/// Title used at the top of the main tabs, so every tab starts the same way.
class PageHeader extends StatelessWidget {
  const PageHeader(
    this.title, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.sm,
    ),
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
