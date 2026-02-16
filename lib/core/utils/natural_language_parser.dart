/// Parse Japanese natural language input into structured event data.
///
/// Handles relative dates (今日, 明日, 来週), absolute dates (3/22),
/// times (9時, 午後3時, 9:00), locations (@場所), and recurrence (毎週月曜).
class NaturalLanguageParser {
  // Day-of-week mapping (Japanese → DateTime.weekday)
  static const Map<String, int> _weekdayMap = {
    '月': DateTime.monday,
    '火': DateTime.tuesday,
    '水': DateTime.wednesday,
    '木': DateTime.thursday,
    '金': DateTime.friday,
    '土': DateTime.saturday,
    '日': DateTime.sunday,
    '月曜': DateTime.monday,
    '火曜': DateTime.tuesday,
    '水曜': DateTime.wednesday,
    '木曜': DateTime.thursday,
    '金曜': DateTime.friday,
    '土曜': DateTime.saturday,
    '日曜': DateTime.sunday,
    '月曜日': DateTime.monday,
    '火曜日': DateTime.tuesday,
    '水曜日': DateTime.wednesday,
    '木曜日': DateTime.thursday,
    '金曜日': DateTime.friday,
    '土曜日': DateTime.saturday,
    '日曜日': DateTime.sunday,
  };

  // RRULE weekday abbreviations
  static const Map<int, String> _rruleWeekday = {
    DateTime.monday: 'MO',
    DateTime.tuesday: 'TU',
    DateTime.wednesday: 'WE',
    DateTime.thursday: 'TH',
    DateTime.friday: 'FR',
    DateTime.saturday: 'SA',
    DateTime.sunday: 'SU',
  };

  // Known time-of-day keywords → (startHour, startMinute, endHour, endMinute)
  static const Map<String, (int, int, int, int)> _timeKeywords = {
    '朝': (8, 0, 9, 0),
    'モーニング': (8, 0, 9, 30),
    'ランチ': (12, 0, 13, 30),
    '昼': (12, 0, 13, 0),
    '午後': (13, 0, 17, 0),
    '夕方': (17, 0, 19, 0),
    '夜': (19, 0, 21, 0),
    '飲み会': (19, 0, 22, 0),
    '飲み': (19, 0, 22, 0),
    '早番': (6, 0, 15, 0),
    '遅番': (14, 0, 23, 0),
    '夜勤': (22, 0, 7, 0),
  };

