import 'package:flutter/material.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Base calendar cell that provides the shared layout and decoration
/// used by both CalendarTab and SuggestionsTab calendar cells.
///
/// Layout (3 rows, centered in a bordered container):
///   - Top: day number (colored by weekday / holiday / selection state)
///   - Middle: 16px slot for weather icon or holiday abbreviation
///   - Bottom: 16px slot for custom content (shift marker, score badge, etc.)
class BaseCalendarCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final String? holidayName;

  /// Content for the middle row (16px height). Typically a weather icon
  /// or holiday abbreviation. If null, falls back to holiday abbreviation.
  final Widget? middleContent;

  /// Content for the bottom row (16px height). Shift marker, score badge, etc.
  final Widget? bottomContent;

  const BaseCalendarCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isOutside,
    this.holidayName,
    this.middleContent,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final isHoliday = holidayName != null;
    final isSunday = day.weekday == DateTime.sunday;
    final isSaturday = day.weekday == DateTime.saturday;

    // Day number color
    Color dayColor;
    if (isOutside) {
      dayColor = AppColors.textHint;
    } else if (isSelected) {
      dayColor = AppColors.primary;
    } else if (isToday) {
      dayColor = AppColors.primaryDark;
    } else if (isHoliday || isSunday) {
      dayColor = AppColors.error;
    } else if (isSaturday) {
      dayColor = const Color(0xFF3498DB);
    } else {
      dayColor = AppColors.textPrimary;
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : isToday
                ? AppColors.primaryLight.withValues(alpha: 0.10)
                : isHoliday && !isOutside
                    ? AppColors.error.withValues(alpha: 0.04)
                    : null,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primaryLight
                  : AppColors.surfaceVariant,
          width: isSelected || isToday ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number (top)
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday || isSelected || isHoliday
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: dayColor,
            ),
          ),
          // Middle slot (weather icon or holiday abbreviation)
          SizedBox(
            height: 16,
            child: middleContent ??
                (isHoliday && !isOutside
                    ? Text(
                        holidayName!.length > 3
                            ? holidayName!.substring(0, 3)
                            : holidayName!,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          height: 1.8,
                        ),
                      )
                    : null),
          ),
          // Bottom slot (custom content)
          SizedBox(
            height: 16,
            child: bottomContent,
          ),
        ],
      ),
    );
  }
}
