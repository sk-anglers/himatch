import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/group/presentation/widgets/shift_list_row.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// メンバーのシフトを横列、日付を縦列に並べたリスト型カレンダー。
class ShiftListCalendarScreen extends ConsumerStatefulWidget {
  final Group group;

  const ShiftListCalendarScreen({super.key, required this.group});

  @override
  ConsumerState<ShiftListCalendarScreen> createState() =>
      _ShiftListCalendarScreenState();
}

class _ShiftListCalendarScreenState
    extends ConsumerState<ShiftListCalendarScreen> {
  bool _showTimeMode = false;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 13)); // 2週間表示
  }

  @override
  Widget build(BuildContext context) {
    final membersMap = ref.watch(localGroupMembersProvider);
    final members = membersMap[widget.group.id] ?? [];
    final mySchedules = ref.watch(localSchedulesProvider);
    final shiftTypeMap = ref.watch(shiftTypeMapProvider);

    // メンバーごとのスケジュールMap
    final memberSchedules = <String, List<Schedule>>{};
    for (final member in members) {
      if (member.userId == AppConstants.localUserId) {
        memberSchedules[member.userId] = mySchedules;
      } else {
        memberSchedules[member.userId] =
            _generateDemoSchedules(member.userId, shiftTypeMap);
      }
    }

    // メンバーカラー
    const memberColors = [
      AppColors.primary,
      AppColors.secondary,
      Color(0xFF00B894),
      Color(0xFFF39C12),
      Color(0xFF3498DB),
      Color(0xFFE91E63),
      Color(0xFF009688),
      Color(0xFF795548),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} シフト一覧'),
        actions: [
          // 表示モード切替
          IconButton(
            icon: Icon(_showTimeMode ? Icons.schedule : Icons.badge),
            tooltip: _showTimeMode ? 'シフト名表示' : '時間表示',
            onPressed: () => setState(() => _showTimeMode = !_showTimeMode),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _endDate.difference(_startDate).inDays + 1,
        itemBuilder: (context, dayIndex) {
          final day = _startDate.add(Duration(days: dayIndex));
          final isToday = _isToday(day);
          final isWeekend = day.weekday == DateTime.saturday ||
              day.weekday == DateTime.sunday;

          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primaryLight.withValues(alpha: 0.1)
                  : isWeekend
                      ? AppColors.surfaceVariant.withValues(alpha: 0.5)
                      : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日付ヘッダー
                Row(
                  children: [
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppDateUtils.formatMonthDayWeek(day),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        AppDateUtils.formatMonthDayWeek(day),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isWeekend
                              ? (day.weekday == DateTime.sunday
                                  ? AppColors.error
                                  : AppColors.primary)
                              : AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // メンバーシフト行
                ...List.generate(members.length, (memberIndex) {
                  final member = members[memberIndex];
                  final color = memberIndex < memberColors.length
                      ? memberColors[memberIndex]
                      : AppColors.textHint;
                  final name = member.userId == AppConstants.localUserId
                      ? 'あなた'
                      : member.nickname ?? 'メンバー${memberIndex + 1}';

                  final daySchedules =
                      _getSchedulesForDay(day, memberSchedules[member.userId] ?? []);

                  return ShiftListRow(
                    memberName: name,
                    memberColor: color,
                    schedules: daySchedules,
                    shiftTypeMap: shiftTypeMap,
                    showTimeMode: _showTimeMode,
                  );
                }),
                const Divider(height: 1),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  List<Schedule> _getSchedulesForDay(DateTime day, List<Schedule> schedules) {
    final targetDate = DateTime(day.year, day.month, day.day);
    return schedules.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return d == targetDate;
    }).toList();
  }

  /// デモ用: 他メンバーにランダムシフトを生成
  List<Schedule> _generateDemoSchedules(
    String userId,
    Map<String, ShiftType> shiftTypeMap,
  ) {
    final schedules = <Schedule>[];
    final shiftTypeIds = shiftTypeMap.keys.toList();
    if (shiftTypeIds.isEmpty) return schedules;

    for (var i = 0; i < 14; i++) {
      final day = _startDate.add(Duration(days: i));
      final hash = userId.hashCode + i * 31;
      // ~60%の確率でシフトあり
      if (hash % 5 < 3) {
        final stId = shiftTypeIds[hash.abs() % shiftTypeIds.length];
        final st = shiftTypeMap[stId]!;
        schedules.add(Schedule(
          id: 'demo-$userId-$i',
          userId: userId,
          title: st.name,
          scheduleType: st.isOff ? ScheduleType.free : ScheduleType.shift,
          startTime: DateTime(day.year, day.month, day.day, 8),
          endTime: DateTime(day.year, day.month, day.day, 17),
          isAllDay: st.startTime == null,
          shiftTypeId: stId,
        ));
      }
    }
    return schedules;
  }
}
