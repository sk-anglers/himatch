import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/workplace.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';

// ─── Salary calculation data class ───

class SalaryBreakdown {
  final int basePay;
  final double baseHours;
  final int overtimePay;
  final double overtimeHours;
  final int nightPay;
  final double nightHours;
  final int holidayPay;
  final double holidayHours;
  final int transportCost;
  final int workingDays;
  final int totalPay;

  const SalaryBreakdown({
    required this.basePay,
    required this.baseHours,
    required this.overtimePay,
    required this.overtimeHours,
    required this.nightPay,
    required this.nightHours,
    required this.holidayPay,
    required this.holidayHours,
    required this.transportCost,
    required this.workingDays,
    required this.totalPay,
  });
}

// ─── Local providers for salary screen ───

/// Local workplace list provider (placeholder until Supabase-backed).
final workplacesProvider =
    NotifierProvider<WorkplacesNotifier, List<Workplace>>(
  WorkplacesNotifier.new,
);

class WorkplacesNotifier extends Notifier<List<Workplace>> {
  @override
  List<Workplace> build() => [
        const Workplace(
          id: 'wp-1',
          userId: AppConstants.localUserId,
          name: 'カフェバイト',
          hourlyWage: 1200,
          closingDay: 25,
          transportCost: 500,
          colorHex: 'FF6C5CE7',
        ),
      ];

  void add(Workplace wp) {
    state = [...state, wp];
  }

  void update(Workplace updated) {
    state = [
      for (final wp in state)
        if (wp.id == updated.id) updated else wp,
    ];
  }

  void remove(String id) {
    state = state.where((wp) => wp.id != id).toList();
  }
}

/// Provider to compute salary breakdown for a given month and workplace.
final salaryBreakdownProvider =
    Provider.family<SalaryBreakdown, ({DateTime month, String workplaceId})>(
        (ref, params) {
  final schedules = ref.watch(localSchedulesProvider);
  final workplaces = ref.watch(workplacesProvider);
  final workplace = workplaces.firstWhere(
    (w) => w.id == params.workplaceId,
    orElse: () => workplaces.first,
  );

  final monthStart = DateTime(params.month.year, params.month.month, 1);
  final monthEnd = DateTime(params.month.year, params.month.month + 1, 0, 23, 59);

  final monthSchedules = schedules.where((s) =>
      s.workplaceId == params.workplaceId &&
      s.scheduleType == ScheduleType.shift &&
      !s.startTime.isBefore(monthStart) &&
      !s.startTime.isAfter(monthEnd));

  double baseHours = 0;
  double overtimeHours = 0;
  double nightHours = 0;
  double holidayHours = 0;
  final workDays = <DateTime>{};

  for (final s in monthSchedules) {
    final hours = s.endTime.difference(s.startTime).inMinutes / 60.0;
    workDays.add(DateTime(s.startTime.year, s.startTime.month, s.startTime.day));

    // Simple heuristic: >8h = overtime portion
    final regularHours = hours.clamp(0, 8).toDouble();
    final ot = (hours - 8).clamp(0, double.infinity).toDouble();

    // Night hours: 22:00-05:00 portion
    double nightH = 0;
    for (int h = s.startTime.hour; h < s.endTime.hour; h++) {
      if (h >= 22 || h < 5) nightH += 1;
    }

    // Holiday: Saturday/Sunday
    final isHoliday =
        s.startTime.weekday == DateTime.saturday ||
        s.startTime.weekday == DateTime.sunday;

    if (isHoliday) {
      holidayHours += hours;
    } else {
      baseHours += regularHours;
      overtimeHours += ot;
    }
    nightHours += nightH;
  }

  final basePay = (baseHours * workplace.hourlyWage).round();
  final overtimePay =
      (overtimeHours * workplace.hourlyWage * workplace.overtimeMultiplier)
          .round();
  final nightPay =
      (nightHours * workplace.hourlyWage * (workplace.nightMultiplier - 1))
          .round();
  final holidayPay =
      (holidayHours * workplace.hourlyWage * workplace.holidayMultiplier)
          .round();
  final transport = workplace.transportCost * workDays.length;
  final total = basePay + overtimePay + nightPay + holidayPay + transport;

  return SalaryBreakdown(
    basePay: basePay,
    baseHours: baseHours,
    overtimePay: overtimePay,
    overtimeHours: overtimeHours,
    nightPay: nightPay,
    nightHours: nightHours,
    holidayPay: holidayPay,
    holidayHours: holidayHours,
    transportCost: transport,
    workingDays: workDays.length,
    totalPay: total,
  );
});

// ─── Tax wall thresholds ───

class _TaxWall {
  final String label;
  final int threshold;
  final String description;
  final Color color;

  const _TaxWall(this.label, this.threshold, this.description, this.color);
}

