import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/utils/rrule_parser.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/models/schedule.dart';

/// Provider for expanding recurring schedules into concrete occurrences.
///
/// Uses [RRuleParser] to expand schedules that have a [Schedule.recurrenceRule]
/// into individual occurrences within the given date range. Non-recurring
/// schedules within the range are included as-is.
///
/// Usage:
/// ```dart
/// final expanded = ref.watch(expandedSchedulesProvider((
///   rangeStart: DateTime(2026, 3, 1),
///   rangeEnd: DateTime(2026, 3, 31),
/// )));
/// ```
final expandedSchedulesProvider = Provider.family<
    List<Schedule>,
    ({DateTime rangeStart, DateTime rangeEnd})>((ref, range) {
  final schedules = ref.watch(localSchedulesProvider);
  final results = <Schedule>[];

  for (final schedule in schedules) {
    if (schedule.recurrenceRule != null &&
        schedule.recurrenceRule!.isNotEmpty) {
      // Expand recurring schedule using RRuleParser
      final occurrenceDates = RRuleParser.expand(
        schedule.recurrenceRule!,
        schedule.startTime,
        range.rangeStart,
        range.rangeEnd,
      );

      // Calculate the duration of the original event
      final duration = schedule.endTime.difference(schedule.startTime);

      for (final date in occurrenceDates) {
        // Preserve the time-of-day from the original schedule
        final occurrenceStart = DateTime(
          date.year,
          date.month,
          date.day,
          schedule.startTime.hour,
          schedule.startTime.minute,
        );
        final occurrenceEnd = occurrenceStart.add(duration);

        results.add(schedule.copyWith(
          startTime: occurrenceStart,
          endTime: occurrenceEnd,
        ));
      }
    } else {
      // Non-recurring: include if it falls within the range
      if (!schedule.endTime.isBefore(range.rangeStart) &&
          !schedule.startTime.isAfter(range.rangeEnd)) {
        results.add(schedule);
      }
    }
  }

  // Sort by start time ascending
  results.sort((a, b) => a.startTime.compareTo(b.startTime));
  return results;
});
