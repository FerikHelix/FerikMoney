import 'package:ferikmoney/app/theme/app_theme.dart';
import 'package:ferikmoney/app/theme/design_tokens.dart';
import 'package:ferikmoney/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/test_app.dart';

Future<BuildContext> _context(WidgetTester tester, ThemeData theme) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('theme helpers keep the exact light and dark values', () {
    testWidgets('light', (tester) async {
      final context = await _context(tester, AppTheme.light());
      final colors = context.ferikColors;

      expect(context.ferikHairline, colors.borderSubtle);
      expect(context.ferikContainerDivider, colors.primaryContainerStrong);
      expect(context.ferikFieldFill, colors.background);
      expect(context.ferikSelectorBorder, colors.borderStandard);
      expect(context.ferikSelectorIconBackground, colors.primarySoft);
      expect(context.ferikCardShadow, Colors.black.withValues(alpha: 0.08));
      expect(
        context.ferikTint(colors.expense, colors.expenseSoft),
        const Color(0xFFFCE8E8),
      );
      expect(context.ferikViolet, const Color(0xFF8B72BE));
    });

    testWidgets('dark', (tester) async {
      final context = await _context(tester, AppTheme.dark());
      final colors = context.ferikColors;

      expect(context.ferikHairline, colors.divider);
      expect(context.ferikContainerDivider, colors.divider);
      expect(context.ferikFieldFill, colors.surfaceVariant);
      expect(
        context.ferikSelectorBorder,
        colors.divider.withValues(alpha: 0.7),
      );
      expect(context.ferikSelectorIconBackground, colors.surface);
      expect(context.ferikCardShadow, Colors.transparent);
      expect(
        context.ferikTint(colors.expense, colors.expenseSoft),
        const Color(0xFFFF8A8A).withValues(alpha: 0.14),
      );
      expect(context.ferikViolet, const Color(0xFFB9A1FF));
    });
  });

  testWidgets('section header actions meet the 48 dp touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SectionHeader(
            title: 'Akun',
            actionLabel: 'Semua',
            onAction: () {},
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(TextButton));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  group('reports empty state', () {
    testWidgets(
      'shows guidance instead of zero cards when nothing is recorded',
      (tester) async {
        await pumpApp(tester, seed: false);
        await tester.tap(find.text('Laporan'));
        await tester.pumpAndSettle();

        expect(find.text('Belum ada data di periode ini'), findsOneWidget);
        expect(find.text('Tren Arus Kas'), findsNothing);
        // The period controls stay so another period can be chosen.
        expect(find.byTooltip('Periode sebelumnya'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('appears for an empty month and disappears with data', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Laporan'));
      await tester.pumpAndSettle();
      expect(find.text('Tren Arus Kas'), findsOneWidget);

      await tester.tap(find.byTooltip('Periode sebelumnya'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada data di periode ini'), findsOneWidget);

      await tester.tap(find.byTooltip('Periode berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Tren Arus Kas'), findsOneWidget);
    });
  });
}
