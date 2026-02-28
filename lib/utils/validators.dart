/// Validate chart data integrity
String? validateChartData(Map<String, dynamic> data) {
  // Validate analysis
  if (!data.containsKey('analysis')) return '缺少 analysis 字段';
  final analysis = data['analysis'] as Map<String, dynamic>?;
  if (analysis == null) return 'analysis 不是有效对象';

  // Validate bazi
  final bazi = analysis['bazi'];
  if (bazi == null || bazi is! List || bazi.length != 4) {
    return 'bazi 必须是包含4个元素的数组';
  }

  // Validate chartData
  if (!data.containsKey('chartData')) return '缺少 chartData 字段';
  final chartData = data['chartData'] as List?;
  if (chartData == null) return 'chartData 格式错误';
  if (chartData.length != 30) {
    return 'chartData 必须包含 30 个数据点（当前: ${chartData.length}）';
  }

  // Validate each data point
  for (var i = 0; i < chartData.length; i++) {
    final point = chartData[i] as Map<String, dynamic>?;
    if (point == null) return 'chartData[$i] 不是有效对象';

    final age = point['age'] as num?;
    if (age == null) return 'chartData[$i].age 必须是数字';
    if (age < 1 || age > 30) return 'chartData[$i].age 必须在 1-30 范围内';

    // Validate OHLC
    final open = (point['open'] as num?)?.toDouble();
    final close = (point['close'] as num?)?.toDouble();
    final high = (point['high'] as num?)?.toDouble();
    final low = (point['low'] as num?)?.toDouble();

    if (open == null || close == null || high == null || low == null) {
      return 'chartData[$i] 缺少 OHLC 数据';
    }

    if (open < 0 || open > 10) return 'chartData[$i].open 超出范围 (0-10)';
    if (close < 0 || close > 10) return 'chartData[$i].close 超出范围 (0-10)';

    // Validate K-line logic
    final maxOC = open > close ? open : close;
    final minOC = open < close ? open : close;
    if (high < maxOC) {
      return 'chartData[$i].high ($high) < max(open,close) ($maxOC)';
    }
    if (low > minOC) {
      return 'chartData[$i].low ($low) > min(open,close) ($minOC)';
    }

    // Validate score
    final score = (point['score'] as num?)?.toDouble();
    if (score == null || score < 0 || score > 10) {
      return 'chartData[$i].score 必须在 0-10 范围内';
    }
  }

  return null; // Valid
}

/// Validate BaZi input format
String? validateBaziInput({
  required String yearPillar,
  required String monthPillar,
  required String dayPillar,
  required String hourPillar,
  required String startAge,
}) {
  final ganZhiPattern = RegExp(r'^[\u4e00-\u9fa5]{2}$');

  if (!ganZhiPattern.hasMatch(yearPillar)) return '年柱格式错误';
  if (!ganZhiPattern.hasMatch(monthPillar)) return '月柱格式错误';
  if (!ganZhiPattern.hasMatch(dayPillar)) return '日柱格式错误';
  if (!ganZhiPattern.hasMatch(hourPillar)) return '时柱格式错误';

  final age = int.tryParse(startAge);
  if (age == null || age < 0 || age > 10) return '起运年龄必须在 0-10 之间';

  return null; // Valid
}
