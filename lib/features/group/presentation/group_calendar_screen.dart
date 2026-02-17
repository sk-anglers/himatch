import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';
import 'package:himatch/features/schedule/presentation/widgets/shift_badge.dart';

/// Member colors for overlay display (up to 8 distinct colors).
const _memberColors = [
  AppColors.primary,    // Purple
  AppColors.secondary,  // Red
  Color(0xFF00B894),    // Green
  Color(0xFFF39C12),    // Orange
  Color(0xFF3498DB),    // Blue
  Color(0xFFE91E63),    // Pink
  Color(0xFF009688),    // Teal
  Color(0xFF795548),    // Brown
];

/// Shows a calendar overlay of all group members' schedules.
class GroupCalendarScreen extends ConsumerStatefulWidget {
  final Group group;
  final String? initialMode;

  const GroupCalendarScreen({
    super.key,
    required this.group,
    this.initialMode,
  });

  @override
  ConsumerState<GroupCalendarScreen> createState() =>
      _GroupCalendarScreenState();
}

class _GroupCalendarScreenState extends ConsumerState<GroupCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final membersMap = ref.watch(localGroupMembersProvider);
    final members = membersMap[widget.group.id] ?? [];
    final mySchedules = ref.watch(localSchedulesProvider);
    final shiftTypeMap = ref.watch(shiftTypeMapProvider);

    // Build member schedule map: userId -> List<Schedule>
    // In demo mode, only local-user has real schedules, others are "fully free"
    final memberSchedules = <String, List<Schedule>>{};
    for (final member in members) {
      if (member.userId == AppConstants.localUserId) {
        memberSchedules[member.userId] = mySchedules;
      } else {
        // Demo: generate simulated schedules for other members
        memberSchedules[member.userId] =
            _generateDemoSchedules(member.userId);
      }
    }

    // Find days where ALL members are free (no busy schedules)
    final allFreeDays = _findAllFreeDays(memberSchedules, members);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.name} のカレンダー'),
      ),
      body: Column(
        children: [
          // Member legend
          _MemberLegend(members: members),
          // Calendar
          TableCalendar<Schedule>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'ja_JP',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) =>
                _getAllSchedulesForDay(day, memberSchedules),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                // シフト付きイベントをバッジ表示
                final shiftEvents = events
                    .where((e) => e.shiftTypeId != null)
                    .toList();

                // Group events by userId to show colored dots
                final userIds = events.map((e) => e.userId).toSet();
                final memberList = members.toList();

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // シフトバッジ（local-userのみ、最大1つ）
                    ...shiftEvents
                        .where((e) => e.userId == AppConstants.localUserId)
                        .take(1)
                        .map((e) {
                      final st = shiftTypeMap[e.shiftTypeId];
                      if (st == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: ShiftBadge(shiftType: st, size: 14),
                      );
                    }),
                    // 他メンバーはドット
                    ...userIds
                        .where((uid) =>
                            uid != AppConstants.localUserId ||
                            shiftEvents.every((e) => e.userId != AppConstants.localUserId))
                        .take(3)
                        .map((userId) {
                      final idx = memberList
                          .indexWhere((m) => m.userId == userId);
                      final color = idx >= 0 && idx < _memberColors.length
                          ? _memberColors[idx]
                          : AppColors.textHint;
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ],
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final dayOnly =
                    DateTime(day.year, day.month, day.day);
                if (allFreeDays.contains(dayOnly)) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 0, // We use custom markers
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8),
          // All-free indicator
          if (_selectedDay != null &&
              allFreeDays.contains(DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day)))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    '全員空き！',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Selected day header
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    AppDateUtils.formatMonthDayWeek(_selectedDay!),
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const Spacer(),
                  Text(
                    '${members.length}人のメンバー',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Member schedules for selected day
          Expanded(
            child: _selectedDay == null
                ? const SizedBox.shrink()
                : _MemberDaySchedules(
                    day: _selectedDay!,
                    members: members,
                    memberSchedules: memberSchedules,
                    shiftTypeMap: shiftTypeMap,
                  ),
          ),
        ],
      ),
    );
  }

  List<Schedule> _getAllSchedulesForDay(
    DateTime day,
    Map<String, List<Schedule>> memberSchedules,
  ) {
    final targetDate = DateTime(day.year, day.month, day.day);
    final result = <Schedule>[];
    for (final schedules in memberSchedules.values) {
      for (final s in schedules) {
        final scheduleDate = DateTime(
          s.startTime.year,
          s.startTime.month,
          s.startTime.day,
        );
        if (scheduleDate == targetDate) {
          result.add(s);
        }
      }
    }
    return result;
  }

  /// Find days (in the next 30 days) where no member has blocking schedules.
  Set<DateTime> _findAllFreeDays(
    Map<String, List<Schedule>> memberSchedules,
    List<GroupMember> members,
  ) {
    if (members.length < 2) return {};

    final freeDays = <DateTime>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < 30; i++) {
      final day = today.add(Duration(days: i));
      var allFree = true;

      for (final entry in memberSchedules.entries) {
        final hasBlocking = entry.value.any((s) {
          final scheduleDate = DateTime(
            s.startTime.year,
            s.startTime.month,
            s.startTime.day,
          );
          return scheduleDate == day &&
              (s.scheduleType == ScheduleType.shift ||
                  s.scheduleType == ScheduleType.event ||
                  s.scheduleType == ScheduleType.blocked);
        });
        if (hasBlocking) {
          allFree = false;
          break;
        }
      }

      if (allFree) {
        freeDays.add(day);
      }
    }

    return freeDays;
  }

  /// Generate simple demo schedules for non-local members.
  List<Schedule> _generateDemoSchedules(String userId) {
    final now = DateTime.now();
    final schedules = <Schedule>[];
    // Generate a few scattered schedules for the next 2 weeks
    for (var i = 0; i < 14; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      // Deterministic "random" based on userId hash and day
      final hash = userId.hashCode + i * 31;
      // ~40% chance of having a schedule
      if (hash % 5 < 2) {
        final hour = 9 + (hash.abs() % 8); // 9-16
        schedules.add(Schedule(
          id: 'demo-$userId-$i',
          userId: userId,
          title: _demoTitle(hash),
          scheduleType: _demoType(hash),
          startTime: DateTime(day.year, day.month, day.day, hour),
          endTime: DateTime(day.year, day.month, day.day, hour + 3),
        ));
      }
    }
    return schedules;
  }

  String _demoTitle(int hash) {
    const titles = ['バイト', '授業', '予定あり', 'シフト', '部活'];
    return titles[hash.abs() % titles.length];
  }

  ScheduleType _demoType(int hash) {
    const types = [ScheduleType.shift, ScheduleType.event, ScheduleType.blocked];
    return types[hash.abs() % types.length];
  }
}

