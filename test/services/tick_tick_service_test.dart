import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_k/models/k_line_point.dart';
import 'package:life_k/services/tick_tick_service.dart';

KLinePoint _makePoint({
  required String ganZhi,
  ActionAdvice? actionAdvice,
  String reason = '财星旺，宜进取',
}) {
  return KLinePoint(
    age: 30,
    year: 2026,
    ganZhi: ganZhi,
    open: 5.0,
    close: 7.0,
    high: 8.0,
    low: 4.0,
    score: 7.0,
    reason: reason,
    actionAdvice: actionAdvice,
  );
}

void main() {
  group('TickTickService.buildTitle', () {
    test('extracts day ganzhi from slash-separated format', () {
      final point = _makePoint(ganZhi: '甲子/丙午');
      final title = TickTickService.buildTitle(
        point,
        const TimeOfDay(hour: 10, minute: 0),
      );
      expect(title, contains('丙午'));
      expect(title, isNot(contains('甲子')));
      expect(title, contains('10:00提醒'));
    });

    test('uses full ganZhi when no slash (year view format)', () {
      final point = _makePoint(ganZhi: '甲子');
      final title = TickTickService.buildTitle(
        point,
        const TimeOfDay(hour: 9, minute: 30),
      );
      expect(title, contains('甲子'));
      expect(title, contains('09:30提醒'));
    });

    test('pads single-digit hour and minute', () {
      final point = _makePoint(ganZhi: '丙午');
      final title = TickTickService.buildTitle(
        point,
        const TimeOfDay(hour: 8, minute: 5),
      );
      expect(title, contains('08:05提醒'));
    });
  });

  group('TickTickService.buildContent', () {
    test('returns first suggestion when actionAdvice is present', () {
      final advice = ActionAdvice(
        suggestions: ['跟进回款', '整理账单'],
        warnings: ['避免冲动消费'],
      );
      final point = _makePoint(ganZhi: '丙午', actionAdvice: advice);
      expect(TickTickService.buildContent(point), equals('跟进回款'));
    });

    test('falls back to reason when actionAdvice is null', () {
      final point = _makePoint(ganZhi: '丙午', reason: '财星旺');
      expect(TickTickService.buildContent(point), equals('财星旺'));
    });
  });

  group('TickTickService.buildDateString', () {
    test('formats date as yyyyMMdd', () {
      final date = DateTime(2026, 2, 5);
      expect(TickTickService.buildDateString(date), equals('20260205'));
    });

    test('pads single-digit month and day', () {
      final date = DateTime(2026, 1, 9);
      expect(TickTickService.buildDateString(date), equals('20260109'));
    });
  });
}
