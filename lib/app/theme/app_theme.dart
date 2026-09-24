import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static ThemeData light() =>
      _build(brightness: Brightness.light, colors: const FerikColors.light());

  static ThemeData dark() =>
      _build(brightness: Brightness.dark, colors: const FerikColors.dark());

  static ThemeData _build({
    required Brightness brightness,
    required FerikColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: isDark ? colors.background : Colors.white,
          primaryContainer: colors.primaryContainer,
          onPrimaryContainer: colors.mainText,
          secondary: colors.transfer,
          onSecondary: isDark ? colors.background : Colors.white,
          secondaryContainer: colors.transfer.withValues(alpha: 0.16),
          onSecondaryContainer: colors.transfer,
          error: colors.expense,
          onError: isDark ? colors.background : Colors.white,
          surface: colors.surface,
          onSurface: colors.mainText,
          onSurfaceVariant: colors.secondaryText,
          surfaceContainerLowest: colors.background,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: isDark
              ? colors.surfaceVariant
              : colors.surfaceTertiary,
          surfaceContainerHighest: isDark
              ? colors.surfaceVariant
              : colors.surfaceStrong,
          outline: isDark ? colors.divider : colors.borderStandard,
          outlineVariant: isDark ? colors.divider : colors.borderSubtle,
          shadow: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
          scrim: Colors.black.withValues(alpha: isDark ? 0.55 : 0.24),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: colors.mainText,
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        height: 1.08,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: colors.mainText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: colors.mainText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: colors.mainText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: colors.mainText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: colors.mainText),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: colors.mainText),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: colors.secondaryText,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: colors.mainText,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        color: colors.secondaryText,
        fontWeight: FontWeight.w600,
      ),
    );

    final inputBorderColor = isDark ? colors.divider : colors.borderStandard;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: inputBorderColor),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.mainText,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? null : Colors.black.withValues(alpha: 0.08),
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark
                ? colors.divider.withValues(alpha: 0.75)
                : colors.borderSubtle,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? colors.divider : colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: inputBorder,
        enabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: isDark
                ? colors.divider.withValues(alpha: 0.7)
                : colors.borderStandard,
          ),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: colors.secondaryText),
        hintStyle: TextStyle(color: colors.secondaryText),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          backgroundColor: isDark ? null : colors.primary,
          foregroundColor: isDark ? null : Colors.white,
          disabledBackgroundColor: isDark ? null : colors.disabledSurface,
          disabledForegroundColor: isDark ? null : colors.disabledText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          side: BorderSide(
            color: isDark ? colors.divider : colors.borderStandard,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.secondaryText,
          highlightColor: colors.primary.withValues(alpha: 0.08),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: isDark ? 2 : 4,
        highlightElevation: isDark ? 1 : 3,
        focusElevation: isDark ? 2 : 4,
        hoverElevation: isDark ? 3 : 5,
        splashColor: isDark
            ? null
            : colors.primaryStrong.withValues(alpha: 0.16),
        backgroundColor: colors.primary,
        foregroundColor: isDark ? colors.background : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.secondaryText,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: isDark ? null : 6,
        modalElevation: isDark ? null : 8,
        shadowColor: isDark ? null : Colors.black.withValues(alpha: 0.10),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        modalBarrierColor: scheme.scrim,
        showDragHandle: true,
        dragHandleColor: isDark ? colors.divider : colors.borderStandard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: isDark ? null : 5,
        shadowColor: isDark ? null : Colors.black.withValues(alpha: 0.10),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceVariant,
        contentTextStyle: TextStyle(color: colors.mainText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceVariant,
      ),
      segmentedButtonTheme: isDark
          ? null
          : SegmentedButtonThemeData(
              style: ButtonStyle(
                side: WidgetStatePropertyAll(
                  BorderSide(color: colors.borderStandard),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
    );
  }
}
