import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// A single day detailed view with 24-hour timeline.
class DayView extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  final List<Schedule> schedules;
  final ValueChanged<DateTime> onTimeSlotTapped;
  final WeatherSummary? weather;

  const DayView({
    super.key,
    required this.selectedDay,
    required this.schedules,
    required this.onTimeSlotTapped,
    this.weather,
  });

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  static const double _hourHeight = 64.0;
  static const double _timeColumnWidth = 52.0;
  static const int _totalHours = 24;

  @override
  void initState() {
    super.initState();
    // Scroll to current time on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
    // Refresh current time indicator every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final offset = (now.hour * _hourHeight + now.minute * _hourHeight / 60) -
        MediaQuery.of(context).size.height / 3;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<Schedule> get _daySchedules {
    final target = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
    );
    return widget.schedules.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return d == target;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.selectedDay.year == now.year &&
        widget.selectedDay.month == now.month &&
        widget.selectedDay.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final shiftTypeMap = ref.watch(shiftTypeMapProvider);
    final schedules = _daySchedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weather header
        if (widget.weather != null) _buildWeatherHeader(),
        const Divider(height: 1),
        // Timeline
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: _totalHours * _hourHeight,
              child: Stack(
                children: [
                  // Hour grid lines + time labels
                  _buildTimeGrid(),
                  // Tap targets for empty areas
                  _buildTapTargets(),
                  // Schedule blocks
                  ...schedules.map((s) => _buildScheduleBlock(s, shiftTypeMap)),
                  // Current time indicator
                  if (_isToday) _buildCurrentTimeIndicator(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherHeader() {
    final w = widget.weather!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          if (w.icon != null)
            Text(w.icon!, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            w.condition,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (w.tempHigh != null || w.tempLow != null)
            Text(
              '${w.tempHigh?.round() ?? "-"}°/${w.tempLow?.round() ?? "-"}°',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeGrid() {
    return Column(
      children: List.generate(_totalHours, (hour) {
        return SizedBox(
          height: _hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              SizedBox(
                width: _timeColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 0),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
              // Grid line
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.surfaceVariant,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTapTargets() {
    return Positioned.fill(
      left: _timeColumnWidth,
      child: Column(
        children: List.generate(_totalHours * 2, (index) {
          final hour = index ~/ 2;
          final minute = (index % 2) * 30;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                final tapped = DateTime(
                  widget.selectedDay.year,
                  widget.selectedDay.month,
                  widget.selectedDay.day,
                  hour,
                  minute,
                );
                widget.onTimeSlotTapped(tapped);
              },
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleBlock(
      Schedule schedule, Map<String, ShiftType> shiftTypeMap) {
    final startMinutes =
        schedule.startTime.hour * 60 + schedule.startTime.minute;
    final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;

    final top = startMinutes * _hourHeight / 60;
    final height = ((endMinutes - startMinutes) * _hourHeight / 60)
        .clamp(24.0, double.infinity);

    Color blockColor;
    if (schedule.shiftTypeId != null &&
        shiftTypeMap.containsKey(schedule.shiftTypeId)) {
      final shiftType = shiftTypeMap[schedule.shiftTypeId]!;
      blockColor = shiftTypeColor(shiftType);
    } else {
      blockColor = _scheduleTypeColor(schedule.scheduleType);
    }

    return Positioned(
      top: top,
      left: _timeColumnWidth + 4,
      right: 8,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: blockColor.withValues(alpha: 0.15),
          border: Border(
            left: BorderSide(color: blockColor, width: 3),
          ),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: blockColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (height > 36)
              Text(
                schedule.isAllDay
                    ? '終日'
                    : '${AppDateUtils.formatTime(schedule.startTime)} - ${AppDateUtils.formatTime(schedule.endTime)}',
                style: TextStyle(
                  fontSize: 11,
                  color: blockColor.withValues(alpha: 0.7),
                ),
              ),
            if (height > 52 && schedule.location != null)
              Text(
                schedule.location!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final minutesFromTop = now.hour * 60 + now.minute;
    final top = minutesFromTop * _hourHeight / 60;

    return Positioned(
      top: top,
      left: _timeColumnWidth - 4,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: AppColors.error,
            ),
          ),
        ],
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