/// Color-coded legend showing each member.
class _MemberLegend extends StatelessWidget {
  final List<GroupMember> members;

  const _MemberLegend({required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (var i = 0; i < members.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < _memberColors.length
                        ? _memberColors[i]
                        : AppColors.textHint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  members[i].userId == AppConstants.localUserId
                      ? 'あなた'
                      : members[i].nickname ?? 'メンバー${i + 1}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          // All-free legend
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '全員空き',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows each member's schedule for a selected day.
class _MemberDaySchedules extends StatelessWidget {
  final DateTime day;
  final List<GroupMember> members;
  final Map<String, List<Schedule>> memberSchedules;
  final Map<String, ShiftType> shiftTypeMap;

  const _MemberDaySchedules({
    required this.day,
    required this.members,
    required this.memberSchedules,
    required this.shiftTypeMap,
  });

  @override
  Widget build(BuildContext context) {
    final targetDate = DateTime(day.year, day.month, day.day);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final color = index < _memberColors.length
            ? _memberColors[index]
            : AppColors.textHint;
        final schedules = (memberSchedules[member.userId] ?? [])
            .where((s) {
          final d = DateTime(
              s.startTime.year, s.startTime.month, s.startTime.day);
          return d == targetDate;
        }).toList();

        final name = member.userId == AppConstants.localUserId
            ? 'あなた'
            : member.nickname ?? 'メンバー${index + 1}';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color indicator
                Container(
                  width: 4,
                  height: schedules.isEmpty ? 32 : 32.0 + (schedules.length - 1) * 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member name
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                          if (member.role == 'owner') ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star,
                                size: 14, color: AppColors.warning),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Schedules or free
                      if (schedules.isEmpty)
                        const Text(
                          '空き',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        )
                      else
                        ...schedules.map((s) {
                        final st = s.shiftTypeId != null
                            ? shiftTypeMap[s.shiftTypeId]
                            : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              if (st != null)
                                ShiftBadge(shiftType: st, size: 16)
                              else
                                _TypeDot(type: s.scheduleType),
                              const SizedBox(width: 6),
                              Text(
                                s.isAllDay
                                    ? '終日'
                                    : '${AppDateUtils.formatTime(s.startTime)}-${AppDateUtils.formatTime(s.endTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TypeDot extends StatelessWidget {
  final ScheduleType type;

  const _TypeDot({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ScheduleType.shift => AppColors.primary,
      ScheduleType.event => AppColors.warning,
      ScheduleType.free => AppColors.success,
      ScheduleType.blocked => AppColors.error,
    };
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