  /// Parse input string and return structured result.
  ///
  /// Returns null if no meaningful information could be extracted.
  static ParseResult? parse(String input, {DateTime? now}) {
    if (input.trim().isEmpty) return null;

    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? date;
    DateTime? startTime;
    DateTime? endTime;
    bool isAllDay = false;
    String? location;
    String? recurrenceRule;
    String? title;

    var remaining = input.trim();

    // ── Extract location (@場所 or 場所:場所名) ──
    final locationAtMatch = RegExp(r'[@＠](\S+)').firstMatch(remaining);
    if (locationAtMatch != null) {
      location = locationAtMatch.group(1);
      remaining = remaining.replaceFirst(locationAtMatch.group(0)!, '').trim();
    } else {
      final locationColonMatch =
          RegExp(r'場所[:：]\s*(\S+)').firstMatch(remaining);
      if (locationColonMatch != null) {
        location = locationColonMatch.group(1);
        remaining =
            remaining.replaceFirst(locationColonMatch.group(0)!, '').trim();
      }
    }

    // ── Extract recurrence ──
    final recurrenceResult = _extractRecurrence(remaining);
    if (recurrenceResult != null) {
      recurrenceRule = recurrenceResult.$1;
      remaining = recurrenceResult.$2;
    }

    // ── Extract all-day ──
    if (remaining.contains('終日') || remaining.contains('一日中')) {
      isAllDay = true;
      remaining = remaining
          .replaceAll('終日', '')
          .replaceAll('一日中', '')
          .trim();
    }

    // ── Extract date ──
    final dateResult = _extractDate(remaining, today);
    if (dateResult != null) {
      date = dateResult.$1;
      remaining = dateResult.$2;
    }

    // ── Extract time range (e.g. 10時から12時まで) ──
    final timeRangeResult = _extractTimeRange(remaining, date ?? today);
    if (timeRangeResult != null) {
      startTime = timeRangeResult.$1;
      endTime = timeRangeResult.$2;
      remaining = timeRangeResult.$3;
    }

    // ── Extract single time (e.g. 18時から) ──
    if (startTime == null) {
      final singleTimeResult = _extractSingleTime(remaining, date ?? today);
      if (singleTimeResult != null) {
        startTime = singleTimeResult.$1;
        remaining = singleTimeResult.$2;
      }
    }

    // ── Apply time keywords for implicit times ──
    if (startTime == null && !isAllDay) {
      for (final entry in _timeKeywords.entries) {
        if (remaining.contains(entry.key)) {
          final baseDate = date ?? today;
          final times = entry.value;
          startTime = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            times.$1,
            times.$2,
          );
          endTime = DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            times.$3,
            times.$4,
          );
          // Don't remove keyword from remaining — it may be the title
          break;
        }
      }
    }

    // ── Extract title (remaining text after stripping particles) ──
    title = _extractTitle(remaining);

    // If nothing meaningful was found, return null
    if (date == null &&
        startTime == null &&
        recurrenceRule == null &&
        isAllDay == false &&
        location == null) {
      // Still return a result if we at least got a title
      if (title != null && title.isNotEmpty) {
        return ParseResult(title: title);
      }
      return null;
    }

    return ParseResult(
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      location: location,
      recurrenceRule: recurrenceRule,
    );
  }

  // ── Date extraction ──

  static (DateTime, String)? _extractDate(String input, DateTime today) {
    // Absolute date: M/D or M月D日
    final absMatch =
        RegExp(r'(\d{1,2})[/月](\d{1,2})日?').firstMatch(input);
    if (absMatch != null) {
      final month = int.parse(absMatch.group(1)!);
      final day = int.parse(absMatch.group(2)!);
      var year = today.year;
      final candidate = DateTime(year, month, day);
      if (candidate.isBefore(today)) {
        year++;
      }
      return (
        DateTime(year, month, day),
        input.replaceFirst(absMatch.group(0)!, '').trim(),
      );
    }

    // 再来週の<曜日>
    final saraiMatch =
        RegExp(r'再来週の?([月火水木金土日]曜?日?)').firstMatch(input);
    if (saraiMatch != null) {
      final weekday = _weekdayMap[saraiMatch.group(1)!];
      if (weekday != null) {
        final target = _nextWeekday(today, weekday, weeksAhead: 2);
        return (
          target,
          input.replaceFirst(saraiMatch.group(0)!, '').trim(),
        );
      }
    }

    // 来週の<曜日>
    final raishuMatch =
        RegExp(r'来週の?([月火水木金土日]曜?日?)').firstMatch(input);
    if (raishuMatch != null) {
      final weekday = _weekdayMap[raishuMatch.group(1)!];
      if (weekday != null) {
        final target = _nextWeekday(today, weekday, weeksAhead: 1);
        return (
          target,
          input.replaceFirst(raishuMatch.group(0)!, '').trim(),
        );
      }
    }

    // 今週の<曜日>
    final konshuMatch =
        RegExp(r'今週の?([月火水木金土日]曜?日?)').firstMatch(input);
    if (konshuMatch != null) {
      final weekday = _weekdayMap[konshuMatch.group(1)!];
      if (weekday != null) {
        final target = _nextWeekday(today, weekday, weeksAhead: 0);
        return (
          target,
          input.replaceFirst(konshuMatch.group(0)!, '').trim(),
        );
      }
    }

    // Standalone weekday (次の<曜日>)
    final nextDayMatch =
        RegExp(r'次の?([月火水木金土日]曜?日?)').firstMatch(input);
    if (nextDayMatch != null) {
      final weekday = _weekdayMap[nextDayMatch.group(1)!];
      if (weekday != null) {
        final target = _nextOccurrence(today, weekday);
        return (
          target,
          input.replaceFirst(nextDayMatch.group(0)!, '').trim(),
        );
      }
    }

    // Relative keywords
    if (input.contains('明後日')) {
      return (
        today.add(const Duration(days: 2)),
        input.replaceFirst('明後日', '').trim(),
      );
    }
    if (input.contains('明日')) {
      return (
        today.add(const Duration(days: 1)),
        input.replaceFirst('明日', '').trim(),
      );
    }
    if (input.contains('今日')) {
      return (today, input.replaceFirst('今日', '').trim());
    }

    // 来月
    if (input.contains('来月')) {
      final nextMonth = today.month == 12
          ? DateTime(today.year + 1, 1, 1)
          : DateTime(today.year, today.month + 1, 1);
      return (nextMonth, input.replaceFirst('来月', '').trim());
    }

    // 月末
    if (input.contains('月末')) {
      final lastDay = DateTime(today.year, today.month + 1, 0);
      return (lastDay, input.replaceFirst('月末', '').trim());
    }

    // 来週 (without specific day → next Monday)
    if (input.contains('再来週')) {
      final target = _nextWeekday(today, DateTime.monday, weeksAhead: 2);
      return (target, input.replaceFirst('再来週', '').trim());
    }
    if (input.contains('来週')) {
      final target = _nextWeekday(today, DateTime.monday, weeksAhead: 1);
      return (target, input.replaceFirst('来週', '').trim());
    }

    // <曜日> alone (this/next occurrence)
    for (final entry in _weekdayMap.entries) {
      if (input.contains(entry.key)) {
        // Only match if it looks like a standalone weekday reference
        final pattern = RegExp('(の|)${RegExp.escape(entry.key)}(の|に|)');
        final match = pattern.firstMatch(input);
        if (match != null) {
          final target = _nextOccurrence(today, entry.value);
          return (
            target,
            input.replaceFirst(match.group(0)!, '').trim(),
          );
        }
      }
    }

    return null;
  }

  // ── Time extraction ──

  /// Extract time range like "10時から12時まで" or "10:00-12:00".
  static (DateTime, DateTime, String)? _extractTimeRange(
    String input,
    DateTime baseDate,
  ) {
    // Pattern: Xh from Y to Z (午前/午後 prefix supported)
    final rangePattern = RegExp(
      r'(午前|午後)?(\d{1,2})[:：時](\d{1,2})?分?'
      r'(から|～|〜|-)'
      r'(午前|午後)?(\d{1,2})[:：時](\d{1,2})?分?(まで)?',
    );

    final match = rangePattern.firstMatch(input);
    if (match == null) return null;

    var startHour = int.parse(match.group(2)!);
    final startMinute = int.tryParse(match.group(3) ?? '') ?? 0;
    var endHour = int.parse(match.group(6)!);
    final endMinute = int.tryParse(match.group(7) ?? '') ?? 0;

    // Handle 午前/午後
    if (match.group(1) == '午後' && startHour < 12) startHour += 12;
    if (match.group(5) == '午後' && endHour < 12) endHour += 12;
    if (match.group(1) == '午前' && startHour == 12) startHour = 0;
    if (match.group(5) == '午前' && endHour == 12) endHour = 0;

    final startDt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      startHour,
      startMinute,
    );
    final endDt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      endHour,
      endMinute,
    );

    return (
      startDt,
      endDt,
      input.replaceFirst(match.group(0)!, '').trim(),
    );
  }

  /// Extract a single time like "18時から" or "午後3時".
  static (DateTime, String)? _extractSingleTime(
    String input,
    DateTime baseDate,
  ) {
    // Pattern: 午前/午後 + hour + optional half/minutes
    final timePattern = RegExp(
      r'(午前|午後)?(\d{1,2})[:：時](\d{1,2}|半)?分?(から|に)?',
    );

    final match = timePattern.firstMatch(input);
    if (match == null) return null;

    var hour = int.parse(match.group(2)!);
    var minute = 0;
    final minStr = match.group(3);
    if (minStr == '半') {
      minute = 30;
    } else if (minStr != null) {
      minute = int.tryParse(minStr) ?? 0;
    }

    // Handle 午前/午後
    if (match.group(1) == '午後' && hour < 12) hour += 12;
    if (match.group(1) == '午前' && hour == 12) hour = 0;

    final dt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );

    return (dt, input.replaceFirst(match.group(0)!, '').trim());
  }

  // ── Recurrence extraction ──

  static (String, String)? _extractRecurrence(String input) {
    // 毎日
    if (input.contains('毎日')) {
      return (
        'FREQ=DAILY;INTERVAL=1',
        input.replaceFirst('毎日', '').trim(),
      );
    }

    // 隔週<曜日> (every other week)
    final kakushuMatch =
        RegExp(r'隔週の?([月火水木金土日]曜?日?)').firstMatch(input);
    if (kakushuMatch != null) {
      final weekday = _weekdayMap[kakushuMatch.group(1)!];
      if (weekday != null) {
        final rrDay = _rruleWeekday[weekday]!;
        return (
          'FREQ=WEEKLY;INTERVAL=2;BYDAY=$rrDay',
          input.replaceFirst(kakushuMatch.group(0)!, '').trim(),
        );
      }
    }

    // N週間ごとの<曜日>
    final nWeekMatch =
        RegExp(r'(\d+)週間ごとの?([月火水木金土日]曜?日?)').firstMatch(input);
    if (nWeekMatch != null) {
      final interval = int.parse(nWeekMatch.group(1)!);
      final weekday = _weekdayMap[nWeekMatch.group(2)!];
      if (weekday != null) {
        final rrDay = _rruleWeekday[weekday]!;
        return (
          'FREQ=WEEKLY;INTERVAL=$interval;BYDAY=$rrDay',
          input.replaceFirst(nWeekMatch.group(0)!, '').trim(),
        );
      }
    }

    // 毎月第N<曜日>
    final monthlyDayMatch =
        RegExp(r'毎月第(\d+)([月火水木金土日]曜?日?)').firstMatch(input);
    if (monthlyDayMatch != null) {
      final ordinal = int.parse(monthlyDayMatch.group(1)!);
      final weekday = _weekdayMap[monthlyDayMatch.group(2)!];
      if (weekday != null) {
        final rrDay = _rruleWeekday[weekday]!;
        return (
          'FREQ=MONTHLY;BYDAY=$ordinal$rrDay',
          input.replaceFirst(monthlyDayMatch.group(0)!, '').trim(),
        );
      }
    }

    // 毎月N日
    final monthlyDateMatch = RegExp(r'毎月(\d{1,2})日').firstMatch(input);
    if (monthlyDateMatch != null) {
      final day = int.parse(monthlyDateMatch.group(1)!);
      return (
        'FREQ=MONTHLY;BYMONTHDAY=$day',
        input.replaceFirst(monthlyDateMatch.group(0)!, '').trim(),
      );
    }

    // 毎週<曜日>
    final weeklyMatch =
        RegExp(r'毎週の?([月火水木金土日]曜?日?)').firstMatch(input);
    if (weeklyMatch != null) {
      final weekday = _weekdayMap[weeklyMatch.group(1)!];
      if (weekday != null) {
        final rrDay = _rruleWeekday[weekday]!;
        return (
          'FREQ=WEEKLY;BYDAY=$rrDay',
          input.replaceFirst(weeklyMatch.group(0)!, '').trim(),
        );
      }
    }

    // 毎週 (without specific day)
    if (input.contains('毎週')) {
      return (
        'FREQ=WEEKLY;INTERVAL=1',
        input.replaceFirst('毎週', '').trim(),
      );
    }

    // 毎月
    if (input.contains('毎月')) {
      return (
        'FREQ=MONTHLY',
        input.replaceFirst('毎月', '').trim(),
      );
    }

    // 毎年
    if (input.contains('毎年')) {
      return (
        'FREQ=YEARLY',
        input.replaceFirst('毎年', '').trim(),
      );
    }

    return null;
  }

  // ── Title extraction ──

  static String? _extractTitle(String remaining) {
    // Clean up particles and whitespace
    var title = remaining
        .replaceAll(RegExp(r'^[のにでへをがはと、。\s]+'), '')
        .replaceAll(RegExp(r'[のにでへをがはと、。\s]+$'), '')
        .trim();

    // Remove leading "の" that sometimes remains
    if (title.startsWith('の')) {
      title = title.substring(1).trim();
    }

    return title.isEmpty ? null : title;
  }

  // ── Date helpers ──

  /// Get the next occurrence of a given weekday, starting from tomorrow.
  static DateTime _nextOccurrence(DateTime from, int weekday) {
    var days = weekday - from.weekday;
    if (days <= 0) days += 7;
    return from.add(Duration(days: days));
  }

  /// Get a weekday N weeks ahead.
  /// [weeksAhead] = 0: this week (same or next occurrence),
  /// 1: next week, 2: week after next.
  static DateTime _nextWeekday(
    DateTime from,
    int weekday, {
    required int weeksAhead,
  }) {
    // Find the Monday of the current week
    final currentMonday =
        from.subtract(Duration(days: from.weekday - DateTime.monday));
    final targetMonday =
        currentMonday.add(Duration(days: 7 * weeksAhead));
    final daysFromMonday = weekday - DateTime.monday;
    return targetMonday.add(Duration(days: daysFromMonday));
  }
}

/// Structured result from natural language parsing.
class ParseResult {
  final String? title;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  final String? recurrenceRule;

  const ParseResult({
    this.title,
    this.date,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.recurrenceRule,
  });

  @override
  String toString() {
    return 'ParseResult('
        'title: $title, '
        'date: $date, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'isAllDay: $isAllDay, '
        'location: $location, '
        'recurrenceRule: $recurrenceRule'
        ')';
  }
}
