import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date & Time calculation utilities for streak and study tracking.
class DateTimeHelper {
  DateTimeHelper._();

  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Returns date in YYYY-MM-DD format
  static String toIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Parses date from YYYY-MM-DD
  static DateTime? fromIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return _isoDateFormat.parse(dateStr.trim());
    } catch (_) {
      return null;
    }
  }

  /// Returns today's date formatted as YYYY-MM-DD
  static String todayIso() {
    return _isoDateFormat.format(DateTime.now());
  }

  /// Calculates the difference in whole calendar days between two dates: D2 - D1
  /// Positive value means d2 is in the future compared to d1.
  static int calendarDaysDifference(DateTime d1, DateTime d2) {
    final date1 = DateTime(d1.year, d1.month, d1.day);
    final date2 = DateTime(d2.year, d2.month, d2.day);
    return date2.difference(date1).inDays;
  }

  /// Formats duration in seconds to "Xm Ys" or "X mins"
  static String formatSecondsToMinutes(int totalSeconds) {
    if (totalSeconds <= 0) return '0 min';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    } else if (seconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  /// Format TimeOfDay to "HH:mm"
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Parse "HH:mm" to TimeOfDay
  static TimeOfDay parseTimeOfDay(String timeStr, {TimeOfDay defaultTime = const TimeOfDay(hour: 20, minute: 0)}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return defaultTime;
  }

  /// Get past 7 days ISO list
  static List<DateTime> getPast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return DateTime(day.year, day.month, day.day);
    });
  }

  /// Format weekday name for Vietnamese or English
  static String getWeekdayShort(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }
}

