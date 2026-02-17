import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/group.dart';

/// Availability heatmap showing group member free time overlap.
///
/// X axis: dates (next 14 days)
/// Y axis: time slots (9:00-22:00, 1-hour granularity)
/// Cell color intensity = number of members available
class AvailabilityHeatmap extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupMember> members;

  /// Map of userId -> List<Schedule> for each member.
  final Map<String, List<Schedule>> schedules;

  const AvailabilityHeatmap({
    super.key,
    required this.groupId,
    required this.members,
    required this.schedules,
  });

  @override
  ConsumerState<AvailabilityHeatmap> createState() =>
      _AvailabilityHeatmapState();
}

class _AvailabilityHeatmapState extends ConsumerState<AvailabilityHeatmap> {
  final ScrollController _horizontalScrollController = ScrollController();

  static const int _startHour = 9;
  static const int _endHour = 22;
  static const int _totalSlots = 22 - 9; // 13 slots
  static const int _totalDays = 14;
  static const double _cellWidth = 44.0;
  static const double _cellHeight = 32.0;
  static const double _timeColumnWidth = 52.0;
  static const double _headerHeight = 48.0;

  static const List<String> _weekDayLabels = [
    '月', '火', '水', '木', '金', '土', '日',
  ];

  /// For each (day, hour) cell, compute which members are available (not busy).
  Map<String, List<String>> _computeAvailability() {
    final today = DateTime.now();
    final result = <String, List<String>>{};

    for (int dayOffset = 0; dayOffset < _totalDays; dayOffset++) {
      final day = DateTime(today.year, today.month, today.day + dayOffset);

      for (int hour = _startHour; hour < _endHour; hour++) {
        final slotStart = DateTime(day.year, day.month, day.day, hour);
        final slotEnd = DateTime(day.year, day.month, day.day, hour + 1);
        final key = '${dayOffset}_$hour';

        final available = <String>[];

        for (final member in widget.members) {
          final memberSchedules =
              widget.schedules[member.userId] ?? [];

          // Check if member is busy during this slot
          final isBusy = memberSchedules.any((s) {
            // A schedule overlaps the slot if it starts before slot ends
            // and ends after slot starts
            return s.startTime.isBefore(slotEnd) &&
                s.endTime.isAfter(slotStart) &&
                s.scheduleType != ScheduleType.free;
          });

          if (!isBusy) {
            available.add(member.userId);
          }
        }

        result[key] = available;
      }
    }
    return result;
  }

  Color _getHeatmapColor(int availableCount, int totalMembers) {
    if (totalMembers == 0) return AppColors.heatmapNone;
    final ratio = availableCount / totalMembers;

    if (ratio >= 1.0) return AppColors.heatmapFull;
    if (ratio >= 0.75) return AppColors.heatmapHigh;
    if (ratio >= 0.5) return AppColors.heatmapMedium;
    if (ratio > 0) return AppColors.heatmapLow;
    return AppColors.heatmapNone;
  }

  void _showAvailableMembers(
      BuildContext context, DateTime day, int hour, List<String> memberIds) {
    // Map user IDs to member nicknames or IDs
    final memberNames = memberIds.map((id) {
      final member = widget.members.firstWhere(
        (m) => m.userId == id,
        orElse: () => GroupMember(
          id: id,
          groupId: widget.groupId,
          userId: id,
        ),
      );
      return member.nickname ?? member.userId;
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${day.month}/${day.day} ${hour.toString().padLeft(2, '0')}:00',
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${memberNames.length}/${widget.members.length}人が空いています',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (memberNames.isEmpty)
              const Text(
                '空いているメンバーはいません',
                style: TextStyle(color: AppColors.textHint),
              )
            else
              ...memberNames.map((name) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availability = _computeAvailability();
    final today = DateTime.now();
    final totalMembers = widget.members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heatmap grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizontalScrollController,
            child: SizedBox(
              width: _timeColumnWidth + _totalDays * _cellWidth,
              child: Column(
                children: [
                  // Date headers
                  SizedBox(
                    height: _headerHeight,
                    child: Row(
                      children: [
                        // Empty corner
                        const SizedBox(width: _timeColumnWidth),
                        ...List.generate(_totalDays, (dayOffset) {
                          final day = DateTime(
                              today.year, today.month, today.day + dayOffset);
                          final isToday = dayOffset == 0;
                          final weekdayIndex =
                              (day.weekday - 1) % 7; // 0=Mon
                          final isSunday = day.weekday == DateTime.sunday;
                          final isSaturday = day.weekday == DateTime.saturday;

                          return SizedBox(
                            width: _cellWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _weekDayLabels[weekdayIndex],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSunday
                                        ? AppColors.error
                                        : isSaturday
                                            ? AppColors.weatherRainy
                                            : AppColors.textHint,
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isToday ? AppColors.primary : null,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isToday
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Time slots grid
                  Expanded(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time labels
                          SizedBox(
                            width: _timeColumnWidth,
                            child: Column(
                              children: List.generate(_totalSlots, (index) {
                                final hour = _startHour + index;
                                return SizedBox(
                                  height: _cellHeight,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: Text(
                                        '${hour.toString().padLeft(2, '0')}:00',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          // Cells
                          ...List.generate(_totalDays, (dayOffset) {
                            final day = DateTime(today.year, today.month,
                                today.day + dayOffset);
                            return SizedBox(
                              width: _cellWidth,
                              child: Column(
                                children:
                                    List.generate(_totalSlots, (slotIndex) {
                                  final hour = _startHour + slotIndex;
                                  final key = '${dayOffset}_$hour';
                                  final available =
                                      availability[key] ?? [];
                                  final color = _getHeatmapColor(
                                      available.length, totalMembers);

                                  return GestureDetector(
                                    onTap: () => _showAvailableMembers(
                                        context, day, hour, available),
                                    child: Container(
                                      width: _cellWidth,
                                      height: _cellHeight,
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 0.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: available.isNotEmpty
                                          ? Text(
                                              '${available.length}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    available.length ==
                                                            totalMembers
                                                        ? Colors.white
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Legend
        const SizedBox(height: 8),
        _buildLegend(totalMembers),
      ],
    );
  }

  Widget _buildLegend(int totalMembers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '全員空き',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          _legendCell(AppColors.heatmapFull),
          _legendCell(AppColors.heatmapHigh),
          _legendCell(AppColors.heatmapMedium),
          _legendCell(AppColors.heatmapLow),
          _legendCell(AppColors.heatmapNone),
          const SizedBox(width: 6),
          const Text(
            '0人',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _legendCell(Color color) {
    return Container(
      width: 20,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }
}
