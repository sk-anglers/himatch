import 'package:himatch/core/constants/app_constants.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:uuid/uuid.dart';

/// Pure Dart suggestion engine.
/// Analyzes group members' schedules to find overlapping free time slots
/// and generates context-aware date suggestions.
class SuggestionEngine {
  static const _uuid = Uuid();

  /// Generate suggestions for a group based on members' schedules.
  ///
  /// [memberSchedules] maps userId -> list of schedules.
  /// [searchRangeDays] how many days ahead to search.
  /// [groupId] the group to generate suggestions for.
  /// [weatherData] optional weather forecast keyed by date.
  List<Suggestion> generateSuggestions({
    required Map<String, List<Schedule>> memberSchedules,
    required String groupId,
    int searchRangeDays = AppConstants.defaultSearchRangeDays,
    Map<DateTime, WeatherSummary>? weatherData,
  }) {
    if (memberSchedules.length < AppConstants.minGroupMembers) {
      return [];
    }

    final totalMembers = memberSchedules.length;
    final memberIds = memberSchedules.keys.toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final suggestions = <Suggestion>[];

    // Scan each day in the search range
    for (int dayOffset = 1; dayOffset <= searchRangeDays; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;

      // Find free slots for each member on this day
      final memberFreeSlots = <String, List<_TimeSlot>>{};
      for (final userId in memberIds) {
        final schedules = memberSchedules[userId] ?? [];
        final freeSlots = _findFreeSlotsForDay(date, schedules);
        memberFreeSlots[userId] = freeSlots;
      }

      // Find overlapping free time slots across members
      final overlaps = _findOverlappingSlots(memberFreeSlots, memberIds);

      // Look up weather for this date
      final dateKey = DateTime(date.year, date.month, date.day);
      final weather = weatherData?[dateKey];

      for (final overlap in overlaps) {
        if (overlap.availableMembers.length < AppConstants.minGroupMembers) {
          continue;
        }

        final durationHours = overlap.slot.durationHours;
        if (durationHours < 1.0) continue; // Skip slots less than 1 hour

        final timeCategory = _classifyTimeCategory(overlap.slot);
        final activityType = _suggestActivity(
          timeCategory: timeCategory,
          durationHours: durationHours,
          isWeekend: isWeekend,
          weather: weather,
        );
        final availabilityRatio =
            overlap.availableMembers.length / totalMembers;

        final score = _calculateScore(
          availabilityRatio: availabilityRatio,
          durationHours: durationHours,
          timeCategory: timeCategory,
          isWeekend: isWeekend,
          weather: weather,
        );

        suggestions.add(Suggestion(
          id: _uuid.v4(),
          groupId: groupId,
          suggestedDate: date,
          startTime: DateTime(
            date.year,
            date.month,
            date.day,
            overlap.slot.startHour,
            overlap.slot.startMinute,
          ),
          endTime: DateTime(
            date.year,
            date.month,
            date.day,
            overlap.slot.endHour,
            overlap.slot.endMinute,
          ),
          durationHours: durationHours,
          timeCategory: timeCategory,
          activityType: activityType,
          availableMembers: overlap.availableMembers,
          totalMembers: totalMembers,
          availabilityRatio: availabilityRatio,
          weatherSummary: weather,
          score: score,
          status: SuggestionStatus.proposed,
          createdAt: DateTime.now(),
          expiresAt: date.add(const Duration(days: 1)),
        ));
      }
    }

    // Sort by score descending, then by date ascending
    suggestions.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.suggestedDate.compareTo(b.suggestedDate);
    });

    return suggestions;
  }

  /// Find free time slots for a specific day based on user's schedules.
  List<_TimeSlot> _findFreeSlotsForDay(
    DateTime date,
    List<Schedule> schedules,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day, 8, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 22, 0);

    // Collect all blocked intervals for this day
    final blocked = <_TimeSlot>[];

    for (final schedule in schedules) {
      if (!_isOnDay(schedule, date)) continue;

      // Free schedules don't block time
      if (schedule.scheduleType == ScheduleType.free) continue;

      if (schedule.isAllDay) {
        // All-day non-free event blocks the whole day
        return [];
      }

      blocked.add(_TimeSlot(
        startHour: schedule.startTime.hour,
        startMinute: schedule.startTime.minute,
        endHour: schedule.endTime.hour,
        endMinute: schedule.endTime.minute,
      ));
    }

    // Also check for explicit free slots
    final freeSlots = <_TimeSlot>[];
    bool hasExplicitFree = false;

    for (final schedule in schedules) {
      if (!_isOnDay(schedule, date)) continue;
      if (schedule.scheduleType != ScheduleType.free) continue;
      hasExplicitFree = true;

      if (schedule.isAllDay) {
        freeSlots.add(_TimeSlot(
          startHour: dayStart.hour,
          startMinute: dayStart.minute,
          endHour: dayEnd.hour,
          endMinute: dayEnd.minute,
        ));
      } else {
        freeSlots.add(_TimeSlot(
          startHour: schedule.startTime.hour,
          startMinute: schedule.startTime.minute,
          endHour: schedule.endTime.hour,
          endMinute: schedule.endTime.minute,
        ));
      }
    }

    // If user has explicit free slots, use those (minus blocked)
    if (hasExplicitFree) {
      return _subtractBlocked(freeSlots, blocked);
    }

    // If no explicit free and no blocked, assume available 8-22
    if (blocked.isEmpty) {
      return [
        _TimeSlot(
          startHour: dayStart.hour,
          startMinute: dayStart.minute,
          endHour: dayEnd.hour,
          endMinute: dayEnd.minute,
        ),
      ];
    }

    // Otherwise, find gaps between blocked intervals
    return _findGaps(dayStart, dayEnd, blocked);
  }

  bool _isOnDay(Schedule schedule, DateTime date) {
    final scheduleDate = DateTime(
      schedule.startTime.year,
      schedule.startTime.month,
      schedule.startTime.day,
    );
    final targetDate = DateTime(date.year, date.month, date.day);
    return scheduleDate == targetDate;
  }

  /// Subtract blocked time from free slots.
  List<_TimeSlot> _subtractBlocked(
    List<_TimeSlot> freeSlots,
    List<_TimeSlot> blocked,
  ) {
    if (blocked.isEmpty) return freeSlots;

    var result = List<_TimeSlot>.from(freeSlots);
    for (final b in blocked) {
      final newResult = <_TimeSlot>[];
      for (final f in result) {
        newResult.addAll(_subtractInterval(f, b));
      }
      result = newResult;
    }
    return result;
  }

  /// Remove interval [b] from interval [f], returning remaining parts.
  List<_TimeSlot> _subtractInterval(_TimeSlot f, _TimeSlot b) {
    final fStart = f.startMinutes;
    final fEnd = f.endMinutes;
    final bStart = b.startMinutes;
    final bEnd = b.endMinutes;

    // No overlap
    if (bEnd <= fStart || bStart >= fEnd) return [f];

    final result = <_TimeSlot>[];

    // Left remainder
    if (bStart > fStart) {
      result.add(_TimeSlot.fromMinutes(fStart, bStart));
    }

    // Right remainder
    if (bEnd < fEnd) {
      result.add(_TimeSlot.fromMinutes(bEnd, fEnd));
    }

    return result;
  }

  /// Find gaps between blocked intervals within [dayStart, dayEnd].
  List<_TimeSlot> _findGaps(
    DateTime dayStart,
    DateTime dayEnd,
    List<_TimeSlot> blocked,
  ) {
    final sorted = List<_TimeSlot>.from(blocked)
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final gaps = <_TimeSlot>[];
    int current = dayStart.hour * 60 + dayStart.minute;
    final end = dayEnd.hour * 60 + dayEnd.minute;

    for (final slot in sorted) {
      if (slot.startMinutes > current) {
        gaps.add(_TimeSlot.fromMinutes(current, slot.startMinutes));
      }
      if (slot.endMinutes > current) {
        current = slot.endMinutes;
      }
    }

    if (current < end) {
      gaps.add(_TimeSlot.fromMinutes(current, end));
    }

    return gaps;
  }

  /// Find overlapping free slots across all members.
  List<_OverlapResult> _findOverlappingSlots(
    Map<String, List<_TimeSlot>> memberFreeSlots,
    List<String> memberIds,
  ) {
    if (memberIds.isEmpty) return [];

    // Merge all slots into a timeline to find potential windows
    final candidateSlots = <_TimeSlot>{};
    for (final slots in memberFreeSlots.values) {
      candidateSlots.addAll(slots);
    }

    // For each unique time window, find which members are available
    final results = <_OverlapResult>[];

    // Use 30-minute resolution for scanning
    for (int startMin = 8 * 60; startMin < 22 * 60; startMin += 30) {
      // Try different durations: 1h, 2h, 3h, 4h, 8h
      for (final durationMin in [60, 120, 180, 240, 480]) {
        final endMin = startMin + durationMin;
        if (endMin > 22 * 60) break;

        final window = _TimeSlot.fromMinutes(startMin, endMin);
        final availableMembers = <String>[];

        for (final userId in memberIds) {
          final slots = memberFreeSlots[userId] ?? [];
          if (_isFullyCovered(window, slots)) {
            availableMembers.add(userId);
          }
        }

        if (availableMembers.length >= AppConstants.minGroupMembers) {
          // Check if this is a superset of existing results (dedup)
          final isDuplicate = results.any((r) =>
              r.slot.startMinutes == window.startMinutes &&
              r.slot.endMinutes == window.endMinutes);
          if (!isDuplicate) {
            results.add(_OverlapResult(
              slot: window,
              availableMembers: availableMembers,
            ));
          }
        }
      }
    }

    // Remove dominated results (subset of a larger slot with same members)
    return _deduplicateOverlaps(results);
  }

  /// Check if a time window is fully covered by the given free slots.
  bool _isFullyCovered(_TimeSlot window, List<_TimeSlot> freeSlots) {
    for (final slot in freeSlots) {
      if (slot.startMinutes <= window.startMinutes &&
          slot.endMinutes >= window.endMinutes) {
        return true;
      }
    }
    return false;
  }

  /// Remove dominated overlaps: keep only the best (longest or most members)
  /// per approximate time window.
  List<_OverlapResult> _deduplicateOverlaps(List<_OverlapResult> results) {
    if (results.isEmpty) return results;

    // Group by approximate start time (within 1 hour) and keep best per group
    final grouped = <int, List<_OverlapResult>>{};
    for (final r in results) {
      final key = r.slot.startMinutes ~/ 60;
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final deduped = <_OverlapResult>[];
    for (final group in grouped.values) {
      // Sort by member count desc, then duration desc
      group.sort((a, b) {
        final memberCompare = b.availableMembers.length
            .compareTo(a.availableMembers.length);
        if (memberCompare != 0) return memberCompare;
        return b.slot.durationMinutes.compareTo(a.slot.durationMinutes);
      });
      deduped.add(group.first);
    }

    return deduped;
  }

  /// Classify time slot into a TimeCategory.
  TimeCategory _classifyTimeCategory(_TimeSlot slot) {
    final durationHours = slot.durationHours;

    if (durationHours >= AppConstants.allDayThreshold) {
      return TimeCategory.allDay;
    }

    final midpointMinutes =
        (slot.startMinutes + slot.endMinutes) ~/ 2;
    final midpointHour = midpointMinutes / 60;

    if (midpointHour < AppConstants.lunchStartHour) {
      return TimeCategory.morning;
    } else if (midpointHour < AppConstants.lunchEndHour) {
      return TimeCategory.lunch;
    } else if (midpointHour < AppConstants.eveningStartHour) {
      return TimeCategory.afternoon;
    } else {
      return TimeCategory.evening;
    }
  }

  /// Suggest an activity type based on context and weather.
  String _suggestActivity({
    required TimeCategory timeCategory,
    required double durationHours,
    required bool isWeekend,
    WeatherSummary? weather,
  }) {
    final isRainy = weather != null && _isRainyWeather(weather.condition);

    if (isRainy) {
      // Rainy day → indoor activities
      return switch (timeCategory) {
        TimeCategory.morning => 'カフェ',
        TimeCategory.lunch => 'ランチ',
        TimeCategory.afternoon =>
          durationHours >= 4 ? 'カラオケ' : '映画',
        TimeCategory.evening => isWeekend ? 'ディナー' : '飲み会',
        TimeCategory.allDay => 'カラオケ',
      };
    }

    return switch (timeCategory) {
      TimeCategory.morning => isWeekend ? 'お出かけ' : 'カフェ',
      TimeCategory.lunch => 'ランチ',
      TimeCategory.afternoon =>
        durationHours >= 4 ? (isWeekend ? '日帰り旅行' : '遊び') : 'カフェ',
      TimeCategory.evening => isWeekend ? 'ディナー' : '飲み会',
      TimeCategory.allDay => isWeekend ? '日帰り旅行' : 'BBQ',
    };
  }

  /// Check if a weather condition represents rain/snow.
  bool _isRainyWeather(String condition) {
    const rainyKeywords = ['雨', '雪', '雷', '霧雨'];
    return rainyKeywords.any((k) => condition.contains(k));
  }

  /// Calculate suggestion score (0.0 - 1.0).
  ///
  /// Weight distribution:
  /// - Availability ratio: 40%
  /// - Weather: 15%
  /// - Duration: 15%
  /// - Weekend: 10%
  /// - Time category: 10-15%
  double _calculateScore({
    required double availabilityRatio,
    required double durationHours,
    required TimeCategory timeCategory,
    required bool isWeekend,
    WeatherSummary? weather,
  }) {
    // Base: availability ratio (most important)
    double score = availabilityRatio * 0.4;

    // Weather factor (max ±0.15)
    if (weather != null) {
      score += _weatherScore(weather.condition);
    }

    // Duration weight (longer is generally better, up to a point)
    final durationScore = (durationHours / 8.0).clamp(0.0, 1.0);
    score += durationScore * 0.15;

    // Weekend bonus
    if (isWeekend) score += 0.1;

    // Time category bonus (evening/lunch are popular for social)
    final timeCategoryBonus = switch (timeCategory) {
      TimeCategory.evening => 0.15,
      TimeCategory.lunch => 0.12,
      TimeCategory.afternoon => 0.08,
      TimeCategory.allDay => 0.1,
      TimeCategory.morning => 0.05,
    };
    score += timeCategoryBonus;

    return score.clamp(0.0, 1.0);
  }

  /// Weather contribution to score.
  double _weatherScore(String condition) {
    if (condition.contains('快晴') || condition == '晴れ') return 0.15;
    if (condition.contains('曇り') || condition == 'くもり') return 0.05;
    if (condition.contains('霧')) return 0.0;
    if (condition.contains('雷')) return -0.15;
    if (condition.contains('雪') || condition.contains('雨')) return -0.10;
    if (condition.contains('にわか')) return -0.05;
    return 0.0;
  }
}

/// Internal time slot representation using hours and minutes.
class _TimeSlot {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const _TimeSlot({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  factory _TimeSlot.fromMinutes(int startMin, int endMin) {
    return _TimeSlot(
      startHour: startMin ~/ 60,
      startMinute: startMin % 60,
      endHour: endMin ~/ 60,
      endMinute: endMin % 60,
    );
  }

  int get startMinutes => startHour * 60 + startMinute;
  int get endMinutes => endHour * 60 + endMinute;
  int get durationMinutes => endMinutes - startMinutes;
  double get durationHours => durationMinutes / 60.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TimeSlot &&
          startMinutes == other.startMinutes &&
          endMinutes == other.endMinutes;

  @override
  int get hashCode => startMinutes.hashCode ^ endMinutes.hashCode;
}

class _OverlapResult {
  final _TimeSlot slot;
  final List<String> availableMembers;

  const _OverlapResult({
    required this.slot,
    required this.availableMembers,
  });
}
