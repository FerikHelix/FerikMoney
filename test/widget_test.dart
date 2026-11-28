import 'package:ferik_money/app/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('theme renders in light and dark mode', (tester) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Center(child: Text('FerikMoney'))),
        ),
      );
      expect(find.text('FerikMoney'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
