import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/workplace.dart';
import 'package:uuid/uuid.dart';

/// Local workplace state for offline-first development.
///
/// Manages the list of workplaces (part-time jobs) for salary calculation.
final workplacesProvider =
    NotifierProvider<WorkplacesNotifier, List<Workplace>>(
  WorkplacesNotifier.new,
);

/// Notifier that manages workplace (part-time job) entries.
class WorkplacesNotifier extends Notifier<List<Workplace>> {
  static const _uuid = Uuid();

  @override
  List<Workplace> build() => [];

  /// Add a new workplace.
  void addWorkplace({
    required String name,
    required int hourlyWage,
    int closingDay = 25,
    double overtimeMultiplier = 1.25,
    double nightMultiplier = 1.25,
    double holidayMultiplier = 1.35,
    int transportCost = 0,
    String? colorHex,
  }) {
    final workplace = Workplace(
      id: _uuid.v4(),
      userId: AppConstants.localUserId,
      name: name,
      hourlyWage: hourlyWage,
      closingDay: closingDay,
      overtimeMultiplier: overtimeMultiplier,
      nightMultiplier: nightMultiplier,
      holidayMultiplier: holidayMultiplier,
      transportCost: transportCost,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );
    state = [...state, workplace];
  }

  /// Update an existing workplace.
  void updateWorkplace(Workplace updated) {
    state = [
      for (final w in state)
        if (w.id == updated.id) updated else w,
    ];
  }

  /// Remove a workplace by ID.
  void removeWorkplace(String id) {
    state = state.where((w) => w.id != id).toList();
  }
}

/// Monthly salary report for a specific workplace and month.
///
/// Contains total hours worked, base salary, transport allowance, and shift count.
class SalaryReport {
  final String workplaceId;
  final int year;
  final int month;
  final double totalHours;
  final int baseSalary;
  final int transportAllowance;
  final int totalSalary;
  final int shiftCount;

  const SalaryReport({
    required this.workplaceId,
    required this.year,
    required this.month,
    required this.totalHours,
    required this.baseSalary,
    required this.transportAllowance,
    required this.totalSalary,
    required this.shiftCount,
  });
}

/// Calculate monthly salary for a workplace.
///
/// Uses the workplace's closing day to determine the pay period.
/// For example, closingDay=25 means the period is the 26th of the previous
/// month through the 25th of the current month.
final monthlySalaryProvider = Provider.family<SalaryReport?,
    ({String workplaceId, int year, int month})>((ref, params) {
  final workplaces = ref.watch(workplacesProvider);
  final schedules = ref.watch(localSchedulesProvider);

  final workplace = workplaces
      .where((w) => w.id == params.workplaceId)
      .firstOrNull;
  if (workplace == null) return null;

  // Calculate pay period based on closing day
  final closingDay = workplace.closingDay;
  late final DateTime periodStart;
  late final DateTime periodEnd;

  if (params.month == 1) {
    periodStart = DateTime(params.year - 1, 12, closingDay + 1);
  } else {
    periodStart = DateTime(params.year, params.month - 1, closingDay + 1);
  }
  periodEnd = DateTime(params.year, params.month, closingDay, 23, 59, 59);

  // Filter shift schedules for this workplace within the pay period
  final shifts = schedules.where((s) =>
      s.workplaceId == params.workplaceId &&
      s.scheduleType == ScheduleType.shift &&
      !s.startTime.isBefore(periodStart) &&
      !s.startTime.isAfter(periodEnd));

  double totalHours = 0;
  for (final shift in shifts) {
    final hours = shift.endTime.difference(shift.startTime).inMinutes / 60.0;
    totalHours += hours;
  }

  final shiftCount = shifts.length;
  final baseSalary = (totalHours * workplace.hourlyWage).round();
  final transportAllowance = shiftCount * workplace.transportCost;
  final totalSalary = baseSalary + transportAllowance;

  return SalaryReport(
    workplaceId: params.workplaceId,
    year: params.year,
    month: params.month,
    totalHours: totalHours,
    baseSalary: baseSalary,
    transportAllowance: transportAllowance,
    totalSalary: totalSalary,
    shiftCount: shiftCount,
  );
});

/// Calculate yearly total salary for a workplace.
///
/// Sums monthly salary reports for all 12 months of the given year.
final yearlySalaryProvider =
    Provider.family<int, ({String workplaceId, int year})>((ref, params) {
  int total = 0;
  for (int month = 1; month <= 12; month++) {
    final report = ref.watch(monthlySalaryProvider((
      workplaceId: params.workplaceId,
      year: params.year,
      month: month,
    )));
    total += report?.totalSalary ?? 0;
  }
  return total;
});

/// Tax wall thresholds relevant for Japanese part-time workers.
///
/// Common thresholds: 1,030,000 yen (income tax), 1,060,000 yen (social insurance),
/// 1,300,000 yen (spousal deduction limit).
class TaxWallWarning {
  final String name;
  final int threshold;
  final int currentTotal;
  final double percentageUsed;
  final String description;

  const TaxWallWarning({
    required this.name,
    required this.threshold,
    required this.currentTotal,
    required this.percentageUsed,
    required this.description,
  });

  bool get isExceeded => currentTotal >= threshold;
  bool get isApproaching => percentageUsed >= 0.8;
}

/// Check tax wall warnings for a workplace in a given year.
///
/// Returns warnings for each tax threshold, indicating how close
/// the user is to exceeding the limit.
final taxWallWarningsProvider = Provider.family<List<TaxWallWarning>,
    ({String workplaceId, int year})>((ref, params) {
  final yearlyTotal = ref.watch(yearlySalaryProvider((
    workplaceId: params.workplaceId,
    year: params.year,
  )));

  const thresholds = [
    (name: '103万円の壁', threshold: 1030000, desc: '所得税が発生する金額です'),
    (name: '106万円の壁', threshold: 1060000, desc: '社会保険加入の目安です（条件あり）'),
    (name: '130万円の壁', threshold: 1300000, desc: '扶養から外れる金額です'),
    (name: '150万円の壁', threshold: 1500000, desc: '配偶者特別控除が段階的に減少します'),
  ];

  return thresholds.map((t) {
    final percentage = yearlyTotal / t.threshold;
    return TaxWallWarning(
      name: t.name,
      threshold: t.threshold,
      currentTotal: yearlyTotal,
      percentageUsed: percentage,
      description: t.desc,
    );
  }).toList();
});
