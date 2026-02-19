/// Chart view mode for K-line chart time axis
enum ChartViewMode {
  /// 30-year annual K-line (default)
  year,

  /// Current date +/- 1 month daily K-line
  month,

  /// Current date +/- 1 week daily K-line
  day;

  String get label {
    switch (this) {
      case ChartViewMode.year:
        return '年视图';
      case ChartViewMode.month:
        return '月视图';
      case ChartViewMode.day:
        return '日视图';
    }
  }

  /// Calculate the date range for this view mode centered on [today].
  ({DateTime start, DateTime end}) dateRange(DateTime today) {
    switch (this) {
      case ChartViewMode.year:
        // Not used for year view (uses original data directly)
        return (start: today, end: today);
      case ChartViewMode.month:
        return (
          start: DateTime(today.year, today.month - 1, today.day),
          end: DateTime(today.year, today.month + 1, today.day),
        );
      case ChartViewMode.day:
        return (
          start: today.subtract(const Duration(days: 7)),
          end: today.add(const Duration(days: 7)),
        );
    }
  }

  /// Format chart subtitle for the current view mode.
  String formatSubtitle(DateTime today, int currentAge) {
    switch (this) {
      case ChartViewMode.year:
        return '人生流年大运K线图';
      case ChartViewMode.month:
      case ChartViewMode.day:
        final range = dateRange(today);
        // 输出格式：x月y日 - z月w日
        final start = range.start;
        final end = range.end;
        final prefix = this == ChartViewMode.month ? '月运势' : '日运势';
        return '$prefix (${start.month}月${start.day}日 - ${end.month}月${end.day}日)';
    }
  }
}
