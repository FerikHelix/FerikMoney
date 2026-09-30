import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';

class FerikCard extends StatelessWidget {
  const FerikCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.onTap,
    this.borderRadius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    final radius = BorderRadius.circular(borderRadius);
    return Material(
      color: color ?? colors.surface,
      elevation: 1,
      shadowColor: context.ferikCardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.ferikCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
