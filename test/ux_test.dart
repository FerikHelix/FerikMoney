import 'package:ferik_money/app/theme.dart';
import 'package:ferik_money/core/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('empty state and save bar survive 360 dp at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ListView(
              children: [
                const EmptyState(
                  icon: Symbols.receipt_long_rounded,
                  title: 'Belum ada transaksi.',
                  body: 'Transaksi yang dicatat akan muncul di sini.',
                  actionLabel: 'Tambah transaksi',
                ),
                SaveBar(label: 'Simpan pengeluaran', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final saveButton = find.byType(FilledButton);
    expect(saveButton, findsOneWidget);
    expect(tester.getSize(saveButton).height, greaterThanOrEqualTo(48));
  });
}
