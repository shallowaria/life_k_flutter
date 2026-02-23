import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/k_line_point.dart';

/// Service for creating reminders in TickTick via URL scheme deep linking.
/// Falls back gracefully when TickTick is not installed.
class TickTickService {
  TickTickService._();

  /// Extract the day ganzhi portion from a point's ganZhi field.
  /// Day/month view format: "月干支/日干支" → returns "日干支"
  /// Year view format: "甲子" → returns as-is
  static String _extractDayGanZhi(KLinePoint point) {
    return point.ganZhi.contains('/')
        ? point.ganZhi.split('/').last
        : point.ganZhi;
  }

  /// Build the task title for TickTick.
  /// Format: "丙午 财星旺 10:00提醒"
  static String buildTitle(KLinePoint point, TimeOfDay time) {
    final ganZhiDisplay = _extractDayGanZhi(point);
    final reasonSnippet = point.reason.length > 8
        ? point.reason.substring(0, 8)
        : point.reason;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$ganZhiDisplay $reasonSnippet $hour:$minute提醒';
  }

  /// Build the task content (body) for TickTick.
  /// Uses the first action suggestion if available, otherwise falls back to reason.
  static String buildContent(KLinePoint point) {
    if (point.actionAdvice != null &&
        point.actionAdvice!.suggestions.isNotEmpty) {
      return point.actionAdvice!.suggestions.first;
    }
    return point.reason;
  }

  /// Format a date as yyyyMMdd, as required by the TickTick URL scheme.
  static String buildDateString(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Attempt to open TickTick with task content pre-copied to clipboard.
  /// Copies title + content to clipboard first, then opens TickTick's
  /// collection box. Returns true if TickTick was successfully launched.
  ///
  /// Note: ticktick://creat_task opens the collection box UI but does not
  /// accept query parameters — clipboard is the reliable workaround.
  static Future<bool> createReminder({
    required KLinePoint point,
    required TimeOfDay time,
    required DateTime date,
  }) async {
    // Copy task content to clipboard so the user can paste into TickTick
    final clipboardText = '${buildTitle(point, time)}\n${buildContent(point)}';
    await Clipboard.setData(ClipboardData(text: clipboardText));

    final uri = Uri.parse('ticktick://creat_task');

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  /// Fallback text shown in a SnackBar when TickTick is not installed.
  static String buildFallbackText(KLinePoint point, TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${buildTitle(point, time)} — ${buildContent(point)} ($hour:$minute)';
  }
}
