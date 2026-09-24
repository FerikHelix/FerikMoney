import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double hero = 24;
  static const double xl = 28;
}

class FerikColors extends ThemeExtension<FerikColors> {
  const FerikColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceTertiary,
    required this.surfaceStrong,
    required this.primary,
    required this.primaryStrong,
    required this.primaryContainer,
    required this.primaryContainerStrong,
    required this.primarySoft,
    required this.mainText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.disabledText,
    required this.disabledSurface,
    required this.divider,
    required this.borderSubtle,
    required this.borderStandard,
    required this.borderStrong,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.transfer,
    required this.transferSoft,
    required this.chartColors,
  });

  const FerikColors.light()
    : background = const Color(0xFFF7F9F8),
      surface = const Color(0xFFFFFFFF),
      surfaceVariant = const Color(0xFFF1F5F3),
      surfaceTertiary = const Color(0xFFEAF1EE),
      surfaceStrong = const Color(0xFFE2ECE8),
      primary = const Color(0xFF087F5B),
      primaryStrong = const Color(0xFF066B4D),
      primaryContainer = const Color(0xFFD7F5E9),
      primaryContainerStrong = const Color(0xFFC4EDDD),
      primarySoft = const Color(0xFFECF9F4),
      mainText = const Color(0xFF17201D),
      secondaryText = const Color(0xFF65716C),
      tertiaryText = const Color(0xFF8A9691),
      disabledText = const Color(0xFFADB5B1),
      disabledSurface = const Color(0xFFE5E9E7),
      divider = const Color(0xFFD5DEDA),
      borderSubtle = const Color(0xFFE2E8E5),
      borderStandard = const Color(0xFFD5DEDA),
      borderStrong = const Color(0xFFC7D2CD),
      income = const Color(0xFF078653),
      incomeSoft = const Color(0xFFE0F5EA),
      expense = const Color(0xFFD94B4B),
      expenseSoft = const Color(0xFFFCE8E8),
      transfer = const Color(0xFF3977D5),
      transferSoft = const Color(0xFFE7EFFC),
      chartColors = const [
        Color(0xFF087F5B),
        Color(0xFF2AA876),
        Color(0xFF4CB8A0),
        Color(0xFF4D8CC9),
        Color(0xFFD49A3A),
        Color(0xFF8B72BE),
      ];

  const FerikColors.dark()
    : background = const Color(0xFF0B0F0E),
      surface = const Color(0xFF141A18),
      surfaceVariant = const Color(0xFF1B2320),
      surfaceTertiary = const Color(0xFF202A26),
      surfaceStrong = const Color(0xFF27332E),
      primary = const Color(0xFF6EE7B7),
      primaryStrong = const Color(0xFF57D6A3),
      primaryContainer = const Color(0xFF123D32),
      primaryContainerStrong = const Color(0xFF174B3D),
      primarySoft = const Color(0xFF122B24),
      mainText = const Color(0xFFF1F5F3),
      secondaryText = const Color(0xFF9EAAA5),
      tertiaryText = const Color(0xFF77847E),
      disabledText = const Color(0xFF59645F),
      disabledSurface = const Color(0xFF29322F),
      divider = const Color(0xFF29322F),
      borderSubtle = const Color(0xFF232D29),
      borderStandard = const Color(0xFF29322F),
      borderStrong = const Color(0xFF34413C),
      income = const Color(0xFF5EE6A8),
      incomeSoft = const Color(0xFF13372B),
      expense = const Color(0xFFFF8A8A),
      expenseSoft = const Color(0xFF3A2020),
      transfer = const Color(0xFF8DB9FF),
      transferSoft = const Color(0xFF182A42),
      chartColors = const [
        Color(0xFF6EE7B7),
        Color(0xFF8DB9FF),
        Color(0xFFF3B96C),
        Color(0xFFB9A1FF),
        Color(0xFFFF9DB4),
        Color(0xFF7DD0C7),
      ];

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceTertiary;
  final Color surfaceStrong;
  final Color primary;
  final Color primaryStrong;
  final Color primaryContainer;
  final Color primaryContainerStrong;
  final Color primarySoft;
  final Color mainText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color disabledText;
  final Color disabledSurface;
  final Color divider;
  final Color borderSubtle;
  final Color borderStandard;
  final Color borderStrong;
  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;
  final Color transfer;
  final Color transferSoft;
  final List<Color> chartColors;

  @override
  FerikColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceTertiary,
    Color? surfaceStrong,
    Color? primary,
    Color? primaryStrong,
    Color? primaryContainer,
    Color? primaryContainerStrong,
    Color? primarySoft,
    Color? mainText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? disabledText,
    Color? disabledSurface,
    Color? divider,
    Color? borderSubtle,
    Color? borderStandard,
    Color? borderStrong,
    Color? income,
    Color? incomeSoft,
    Color? expense,
    Color? expenseSoft,
    Color? transfer,
    Color? transferSoft,
    List<Color>? chartColors,
  }) => FerikColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
    surfaceStrong: surfaceStrong ?? this.surfaceStrong,
    primary: primary ?? this.primary,
    primaryStrong: primaryStrong ?? this.primaryStrong,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    primaryContainerStrong:
        primaryContainerStrong ?? this.primaryContainerStrong,
    primarySoft: primarySoft ?? this.primarySoft,
    mainText: mainText ?? this.mainText,
    secondaryText: secondaryText ?? this.secondaryText,
    tertiaryText: tertiaryText ?? this.tertiaryText,
    disabledText: disabledText ?? this.disabledText,
    disabledSurface: disabledSurface ?? this.disabledSurface,
    divider: divider ?? this.divider,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    borderStandard: borderStandard ?? this.borderStandard,
    borderStrong: borderStrong ?? this.borderStrong,
    income: income ?? this.income,
    incomeSoft: incomeSoft ?? this.incomeSoft,
    expense: expense ?? this.expense,
    expenseSoft: expenseSoft ?? this.expenseSoft,
    transfer: transfer ?? this.transfer,
    transferSoft: transferSoft ?? this.transferSoft,
    chartColors: chartColors ?? this.chartColors,
  );

  @override
  FerikColors lerp(covariant FerikColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FerikColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceVariant: mix(surfaceVariant, other.surfaceVariant),
      surfaceTertiary: mix(surfaceTertiary, other.surfaceTertiary),
      surfaceStrong: mix(surfaceStrong, other.surfaceStrong),
      primary: mix(primary, other.primary),
      primaryStrong: mix(primaryStrong, other.primaryStrong),
      primaryContainer: mix(primaryContainer, other.primaryContainer),
      primaryContainerStrong: mix(
        primaryContainerStrong,
        other.primaryContainerStrong,
      ),
      primarySoft: mix(primarySoft, other.primarySoft),
      mainText: mix(mainText, other.mainText),
      secondaryText: mix(secondaryText, other.secondaryText),
      tertiaryText: mix(tertiaryText, other.tertiaryText),
      disabledText: mix(disabledText, other.disabledText),
      disabledSurface: mix(disabledSurface, other.disabledSurface),
      divider: mix(divider, other.divider),
      borderSubtle: mix(borderSubtle, other.borderSubtle),
      borderStandard: mix(borderStandard, other.borderStandard),
      borderStrong: mix(borderStrong, other.borderStrong),
      income: mix(income, other.income),
      incomeSoft: mix(incomeSoft, other.incomeSoft),
      expense: mix(expense, other.expense),
      expenseSoft: mix(expenseSoft, other.expenseSoft),
      transfer: mix(transfer, other.transfer),
      transferSoft: mix(transferSoft, other.transferSoft),
      chartColors: List<Color>.generate(
        chartColors.length,
        (index) => mix(
          chartColors[index],
          other.chartColors[index % other.chartColors.length],
        ),
      ),
    );
  }
}

extension FerikThemeContext on BuildContext {
  FerikColors get ferikColors =>
      Theme.of(this).extension<FerikColors>() ?? const FerikColors.light();

  bool get isFerikDark => Theme.of(this).brightness == Brightness.dark;

  Color get ferikCardBorder => isFerikDark
      ? ferikColors.divider.withValues(alpha: 0.75)
      : ferikColors.borderSubtle;

  Color get ferikInteractiveBorder =>
      isFerikDark ? ferikColors.divider : ferikColors.borderStandard;
}
