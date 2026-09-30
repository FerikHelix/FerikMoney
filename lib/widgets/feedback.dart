import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/theme/design_tokens.dart';

/// Single place for transient feedback so every screen reports results the
/// same way: at the bottom, above the floating action button.
void showFeedback(
  String title,
  String message, {
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    duration: duration,
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      // Clears the centered FAB and the navigation bar.
      96,
    ),
    mainButton: actionLabel == null || onAction == null
        ? null
        : TextButton(onPressed: onAction, child: Text(actionLabel)),
  );
}
