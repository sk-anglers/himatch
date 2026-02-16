import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// Weekly view widget showing 7 days as columns with hourly time slots (7:00-23:00).
class WeekView extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  final List<Schedule> schedules;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime>? onTimeSlotTapped;
  final Map<DateTime, WeatherSummary>? weatherData;

  /// Function that returns a holiday name for a given date, or null.
  final String? Function(DateTime)? holidayService;

  const WeekView({
    super.key,
    required this.selectedDay,
    required this.schedules,
    required this.onDaySelected,
    this.onTimeSlotTapped,
    this.weatherData,
    this.holidayService,
  });

  @override
  ConsumerState<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends ConsumerState<WeekView> {
  late PageController _pageController;
  late DateTime _currentWeekStart;
  final ScrollController _verticalScrollController = ScrollController();

  static const int _startHour = 7;
  static const int _endHour = 23;
  static const double _hourHeight = 60.0;
  static const double _headerHeight = 80.0;
  static const double _timeColumnWidth = 48.0;

  static const List<String> _weekDayLabels = [
    '月', '火', '水', '木', '金', '土', '日',
  ];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(widget.selectedDay);
    _pageController = PageController(initialPage: 500);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    // Monday-based week
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  DateTime _weekStartForPage(int page) {
    final offset = page - 500;
    return _currentWeekStart.add(Duration(days: offset * 7));
  }

  List<Schedule> _schedulesForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return widget.schedules.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return d == target;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shiftTypeMap = ref.watch(shiftTypeMapProvider);

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (page) {
        final weekStart = _weekStartForPage(page);
        widget.onDaySelected(weekStart);
      },
      itemBuilder: (context, page) {
        final weekStart = _weekStartForPage(page);
        return _buildWeekPage(weekStart, shiftTypeMap);
      },
    );
  }

  Widget _buildWeekPage(
      DateTime weekStart, Map<String, dynamic> shiftTypeMap) {
    return Column(
      children: [
        // Day headers with weather and holiday
        _buildDayHeaders(weekStart),
        const Divider(height: 1),
        // Scrollable time grid
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time labels column
                _buildTimeColumn(),
                // Day columns
                ...List.generate(7, (dayIndex) {
                  final day = weekStart.add(Duration(days: dayIndex));
                  return Expanded(
                    child: _buildDayColumn(day, shiftTypeMap),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(DateTime weekStart) {
    final today = DateTime.now();

    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          // Empty corner for time column
          const SizedBox(width: _timeColumnWidth),
          ...List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            final isSelected = day.year == widget.selectedDay.year &&
                day.month == widget.selectedDay.month &&
                day.day == widget.selectedDay.day;
            final isSunday = day.weekday == DateTime.sunday;
            final isSaturday = day.weekday == DateTime.saturday;
            final holiday = widget.holidayService?.call(day);
            final isHoliday = holiday != null;
            final weather = widget.weatherData?[
                DateTime(day.year, day.month, day.day)];

            Color dayColor;
            if (isHoliday || isSunday) {
              dayColor = AppColors.error;
            } else if (isSaturday) {
              dayColor = const Color(0xFF3498DB);
            } else {
              dayColor = AppColors.textPrimary;
            }

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onDaySelected(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : null,
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Weather icon
                      SizedBox(
                        height: 18,
                        child: weather != null
                            ? Text(
                                weather.icon ?? '',
                                style: const TextStyle(fontSize: 14),
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Day of week label
                      Text(
                        _weekDayLabels[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: dayColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Date number
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.primary : null,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Colors.white : dayColor,
                          ),
                        ),
                      ),
                      // Holiday name
                      if (isHoliday)
                        Flexible(
                          child: Text(
                            holiday.length > 4
                                ? holiday.substring(0, 4)
                                : holiday,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    final totalHours = _endHour - _startHour;
    return SizedBox(
      width: _timeColumnWidth,
      height: totalHours * _hourHeight,
      child: Stack(
        children: List.generate(totalHours, (index) {
          final hour = _startHour + index;
          return Positioned(
            top: index * _hourHeight - 6,
            left: 0,
            right: 4,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(DateTime day, Map<String, dynamic> shiftTypeMap) {
    final totalHours = _endHour - _startHour;
    final daySchedules = _schedulesForDay(day);

    return SizedBox(
      height: totalHours * _hourHeight,
      child: Stack(
        children: [
          // Hour grid lines
          ...List.generate(totalHours, (index) {
            return Positioned(
              top: index * _hourHeight,
              left: 0,
              right: 0,
              child: Container(
                height: _hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.surfaceVariant,
                      width: 0.5,
                    ),
                    right: BorderSide(
                      color: AppColors.surfaceVariant,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Tap targets for empty slots
          ...List.generate(totalHours, (index) {
            final hour = _startHour + index;
            return Positioned(
              top: index * _hourHeight,
              left: 0,
              right: 0,
              height: _hourHeight,
              child: GestureDetector(
                onTap: () {
                  final tappedTime = DateTime(
                    day.year,
                    day.month,
                    day.day,
                    hour,
                  );
                  widget.onTimeSlotTapped?.call(tappedTime);
                },
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            );
          }),
          // Schedule blocks
          ...daySchedules.map((schedule) {
            return _buildScheduleBlock(schedule, shiftTypeMap);
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleBlock(
      Schedule schedule, Map<String, dynamic> shiftTypeMap) {
    final startMinutes =
        schedule.startTime.hour * 60 + schedule.startTime.minute;
    final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
    final clampedStartMinutes =
        (startMinutes - _startHour * 60).clamp(0, (_endHour - _startHour) * 60);
    final clampedEndMinutes =
        (endMinutes - _startHour * 60).clamp(0, (_endHour - _startHour) * 60);

    final top = clampedStartMinutes * _hourHeight / 60;
    final height =
        ((clampedEndMinutes - clampedStartMinutes) * _hourHeight / 60)
            .clamp(20.0, double.infinity);

    Color blockColor;
    if (schedule.shiftTypeId != null &&
        shiftTypeMap.containsKey(schedule.shiftTypeId)) {
      final shiftType = shiftTypeMap[schedule.shiftTypeId];
      blockColor = shiftTypeColor(shiftType);
    } else {
      blockColor = _scheduleTypeColor(schedule.scheduleType);
    }

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: blockColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(3),
        child: Text(
          schedule.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _scheduleTypeColor(ScheduleType type) {
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
