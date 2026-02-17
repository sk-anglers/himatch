/// Parse and expand iCalendar RRULE strings into date occurrences.
///
/// Supports: DAILY, WEEKLY, MONTHLY (by monthday or by day), YEARLY
/// With: INTERVAL, COUNT, UNTIL, BYDAY
class RRuleParser {
  // Weekday name → DateTime.weekday value
  static const Map<String, int> _weekdayMap = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  // Reverse: DateTime.weekday → RRULE abbreviation
  static const Map<int, String> _weekdayReverseMap = {
    DateTime.monday: 'MO',
    DateTime.tuesday: 'TU',
    DateTime.wednesday: 'WE',
    DateTime.thursday: 'TH',
    DateTime.friday: 'FR',
    DateTime.saturday: 'SA',
    DateTime.sunday: 'SU',
  };

  // Japanese weekday names
  static const Map<int, String> _weekdayJa = {
    DateTime.monday: '月曜日',
    DateTime.tuesday: '火曜日',
    DateTime.wednesday: '水曜日',
    DateTime.thursday: '木曜日',
    DateTime.friday: '金曜日',
    DateTime.saturday: '土曜日',
    DateTime.sunday: '日曜日',
  };

  /// Parse RRULE string and return expanded dates within a range.
  ///
  /// [rrule] - The RRULE string (e.g. "FREQ=WEEKLY;BYDAY=MO,WE;INTERVAL=2")
  /// [start] - The event start date (DTSTART)
  /// [rangeStart] - Start of the expansion range
  /// [rangeEnd] - End of the expansion range
  static List<DateTime> expand(
    String rrule,
    DateTime start,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final params = _parseParams(rrule);
    final freq = params['FREQ'] ?? '';
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;
    final count = int.tryParse(params['COUNT'] ?? '') ?? -1;
    final until = params['UNTIL'] != null ? _parseDate(params['UNTIL']!) : null;
    final byDay = params['BYDAY']?.split(',') ?? [];
    final byMonthDay =
        int.tryParse(params['BYMONTHDAY'] ?? '') ?? start.day;

    final effectiveEnd = until != null && until.isBefore(rangeEnd)
        ? until
        : rangeEnd;

    final results = <DateTime>[];
    int generated = 0;

    switch (freq) {
      case 'DAILY':
        var current = start;
        while (!current.isAfter(effectiveEnd)) {
          if (!current.isBefore(rangeStart)) {
            results.add(current);
            generated++;
            if (count > 0 && generated >= count) break;
          }
          current = current.add(Duration(days: interval));
        }

      case 'WEEKLY':
        if (byDay.isEmpty) {
          // No BYDAY specified — recur on the same weekday as start
          var current = start;
          while (!current.isAfter(effectiveEnd)) {
            if (!current.isBefore(rangeStart)) {
              results.add(current);
              generated++;
              if (count > 0 && generated >= count) break;
            }
            current = current.add(Duration(days: 7 * interval));
          }
        } else {
          // BYDAY specified — expand within each week
          final targetWeekdays = byDay
              .map((d) => _weekdayMap[d.trim().toUpperCase()])
              .whereType<int>()
              .toList()
            ..sort();

          // Find the Monday of the start week
          var weekStart =
              start.subtract(Duration(days: start.weekday - DateTime.monday));

          while (!weekStart.isAfter(effectiveEnd)) {
            for (final wd in targetWeekdays) {
              final candidate =
                  weekStart.add(Duration(days: wd - DateTime.monday));
              if (candidate.isBefore(start)) continue;
              if (candidate.isAfter(effectiveEnd)) break;
              if (!candidate.isBefore(rangeStart)) {
                results.add(candidate);
                generated++;
                if (count > 0 && generated >= count) break;
              }
            }
            if (count > 0 && generated >= count) break;
            weekStart = weekStart.add(Duration(days: 7 * interval));
          }
        }

      case 'MONTHLY':
        if (byDay.isNotEmpty) {
          // MONTHLY by day (e.g., BYDAY=2MO → 2nd Monday)
          for (final bd in byDay) {
            final parsed = _parseByDayWithOrdinal(bd.trim());
            if (parsed == null) continue;
            final ordinal = parsed.$1;
            final weekday = parsed.$2;

            var current = DateTime(start.year, start.month);
            while (!current.isAfter(effectiveEnd)) {
              final candidate = _nthWeekdayOfMonth(
                current.year,
                current.month,
                weekday,
                ordinal,
              );
              if (candidate != null &&
                  !candidate.isBefore(start) &&
                  !candidate.isAfter(effectiveEnd) &&
                  !candidate.isBefore(rangeStart)) {
                results.add(candidate);
                generated++;
                if (count > 0 && generated >= count) break;
              }
              // Advance by interval months
              current = _addMonths(current, interval);
            }
          }
          results.sort();
        } else {
          // MONTHLY by monthday
          var current = DateTime(start.year, start.month, byMonthDay);
          if (current.isBefore(start)) {
            current = _addMonths(current, interval);
          }
          while (!current.isAfter(effectiveEnd)) {
            // Clamp to last day of month if needed
            final clamped = _clampDay(current.year, current.month, byMonthDay);
            if (!clamped.isBefore(rangeStart)) {
              results.add(clamped);
              generated++;
              if (count > 0 && generated >= count) break;
            }
            current = _addMonths(current, interval);
          }
        }

      case 'YEARLY':
        var current = start;
        while (!current.isAfter(effectiveEnd)) {
          if (!current.isBefore(rangeStart)) {
            results.add(current);
            generated++;
            if (count > 0 && generated >= count) break;
          }
          current = DateTime(
            current.year + interval,
            current.month,
            current.day,
          );
        }
    }

    return results;
  }

