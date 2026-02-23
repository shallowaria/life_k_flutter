import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_k/models/k_line_point.dart';
import 'package:life_k/widgets/k_line_chart/chart_view_mode.dart';
import 'package:life_k/widgets/k_line_chart/k_line_tooltip.dart';

KLinePoint _makePoint({ActionAdvice? actionAdvice}) {
  return KLinePoint(
    age: 30,
    year: 2026,
    ganZhi: '甲子/丙午',
    open: 5.0,
    close: 7.0,
    high: 8.0,
    low: 4.0,
    score: 7.0,
    reason: '财星旺，宜进取',
    actionAdvice: actionAdvice,
  );
}

final _advice = ActionAdvice(
  suggestions: ['跟进回款', '整理账单'],
  warnings: ['避免冲动消费'],
  basis: '财星入库',
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('KLineTooltip reminder button visibility', () {
    testWidgets('year view does not show reminder button', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          KLineTooltip(
            point: _makePoint(actionAdvice: _advice),
            viewMode: ChartViewMode.year,
            onReminderTap: () => tapped = true,
          ),
        ),
      );
      expect(find.text('一键提醒'), findsNothing);
      expect(tapped, isFalse);
    });

    testWidgets('month view does not show reminder button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          KLineTooltip(
            point: _makePoint(actionAdvice: _advice),
            viewMode: ChartViewMode.month,
            onReminderTap: () {},
          ),
        ),
      );
      expect(find.text('一键提醒'), findsNothing);
    });

    testWidgets('day view without actionAdvice does not show button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          KLineTooltip(
            point: _makePoint(),
            viewMode: ChartViewMode.day,
            onReminderTap: () {},
          ),
        ),
      );
      expect(find.text('一键提醒'), findsNothing);
    });

    testWidgets('day view with actionAdvice shows reminder button', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          KLineTooltip(
            point: _makePoint(actionAdvice: _advice),
            viewMode: ChartViewMode.day,
            onReminderTap: () => tapped = true,
          ),
        ),
      );
      expect(find.text('一键提醒'), findsOneWidget);
      await tester.tap(find.text('一键提醒'));
      expect(tapped, isTrue);
    });
  });
}
