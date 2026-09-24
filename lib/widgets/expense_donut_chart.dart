import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import 'money_text.dart';

class ExpenseChartSlice {
  const ExpenseChartSlice({required this.value, required this.color});

  final int value;
  final Color color;
}

class ExpenseDonutChart extends StatelessWidget {
  const ExpenseDonutChart({
    super.key,
    required this.total,
    required this.slices,
    required this.visible,
  });

  final int total;
  final List<ExpenseChartSlice> slices;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Diagram pengeluaran berdasarkan kategori',
      child: SizedBox.square(
        dimension: 206,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              key: const Key('expense-donut-painter'),
              size: const Size.square(206),
              painter: _DonutPainter(
                slices: slices,
                trackColor: context.ferikColors.surfaceVariant,
              ),
            ),
            SizedBox(
              width: 126,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pengeluaran',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  MoneyText(
                    amount: total,
                    visible: visible,
                    tone: MoneyTone.expense,
                    scaleDown: true,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.trackColor});

  final List<ExpenseChartSlice> slices;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 22.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);
    if (total <= 0) return;
    const gap = 0.035;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final fullSweep = (slice.value / total) * math.pi * 2;
      final sweep = slices.length == 1
          ? math.pi * 2
          : math.max(0.01, fullSweep - gap);
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.trackColor != trackColor;
}
