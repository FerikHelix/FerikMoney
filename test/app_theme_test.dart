import 'package:ferikmoney/app/theme/app_theme.dart';
import 'package:ferikmoney/app/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses the complete FerikMoney V3 palette', () {
    final theme = AppTheme.light();
    final colors = theme.extension<FerikColors>()!;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F9F8));
    expect(colors.surface, const Color(0xFFFFFFFF));
    expect(colors.surfaceVariant, const Color(0xFFF1F5F3));
    expect(colors.surfaceTertiary, const Color(0xFFEAF1EE));
    expect(colors.surfaceStrong, const Color(0xFFE2ECE8));
    expect(colors.primary, const Color(0xFF087F5B));
    expect(colors.primaryStrong, const Color(0xFF066B4D));
    expect(colors.primaryContainer, const Color(0xFFD7F5E9));
    expect(colors.primaryContainerStrong, const Color(0xFFC4EDDD));
    expect(colors.primarySoft, const Color(0xFFECF9F4));
    expect(colors.mainText, const Color(0xFF17201D));
    expect(colors.secondaryText, const Color(0xFF65716C));
    expect(colors.tertiaryText, const Color(0xFF8A9691));
    expect(colors.disabledText, const Color(0xFFADB5B1));
    expect(colors.borderSubtle, const Color(0xFFE2E8E5));
    expect(colors.borderStandard, const Color(0xFFD5DEDA));
    expect(colors.borderStrong, const Color(0xFFC7D2CD));
    expect(colors.income, const Color(0xFF078653));
    expect(colors.incomeSoft, const Color(0xFFE0F5EA));
    expect(colors.expense, const Color(0xFFD94B4B));
    expect(colors.expenseSoft, const Color(0xFFFCE8E8));
    expect(colors.transfer, const Color(0xFF3977D5));
    expect(colors.transferSoft, const Color(0xFFE7EFFC));
    expect(theme.cardTheme.elevation, 1);
    expect(theme.bottomSheetTheme.modalElevation, 8);
  });

  test('dark theme retains its V2 baseline palette', () {
    final theme = AppTheme.dark();
    final colors = theme.extension<FerikColors>()!;

    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0F0E));
    expect(colors.surface, const Color(0xFF141A18));
    expect(colors.surfaceVariant, const Color(0xFF1B2320));
    expect(colors.primary, const Color(0xFF6EE7B7));
    expect(colors.income, const Color(0xFF5EE6A8));
    expect(colors.expense, const Color(0xFFFF8A8A));
    expect(colors.transfer, const Color(0xFF8DB9FF));
    expect(colors.divider, const Color(0xFF29322F));
    expect(colors.chartColors, const [
      Color(0xFF6EE7B7),
      Color(0xFF8DB9FF),
      Color(0xFFF3B96C),
      Color(0xFFB9A1FF),
      Color(0xFFFF9DB4),
      Color(0xFF7DD0C7),
    ]);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.colorScheme.scrim, Colors.black.withValues(alpha: 0.55));
  });
}
