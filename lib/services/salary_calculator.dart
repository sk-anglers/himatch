import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/workplace.dart';
import 'holiday_service.dart';

/// Calculate salary from shift schedules.
///
/// Supports regular pay, overtime (>8h/day at 1.25x), night (22:00-05:00 at
/// 1.25x), holiday pay (1.35x), and transport cost per work day.
class SalaryCalculator {
  static final JapaneseHolidayService _holidayService =
      JapaneseHolidayService();

  /// Calculate monthly salary for a workplace.
  ///
  /// [shifts] - All shifts for the given month
  /// [workplace] - Workplace with wage settings
  /// [year] - Target year
  /// [month] - Target month
  /// [holidays] - Optional override for holiday dates; if null, computed
  static SalaryReport calculateMonthly({
    required List<Schedule> shifts,
    required Workplace workplace,
    required int year,
    required int month,
    Map<DateTime, String>? holidays,
  }) {
    final effectiveHolidays =
        holidays ?? _holidayService.getHolidaysForYear(year);

    int totalRegularMinutes = 0;
    int totalOvertimeMinutes = 0;
    int totalNightMinutes = 0;
    int totalHolidayMinutes = 0;
    int workDays = 0;

    // Filter shifts to the target month
    final monthlyShifts = shifts.where((s) {
      return s.startTime.year == year && s.startTime.month == month;
    }).toList();

    // Group shifts by date to calculate daily totals
    final shiftsByDate = <DateTime, List<Schedule>>{};
    for (final shift in monthlyShifts) {
      final dateKey = DateTime(
        shift.startTime.year,
        shift.startTime.month,
        shift.startTime.day,
      );
      shiftsByDate.putIfAbsent(dateKey, () => []).add(shift);
    }

    for (final entry in shiftsByDate.entries) {
      final dateKey = entry.key;
      final dayShifts = entry.value;
      workDays++;

      final isHoliday = effectiveHolidays.containsKey(dateKey) ||
          dateKey.weekday == DateTime.sunday;

      int dayTotalMinutes = 0;
      int dayNightMinutes = 0;

      for (final shift in dayShifts) {
        final shiftMinutes =
            shift.endTime.difference(shift.startTime).inMinutes;
        dayTotalMinutes += shiftMinutes;

        // Calculate night minutes (22:00-05:00)
        dayNightMinutes +=
            _calculateNightMinutes(shift.startTime, shift.endTime);
      }

      // Overtime: minutes exceeding 8 hours (480 minutes) per day
      final overtimeThreshold = 480; // 8 hours in minutes
      int dayOvertimeMinutes = 0;
      int dayRegularMinutes = dayTotalMinutes;

      if (dayTotalMinutes > overtimeThreshold) {
        dayOvertimeMinutes = dayTotalMinutes - overtimeThreshold;
        dayRegularMinutes = overtimeThreshold;
      }

      if (isHoliday) {
        // All minutes on holidays count as holiday minutes
        totalHolidayMinutes += dayTotalMinutes;
      } else {
        // Night minutes are a subset of total; ensure regular never goes negative
        final dayRegularNonNight =
            (dayRegularMinutes - dayNightMinutes).clamp(0, dayRegularMinutes);
        totalRegularMinutes += dayRegularNonNight;
        totalOvertimeMinutes += dayOvertimeMinutes;
        totalNightMinutes += dayNightMinutes;
      }
    }

    // Calculate pay
    final hourlyWage = workplace.hourlyWage;
    final wagePerMinute = hourlyWage / 60.0;

    final regularPay = (wagePerMinute * totalRegularMinutes).round();
    final overtimePay =
        (wagePerMinute * workplace.overtimeMultiplier * totalOvertimeMinutes)
            .round();
    final nightPay =
        (wagePerMinute * workplace.nightMultiplier * totalNightMinutes).round();
    final holidayPay =
        (wagePerMinute * workplace.holidayMultiplier * totalHolidayMinutes)
            .round();
    final transportCost = workplace.transportCost * workDays;

    return SalaryReport(
      regularMinutes: totalRegularMinutes,
      overtimeMinutes: totalOvertimeMinutes,
      nightMinutes: totalNightMinutes,
      holidayMinutes: totalHolidayMinutes,
      regularPay: regularPay,
      overtimePay: overtimePay,
      nightPay: nightPay,
      holidayPay: holidayPay,
      transportCost: transportCost,
      totalPay: regularPay + overtimePay + nightPay + holidayPay + transportCost,
      workDays: workDays,
    );
  }

  /// Calculate yearly total salary across all months.
  static YearlySalaryReport calculateYearly({
    required List<Schedule> shifts,
    required Workplace workplace,
    required int year,
    Map<DateTime, String>? holidays,
  }) {
    final monthlyReports = <int, SalaryReport>{};
    int yearlyTotal = 0;

    for (int month = 1; month <= 12; month++) {
      final report = calculateMonthly(
        shifts: shifts,
        workplace: workplace,
        year: year,
        month: month,
        holidays: holidays,
      );
      monthlyReports[month] = report;
      yearlyTotal += report.totalPay;
    }

    return YearlySalaryReport(
      year: year,
      monthlyReports: monthlyReports,
      yearlyTotal: yearlyTotal,
      taxWallWarnings: checkTaxWalls(yearlyTotal),
    );
  }

