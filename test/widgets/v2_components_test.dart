import 'package:ferikmoney/app/theme/app_theme.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:ferikmoney/widgets/amount_input.dart';
import 'package:ferikmoney/widgets/expense_donut_chart.dart';
import 'package:ferikmoney/widgets/transaction_tile.dart';
import 'package:ferikmoney/widgets/transaction_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 412.0, 480.0]) {
    testWidgets('transaction controls do not overflow at ${width.toInt()} px', (
      tester,
    ) async {
      final amount = TextEditingController(text: '125.750.000');
      addTearDown(amount.dispose);
      await tester.pumpWidget(
        _TestFrame(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TransactionTypeSelector(value: 'expense', onChanged: (_) {}),
              const SizedBox(height: 16),
              AmountInput(
                controller: amount,
                autofocus: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );

      expect(find.text('Keluar'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('light type selector uses exact semantic soft fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestFrame(
        width: 390,
        child: TransactionTypeSelector(value: 'expense', onChanged: (_) {}),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('transaction-type-expense')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFCE8E8));
  });

  testWidgets('dark type selector retains alpha-based selected fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestFrame(
        width: 390,
        brightness: Brightness.dark,
        child: TransactionTypeSelector(value: 'expense', onChanged: (_) {}),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('transaction-type-expense')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFF8A8A).withValues(alpha: 0.14));
  });

  testWidgets('transaction controls remain usable with enlarged text', (
    tester,
  ) async {
    final amount = TextEditingController(text: '125.750.000');
    addTearDown(amount.dispose);
    await tester.pumpWidget(
      _TestFrame(
        width: 320,
        textScaler: const TextScaler.linear(1.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TransactionTypeSelector(value: 'transfer', onChanged: (_) {}),
            AmountInput(controller: amount, autofocus: false),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction tile remains scannable on a small phone', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 23);
    final transaction = MoneyTransaction(
      id: 'tx',
      type: 'expense',
      amount: 125750000,
      accountId: 'account',
      destinationAccountId: null,
      categoryId: 'category',
      note: 'Belanja bulanan keluarga',
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
    );
    final category = Category(
      id: 'category',
      name: 'Belanja',
      type: 'expense',
      icon: 'shopping_bag',
      createdAt: now,
    );

    await tester.pumpWidget(
      _TestFrame(
        width: 320,
        child: TransactionTile(
          transaction: transaction,
          accountName: 'Bank BCA',
          category: category,
          dateLabel: 'Hari ini',
        ),
      ),
    );

    expect(find.text('Belanja bulanan keluarga'), findsOneWidget);
    expect(find.text('\u2212Rp 125.750.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single category donut renders as a complete distribution', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestFrame(
        width: 320,
        child: ExpenseDonutChart(
          total: 750000,
          visible: true,
          slices: [ExpenseChartSlice(value: 750000, color: Color(0xFF087F5B))],
        ),
      ),
    );

    expect(find.byKey(const Key('expense-donut-painter')), findsOneWidget);
    expect(find.text('Rp 750.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestFrame extends StatelessWidget {
  const _TestFrame({
    required this.width,
    required this.child,
    this.brightness = Brightness.light,
    this.textScaler = TextScaler.noScaling,
  });

  final double width;
  final Widget child;
  final Brightness brightness;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}
