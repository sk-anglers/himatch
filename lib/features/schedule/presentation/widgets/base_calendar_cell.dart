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
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final isHoliday = holidayName != null;
    final isSunday = day.weekday == DateTime.sunday;
    final isSaturday = day.weekday == DateTime.saturday;

    // Day number color (theme-aware)
    Color dayColor;
    if (isOutside) {
      dayColor = colors.textHint;
    } else if (isSelected) {
      dayColor = colors.primary;
    } else if (isToday) {
      dayColor = colors.primaryDark;
    } else if (isHoliday || isSunday) {
      dayColor = colors.error;
    } else if (isSaturday) {
      dayColor = AppColors.weatherRainy;
    } else {
      dayColor = colors.textPrimary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.12)
            : isToday
                ? colors.primaryLight.withValues(alpha: 0.10)
                : isHoliday && !isOutside
                    ? colors.error.withValues(alpha: 0.04)
                    : null,
        border: Border.all(
          color: isSelected
              ? colors.primary
              : isToday
                  ? colors.primaryLight
                  : colors.surfaceVariant,
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
                        style: TextStyle(
                          fontSize: 8,
                          color: colors.error,
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
