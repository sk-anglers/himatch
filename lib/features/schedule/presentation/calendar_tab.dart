import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/features/schedule/presentation/schedule_form_screen.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
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
    final schedules = ref.watch(localSchedulesProvider);
    final selectedDaySchedules = _getSchedulesForDay(_selectedDay, schedules);

    return Scaffold(
      body: Column(
        children: [
          TableCalendar<Schedule>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'ja_JP',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getSchedulesForDay(day, schedules),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              markerSize: 6,
              markersMaxCount: 3,
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
          // Selected day header
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    AppDateUtils.formatMonthDayWeek(_selectedDay!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${selectedDaySchedules.length}件',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Schedule list
          Expanded(
            child: selectedDaySchedules.isEmpty
                ? const Center(
                    child: Text(
                      '予定がありません',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedDaySchedules.length,
                    itemBuilder: (context, index) {
                      return _ScheduleCard(
                        schedule: selectedDaySchedules[index],
                        onTap: () => _openEditForm(selectedDaySchedules[index]),
                        onDelete: () => _deleteSchedule(selectedDaySchedules[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Schedule> _getSchedulesForDay(DateTime? day, List<Schedule> schedules) {
    if (day == null) return [];
    return schedules.where((s) {
      final scheduleDate = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);
      return scheduleDate == targetDate;
    }).toList();
  }

  void _openAddForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          initialDate: _selectedDay ?? DateTime.now(),
        ),
      ),
    );
  }

  void _openEditForm(Schedule schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          initialDate: schedule.startTime,
          schedule: schedule,
        ),
      ),
    );
  }

  void _deleteSchedule(Schedule schedule) {
    ref.read(localSchedulesProvider.notifier).removeSchedule(schedule.id);
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(schedule.scheduleType),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ScheduleTypeBadge(type: schedule.scheduleType),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            schedule.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.isAllDay
                          ? '終日'
                          : '${AppDateUtils.formatTime(schedule.startTime)} - ${AppDateUtils.formatTime(schedule.endTime)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.textHint,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('削除確認'),
                      content: Text('「${schedule.title}」を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete();
                          },
                          child: const Text('削除',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.shift:
        return AppColors.primary;
      case ScheduleType.event:
        return AppColors.warning;
      case ScheduleType.free:
        return AppColors.success;
      case ScheduleType.blocked:
        return AppColors.error;
    }
  }
}

class _ScheduleTypeBadge extends StatelessWidget {
  final ScheduleType type;

  const _ScheduleTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ScheduleType.shift => ('シフト', AppColors.primary),
      ScheduleType.event => ('予定', AppColors.warning),
      ScheduleType.free => ('空き', AppColors.success),
      ScheduleType.blocked => ('不可', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
