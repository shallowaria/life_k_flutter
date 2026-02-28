import 'package:flutter_test/flutter_test.dart';
import 'package:life_k/utils/score_normalizer.dart';

void main() {
  group('normalizeScore', () {
    group('scores already in [0, 10]', () {
      test('returns 0.0 unchanged', () {
        expect(normalizeScore(0.0), equals(0.0));
      });

      test('returns 5.0 unchanged', () {
        expect(normalizeScore(5.0), equals(5.0));
      });

      test('returns 10.0 unchanged', () {
        expect(normalizeScore(10.0), equals(10.0));
      });

      test('returns mid-range value unchanged', () {
        expect(normalizeScore(7.5), equals(7.5));
      });
    });

    group('negative scores', () {
      test('clamps -1 to 0.0', () {
        expect(normalizeScore(-1.0), equals(0.0));
      });

      test('clamps -100 to 0.0', () {
        expect(normalizeScore(-100.0), equals(0.0));
      });
    });

    group('scores above 10 (100-scale)', () {
      test('divides 100 by 10 to give 10.0', () {
        expect(normalizeScore(100.0), equals(10.0));
      });

      test('divides 75 by 10 to give 7.5', () {
        expect(normalizeScore(75.0), equals(7.5));
      });

      test('divides 50 by 10 to give 5.0', () {
        expect(normalizeScore(50.0), equals(5.0));
      });

      test('clamps 110 / 10 = 11 down to 10.0', () {
        expect(normalizeScore(110.0), equals(10.0));
      });
    });

    group('boundary edge cases', () {
      test('10.1 is treated as 100-scale, gives 1.01', () {
        expect(normalizeScore(10.1), closeTo(1.01, 0.001));
      });

      test('result is never below 0', () {
        expect(normalizeScore(-999.0), greaterThanOrEqualTo(0.0));
      });

      test('result is never above 10', () {
        expect(normalizeScore(9999.0), lessThanOrEqualTo(10.0));
      });
    });
  });
}
