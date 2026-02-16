/// Japanese national holiday calculator.
///
/// Computes holidays algorithmically (no API needed, works offline).
/// Covers: 固定祝日, ハッピーマンデー, 春分/秋分, 振替休日, 国民の休日.
class JapaneseHolidayService {
  /// Cache: year → {date → name}
  final Map<int, Map<DateTime, String>> _cache = {};

  /// Get holiday name for a date, or null if not a holiday.
  String? getHoliday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final holidays = getHolidaysForYear(d.year);
    return holidays[d];
  }

  /// Get all holidays for a given year.
  Map<DateTime, String> getHolidaysForYear(int year) {
    if (_cache.containsKey(year)) return _cache[year]!;

    final holidays = <DateTime, String>{};

    // ── 固定祝日 ──
    holidays[DateTime(year, 1, 1)] = '元日';
    holidays[DateTime(year, 2, 11)] = '建国記念の日';
    holidays[DateTime(year, 2, 23)] = '天皇誕生日';
    holidays[DateTime(year, 4, 29)] = '昭和の日';
    holidays[DateTime(year, 5, 3)] = '憲法記念日';
    holidays[DateTime(year, 5, 4)] = 'みどりの日';
    holidays[DateTime(year, 5, 5)] = 'こどもの日';
    holidays[DateTime(year, 8, 11)] = '山の日';
    holidays[DateTime(year, 11, 3)] = '文化の日';
    holidays[DateTime(year, 11, 23)] = '勤労感謝の日';

    // ── ハッピーマンデー ──
    holidays[_nthWeekday(year, 1, DateTime.monday, 2)] = '成人の日';
    holidays[_nthWeekday(year, 7, DateTime.monday, 3)] = '海の日';
    holidays[_nthWeekday(year, 9, DateTime.monday, 3)] = '敬老の日';
    holidays[_nthWeekday(year, 10, DateTime.monday, 2)] = 'スポーツの日';

    // ── 春分の日・秋分の日 ──
    holidays[DateTime(year, 3, _vernalEquinoxDay(year))] = '春分の日';
    holidays[DateTime(year, 9, _autumnalEquinoxDay(year))] = '秋分の日';

    // ── 振替休日（日曜が祝日 → 翌平日） ──
    final baseHolidays = Map<DateTime, String>.from(holidays);
    for (final entry in baseHolidays.entries) {
      if (entry.key.weekday == DateTime.sunday) {
        var substitute = entry.key.add(const Duration(days: 1));
        while (holidays.containsKey(substitute)) {
          substitute = substitute.add(const Duration(days: 1));
        }
        holidays[substitute] = '振替休日';
      }
    }

    // ── 国民の休日（祝日に挟まれた平日） ──
    final sortedDates = holidays.keys.toList()..sort();
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final diff = sortedDates[i + 1].difference(sortedDates[i]).inDays;
      if (diff == 2) {
        final between = sortedDates[i].add(const Duration(days: 1));
        if (!holidays.containsKey(between) &&
            between.weekday != DateTime.sunday) {
          holidays[between] = '国民の休日';
        }
      }
    }

    _cache[year] = holidays;
    return holidays;
  }

  /// N番目の特定曜日を求める（例: 1月の第2月曜日）
  DateTime _nthWeekday(int year, int month, int weekday, int n) {
    var date = DateTime(year, month, 1);
    int count = 0;
    while (true) {
      if (date.weekday == weekday) {
        count++;
        if (count == n) return date;
      }
      date = date.add(const Duration(days: 1));
    }
  }

  /// 春分の日の日（3月）
  /// 公式に近い近似式（1980-2099年有効）
  int _vernalEquinoxDay(int year) {
    return (20.8431 + 0.242194 * (year - 1980) - ((year - 1980) ~/ 4))
        .floor();
  }

  /// 秋分の日の日（9月）
  int _autumnalEquinoxDay(int year) {
    return (23.2488 + 0.242194 * (year - 1980) - ((year - 1980) ~/ 4))
        .floor();
  }
}