  /// Build an RRULE string from parameters.
  ///
  /// [freq] - Frequency: DAILY, WEEKLY, MONTHLY, YEARLY
  /// [interval] - Recurrence interval (default 1)
  /// [count] - Maximum number of occurrences
  /// [until] - End date for recurrence
  /// [byDay] - List of day abbreviations (e.g. ['MO', 'WE', '2MO'])
  static String build({
    required String freq,
    int interval = 1,
    int? count,
    DateTime? until,
    List<String>? byDay,
  }) {
    final parts = <String>['FREQ=${freq.toUpperCase()}'];

    if (interval > 1) {
      parts.add('INTERVAL=$interval');
    }
    if (byDay != null && byDay.isNotEmpty) {
      parts.add('BYDAY=${byDay.join(',')}');
    }
    if (count != null) {
      parts.add('COUNT=$count');
    }
    if (until != null) {
      final y = until.year.toString().padLeft(4, '0');
      final m = until.month.toString().padLeft(2, '0');
      final d = until.day.toString().padLeft(2, '0');
      parts.add('UNTIL=$y$m${d}T235959Z');
    }

    return parts.join(';');
  }

  /// Human-readable description in Japanese.
  static String describe(String rrule) {
    final params = _parseParams(rrule);
    final freq = params['FREQ'] ?? '';
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;
    final byDay = params['BYDAY']?.split(',') ?? [];
    final count = int.tryParse(params['COUNT'] ?? '');
    final until =
        params['UNTIL'] != null ? _parseDate(params['UNTIL']!) : null;

    final buffer = StringBuffer();

    switch (freq) {
      case 'DAILY':
        if (interval == 1) {
          buffer.write('毎日');
        } else {
          buffer.write('$interval日ごと');
        }

      case 'WEEKLY':
        if (interval == 1) {
          buffer.write('毎週');
        } else {
          buffer.write('$interval週間ごと');
        }
        if (byDay.isNotEmpty) {
          final dayNames = byDay.map((d) {
            final parsed = _parseByDayWithOrdinal(d.trim());
            if (parsed != null && parsed.$1 > 0) {
              return '第${parsed.$1}${_weekdayJa[parsed.$2] ?? d}';
            }
            final wd = _weekdayMap[d.trim().toUpperCase()];
            return wd != null ? _weekdayJa[wd]! : d;
          }).toList();
          buffer.write(dayNames.join('・'));
        }

      case 'MONTHLY':
        if (interval == 1) {
          buffer.write('毎月');
        } else {
          buffer.write('$intervalヶ月ごと');
        }
        if (byDay.isNotEmpty) {
          final dayNames = byDay.map((d) {
            final parsed = _parseByDayWithOrdinal(d.trim());
            if (parsed != null) {
              return '第${parsed.$1}${_weekdayJa[parsed.$2] ?? d}';
            }
            return d;
          }).toList();
          buffer.write(dayNames.join('・'));
        }

      case 'YEARLY':
        if (interval == 1) {
          buffer.write('毎年');
        } else {
          buffer.write('$interval年ごと');
        }
    }

    if (count != null) {
      buffer.write(' ($count回まで)');
    }
    if (until != null) {
      buffer.write(
        ' (${until.year}/${until.month}/${until.day}まで)',
      );
    }

    return buffer.toString();
  }

