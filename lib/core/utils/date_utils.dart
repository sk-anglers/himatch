import 'package:intl/intl.dart';

abstract class AppDateUtils {
  static final DateFormat dateFormat = DateFormat('yyyy/MM/dd');
  static final DateFormat timeFormat = DateFormat('HH:mm');
  static final DateFormat dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');
  static final DateFormat dayOfWeekFormat = DateFormat('E', 'ja');
  static final DateFormat monthDayFormat = DateFormat('M/d', 'ja');
  static final DateFormat monthDayWeekFormat = DateFormat('M/d (E)', 'ja');

  static String formatDate(DateTime date) => dateFormat.format(date);
  static String formatTime(DateTime time) => timeFormat.format(time);
  static String formatDateTime(DateTime dt) => dateTimeFormat.format(dt);
  static String formatMonthDayWeek(DateTime date) =>
      monthDayWeekFormat.format(date);

  /// Calculate duration in hours between two DateTimes
  static double durationInHours(DateTime start, DateTime end) {
    return end.difference(start).inMinutes / 60.0;
  }

  /// Check if a time slot is in the evening (after 18:00)
  static bool isEvening(DateTime time) => time.hour >= 18;

  /// Check if a time slot is around lunch (11:00-14:00)
  static bool isLunchTime(DateTime time) =>
      time.hour >= 11 && time.hour < 14;
}