const _taxWalls = [
  _TaxWall('103万円の壁', 1030000, '所得税が発生します', AppColors.warning),
  _TaxWall('106万円の壁', 1060000, '社会保険料の負担が発生する場合があります', AppColors.warning),
  _TaxWall('130万円の壁', 1300000, '扶養から外れ、社会保険に加入が必要です', AppColors.error),
  _TaxWall('150万円の壁', 1500000, '配偶者特別控除が段階的に減額されます', AppColors.error),
];

// ─── Screen ───

class SalarySummaryScreen extends ConsumerStatefulWidget {
  const SalarySummaryScreen({super.key});

  @override
  ConsumerState<SalarySummaryScreen> createState() =>
      _SalarySummaryScreenState();
}

class _SalarySummaryScreenState extends ConsumerState<SalarySummaryScreen> {
  late DateTime _selectedMonth;
  String? _selectedWorkplaceId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final workplaces = ref.watch(workplacesProvider);

    if (workplaces.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('給与明細')),
        body: const Center(
          child: Text(
            '勤務先が登録されていません。\n設定から勤務先を追加してください。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    final workplaceId = _selectedWorkplaceId ?? workplaces.first.id;
    final salary = ref.watch(salaryBreakdownProvider(
      (month: _selectedMonth, workplaceId: workplaceId),
    ));

    // Estimate yearly income (simple: current month * 12)
    final estimatedYearly = salary.totalPay * 12;

    return Scaffold(
      appBar: AppBar(title: const Text('給与明細')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            _buildMonthSelector(),
            const SizedBox(height: 12),

            // Workplace selector
            if (workplaces.length > 1) ...[
              _buildWorkplaceSelector(workplaces, workplaceId),
              const SizedBox(height: 16),
            ],

            // Total summary card
            _buildTotalCard(salary),
            const SizedBox(height: 16),

            // Breakdown
            _buildBreakdownSection(salary),
            const SizedBox(height: 12),

            // Working days
            _buildInfoRow('出勤日数', '${salary.workingDays}日'),
            const SizedBox(height: 20),

            // Tax wall warnings
            ..._buildTaxWallWarnings(estimatedYearly),

            const SizedBox(height: 24),

            // Export buttons
            _buildExportButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textPrimary,
        ),
        Text(
          '${_selectedMonth.year}年${_selectedMonth.month}月',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildWorkplaceSelector(
      List<Workplace> workplaces, String currentId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: currentId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        items: workplaces.map((wp) {
          return DropdownMenuItem(
            value: wp.id,
            child: Text(wp.name),
          );
        }).toList(),
        onChanged: (id) {
          if (id != null) {
            setState(() => _selectedWorkplaceId = id);
          }
        },
      ),
    );
  }

  Widget _buildTotalCard(SalaryBreakdown salary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '総支給額',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${_formatNumber(salary.totalPay)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(SalaryBreakdown salary) {
    final items = [
      _BreakdownItem(
        '基本給',
        salary.basePay,
        '${salary.baseHours.toStringAsFixed(1)}時間',
        AppColors.primary,
      ),
      _BreakdownItem(
        '残業手当',
        salary.overtimePay,
        '${salary.overtimeHours.toStringAsFixed(1)}時間',
        AppColors.warning,
      ),
      _BreakdownItem(
        '深夜手当',
        salary.nightPay,
        '${salary.nightHours.toStringAsFixed(1)}時間',
        const Color(0xFF6C5CE7),
      ),
      _BreakdownItem(
        '休日手当',
        salary.holidayPay,
        '${salary.holidayHours.toStringAsFixed(1)}時間',
        AppColors.error,
      ),
      _BreakdownItem(
        '交通費',
        salary.transportCost,
        null,
        AppColors.success,
      ),
    ];

    final maxAmount =
        items.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '内訳',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildBreakdownBar(item, maxAmount)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownBar(_BreakdownItem item, int maxAmount) {
    final ratio = maxAmount > 0 ? item.amount / maxAmount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.detail != null) ...[
                const SizedBox(width: 6),
                Text(
                  '(${item.detail})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '¥${_formatNumber(item.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(item.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaxWallWarnings(int estimatedYearly) {
    final warnings = <Widget>[];
    for (final wall in _taxWalls) {
      final remaining = wall.threshold - estimatedYearly;
      if (remaining > 0 && remaining < 200000) {
        // Approaching the wall (within 20万円)
        warnings.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: wall.color.withValues(alpha: 0.1),
              border: Border.all(color: wall.color.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: wall.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wall.label}まであと ¥${_formatNumber(remaining)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: wall.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wall.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (remaining <= 0) {
        // Already exceeded
        warnings.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wall.label}を超過しています',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wall.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return warnings;
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF出力は今後実装予定です')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF出力'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV出力は今後実装予定です')),
              );
            },
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('CSV出力'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _BreakdownItem {
  final String label;
  final int amount;
  final String? detail;
  final Color color;

  const _BreakdownItem(this.label, this.amount, this.detail, this.color);
}