  // ── Private helpers ──

  /// Parse RRULE parameters into a key-value map.
  static Map<String, String> _parseParams(String rrule) {
    // Strip "RRULE:" prefix if present
    var rule = rrule;
    if (rule.toUpperCase().startsWith('RRULE:')) {
      rule = rule.substring(6);
    }

    final params = <String, String>{};
    for (final part in rule.split(';')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        params[part.substring(0, idx).toUpperCase()] =
            part.substring(idx + 1);
      }
    }
    return params;
  }

  /// Parse a UNTIL date string (e.g. "20260315T235959Z" or "20260315").
  static DateTime _parseDate(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    final year = int.parse(digits.substring(0, 4));
    final month = int.parse(digits.substring(4, 6));
    final day = int.parse(digits.substring(6, 8));
    return DateTime(year, month, day);
  }

  /// Parse BYDAY value with optional ordinal (e.g. "2MO" → (2, Monday)).
  /// Returns null if invalid.
  static (int, int)? _parseByDayWithOrdinal(String value) {
    final match = RegExp(r'^(-?\d+)?([A-Z]{2})$').firstMatch(value.toUpperCase());
    if (match == null) return null;
    final ordinal = int.tryParse(match.group(1) ?? '0') ?? 0;
    final weekday = _weekdayMap[match.group(2)];
    if (weekday == null) return null;
    return (ordinal, weekday);
  }

  /// Get the Nth weekday of a month (e.g., 2nd Monday of March 2026).
  /// Returns null if ordinal is out of range.
  static DateTime? _nthWeekdayOfMonth(
    int year,
    int month,
    int weekday,
    int n,
  ) {
    if (n <= 0) return null;
    var date = DateTime(year, month, 1);
    int count = 0;
    while (date.month == month) {
      if (date.weekday == weekday) {
        count++;
        if (count == n) return date;
      }
      date = date.add(const Duration(days: 1));
    }
    return null; // N exceeds available weekdays in month
  }

  /// Add months, clamping the day to the last valid day.
  static DateTime _addMonths(DateTime date, int months) {
    final newMonth = date.month + months;
    final year = date.year + (newMonth - 1) ~/ 12;
    final month = ((newMonth - 1) % 12) + 1;
    final maxDay = _daysInMonth(year, month);
    return DateTime(year, month, date.day > maxDay ? maxDay : date.day);
  }

  /// Clamp day to valid range for given year/month.
  static DateTime _clampDay(int year, int month, int day) {
    final maxDay = _daysInMonth(year, month);
    return DateTime(year, month, day > maxDay ? maxDay : day);
  }

  /// Number of days in a given month.
  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get RRULE weekday abbreviation from DateTime.weekday.
  static String? weekdayToRRule(int weekday) => _weekdayReverseMap[weekday];
}
