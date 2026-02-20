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
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.08)
            : isToday
                ? colors.primaryLight.withValues(alpha: 0.06)
                : isHoliday && !isOutside
                    ? colors.error.withValues(alpha: 0.03)
                    : null,
        border: Border.all(
          color: isSelected
              ? colors.primary
              : isToday
                  ? colors.primaryLight
                  : colors.surfaceVariant,
          width: isSelected || isToday ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day number (top)
            Text(
              '${day.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday || isSelected || isHoliday
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: dayColor,
              ),
            ),
            const SizedBox(height: 1),
            // Bottom slot (shift badge — full width)
            if (bottomContent != null)
              bottomContent!
            else if (middleContent != null)
              Center(child: middleContent!)
            else if (isHoliday && !isOutside)
              Center(
                child: Text(
                  holidayName!.length > 3
                      ? holidayName!.substring(0, 3)
                      : holidayName!,
                  style: TextStyle(
                    fontSize: 8,
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