  /// Check tax wall thresholds and return relevant warnings.
  ///
  /// Japanese tax walls for part-time workers:
  /// - 103万円: 所得税 (income tax starts)
  /// - 106万円: 社保一部 (partial social insurance at large employers)
  /// - 123万円: 新基準 (new standard, effective 2025+)
  /// - 130万円: 社保 (social insurance for all)
  /// - 150万円: 配偶者控除 (spousal deduction fully lost)
  static List<TaxWallWarning> checkTaxWalls(int yearlyIncome) {
    final walls = <TaxWallWarning>[];

    final thresholds = [
      (
        name: '103万の壁',
        threshold: 1030000,
        description: '所得税が発生します。年収103万円を超えると所得税の課税対象になります。',
      ),
      (
        name: '106万の壁',
        threshold: 1060000,
        description:
            '大企業（従業員101人以上）で社会保険の加入対象になります。手取りが一時的に減る可能性があります。',
      ),
      (
        name: '123万の壁',
        threshold: 1230000,
        description: '2025年税制改正による新しい基準です。基礎控除・給与所得控除の引き上げに対応しています。',
      ),
      (
        name: '130万の壁',
        threshold: 1300000,
        description:
            '社会保険の扶養から外れます。健康保険・年金を自分で負担する必要があり、手取りが大きく減る可能性があります。',
      ),
      (
        name: '150万の壁',
        threshold: 1500000,
        description: '配偶者特別控除が段階的に減少し始めます。配偶者の税負担が増える可能性があります。',
      ),
    ];

    for (final wall in thresholds) {
      walls.add(TaxWallWarning(
        name: wall.name,
        threshold: wall.threshold,
        current: yearlyIncome,
        description: wall.description,
      ));
    }

    return walls;
  }

  /// Calculate night-time minutes (22:00-05:00) within a shift.
  static int _calculateNightMinutes(DateTime start, DateTime end) {
    int nightMinutes = 0;
    final date = DateTime(start.year, start.month, start.day);

    // Night period 1: 00:00 - 05:00 on the start day
    final nightEnd1 = date.add(const Duration(hours: 5));
    // Night period 2: 22:00 - 24:00 on the start day
    final nightStart2 = date.add(const Duration(hours: 22));
    final nightEnd2 = date.add(const Duration(hours: 24));

    // Check overlap with 00:00-05:00
    nightMinutes += _overlapMinutes(start, end, date, nightEnd1);

    // Check overlap with 22:00-24:00
    nightMinutes += _overlapMinutes(start, end, nightStart2, nightEnd2);

    // If shift extends past midnight, check 00:00-05:00 of next day
    if (end.isAfter(nightEnd2)) {
      final nextDate = date.add(const Duration(days: 1));
      final nextNightEnd = nextDate.add(const Duration(hours: 5));
      nightMinutes += _overlapMinutes(start, end, nightEnd2, nextNightEnd);
    }

    return nightMinutes;
  }

  /// Calculate overlap in minutes between two time ranges.
  static int _overlapMinutes(
    DateTime s1,
    DateTime e1,
    DateTime s2,
    DateTime e2,
  ) {
    final overlapStart = s1.isAfter(s2) ? s1 : s2;
    final overlapEnd = e1.isBefore(e2) ? e1 : e2;
    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart).inMinutes;
    }
    return 0;
  }
}

/// Monthly salary report.
class SalaryReport {
  final int regularMinutes;
  final int overtimeMinutes;
  final int nightMinutes;
  final int holidayMinutes;
  final int regularPay;
  final int overtimePay;
  final int nightPay;
  final int holidayPay;
  final int transportCost;
  final int totalPay;
  final int workDays;

  const SalaryReport({
    required this.regularMinutes,
    required this.overtimeMinutes,
    required this.nightMinutes,
    required this.holidayMinutes,
    required this.regularPay,
    required this.overtimePay,
    required this.nightPay,
    required this.holidayPay,
    required this.transportCost,
    required this.totalPay,
    required this.workDays,
  });

  /// Total worked minutes (all categories).
  int get totalMinutes =>
      regularMinutes + overtimeMinutes + nightMinutes + holidayMinutes;

  /// Format minutes as "Xh Ym" string.
  static String formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h時間$m分' : '$h時間';
  }

  /// Format yen amount with comma separator.
  static String formatYen(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '$buffer円';
  }
}

/// Yearly salary summary with monthly breakdown.
class YearlySalaryReport {
  final int year;
  final Map<int, SalaryReport> monthlyReports;
  final int yearlyTotal;
  final List<TaxWallWarning> taxWallWarnings;

  const YearlySalaryReport({
    required this.year,
    required this.monthlyReports,
    required this.yearlyTotal,
    required this.taxWallWarnings,
  });

  /// Warnings for walls the current income is approaching or exceeding.
  List<TaxWallWarning> get activeWarnings {
    return taxWallWarnings.where((w) {
      // Warn if within 80% of threshold or exceeding
      return yearlyTotal >= (w.threshold * 0.8);
    }).toList();
  }
}

/// Tax wall threshold warning.
class TaxWallWarning {
  final String name;
  final int threshold;
  final int current;
  final String description;

  const TaxWallWarning({
    required this.name,
    required this.threshold,
    required this.current,
    required this.description,
  });

  /// Whether the current income exceeds this wall.
  bool get isExceeded => current > threshold;

  /// Whether the current income is approaching (within 90% of threshold).
  bool get isApproaching => current >= (threshold * 0.9) && !isExceeded;

  /// Remaining amount before hitting the wall.
  int get remaining => threshold - current;

  /// Progress ratio (0.0-1.0+).
  double get ratio => current / threshold;
}
