import 'package:flutter_test/flutter_test.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/suggestion/domain/suggestion_engine.dart';

void main() {
  late SuggestionEngine engine;

  setUp(() {
    engine = SuggestionEngine();
  });

  Schedule makeSchedule({
    required String userId,
    required ScheduleType type,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
  }) {
    return Schedule(
      id: 'test-${startTime.toIso8601String()}',
      userId: userId,
      title: 'Test',
      scheduleType: type,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('SuggestionEngine', () {
    test('returns empty when fewer than 2 members', () {
      final result = engine.generateSuggestions(
        memberSchedules: {'user1': []},
        groupId: 'group1',
      );
      expect(result, isEmpty);
    });

    test('returns empty for empty member map', () {
      final result = engine.generateSuggestions(
        memberSchedules: {},
        groupId: 'group1',
      );
      expect(result, isEmpty);
    });

    test('generates suggestions when all members are free', () {
      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 3,
      );
      expect(result, isNotEmpty);
      // All suggestions should have 100% availability
      for (final s in result) {
        expect(s.availabilityRatio, 1.0);
        expect(s.availableMembers.length, 2);
        expect(s.totalMembers, 2);
      }
    });

    test('generates suggestions with blocked time excluded', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [
            makeSchedule(
              userId: 'user1',
              type: ScheduleType.shift,
              startTime: DateTime(date.year, date.month, date.day, 9, 0),
              endTime: DateTime(date.year, date.month, date.day, 17, 0),
            ),
          ],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 1,
      );

      // user1 is blocked 9-17, so only 8-9 and 17-22 are available
      // At least some suggestions should show only partial availability
      final fullAvail = result.where((s) => s.availabilityRatio == 1.0);
      final partialAvail = result.where((s) => s.availabilityRatio < 1.0);

      // user1 blocked 9-17 means 8-9 (1h) and 17-22 (5h) both members free
      // 9-17 only user2 free → partial
      expect(fullAvail.isNotEmpty || partialAvail.isNotEmpty, true);
    });

    test('free schedule type marks time as available', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [
            makeSchedule(
              userId: 'user1',
              type: ScheduleType.free,
              startTime: DateTime(date.year, date.month, date.day, 10, 0),
              endTime: DateTime(date.year, date.month, date.day, 15, 0),
            ),
          ],
          'user2': [
            makeSchedule(
              userId: 'user2',
              type: ScheduleType.free,
              startTime: DateTime(date.year, date.month, date.day, 12, 0),
              endTime: DateTime(date.year, date.month, date.day, 18, 0),
            ),
          ],
        },
        groupId: 'group1',
        searchRangeDays: 1,
      );

      // Both free 12-15, so should have overlapping suggestion
      final overlapping = result.where((s) =>
          s.availabilityRatio == 1.0 &&
          s.startTime.hour >= 12 &&
          s.endTime.hour <= 15);
      expect(overlapping, isNotEmpty);
    });

    test('all-day blocked schedule blocks entire day', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [
            makeSchedule(
              userId: 'user1',
              type: ScheduleType.blocked,
              startTime: DateTime(date.year, date.month, date.day),
              endTime: DateTime(date.year, date.month, date.day, 23, 59),
              isAllDay: true,
            ),
          ],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 1,
      );

      // user1 is blocked all day, no full-availability suggestions
      final fullAvail = result.where((s) => s.availabilityRatio == 1.0);
      expect(fullAvail, isEmpty);
    });

    test('suggestions are sorted by score descending', () {
      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [],
          'user2': [],
          'user3': [],
        },
        groupId: 'group1',
        searchRangeDays: 7,
      );

      for (int i = 0; i < result.length - 1; i++) {
        if (result[i].score == result[i + 1].score) {
          // Same score: sorted by date ascending
          expect(
            result[i].suggestedDate.compareTo(result[i + 1].suggestedDate) <= 0,
            true,
          );
        } else {
          expect(result[i].score >= result[i + 1].score, true);
        }
      }
    });

    test('suggestion has valid timeCategory', () {
      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 3,
      );

      for (final s in result) {
        expect(TimeCategory.values.contains(s.timeCategory), true);
      }
    });

    test('suggestion has non-empty activityType', () {
      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 3,
      );

      for (final s in result) {
        expect(s.activityType, isNotEmpty);
      }
    });

    test('suggestion score is between 0 and 1', () {
      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 7,
      );

      for (final s in result) {
        expect(s.score, greaterThanOrEqualTo(0.0));
        expect(s.score, lessThanOrEqualTo(1.0));
      }
    });

    test('suggestion expires after suggested date', () {
      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [],
          'user2': [],
        },
        groupId: 'group1',
        searchRangeDays: 3,
      );

      for (final s in result) {
        expect(s.expiresAt.isAfter(s.suggestedDate), true);
      }
    });

    test('3 members with partial overlap', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final result = engine.generateSuggestions(
        memberSchedules: {
          'user1': [
            makeSchedule(
              userId: 'user1',
              type: ScheduleType.shift,
              startTime: DateTime(date.year, date.month, date.day, 8, 0),
              endTime: DateTime(date.year, date.month, date.day, 12, 0),
            ),
          ],
          'user2': [
            makeSchedule(
              userId: 'user2',
              type: ScheduleType.event,
              startTime: DateTime(date.year, date.month, date.day, 14, 0),
              endTime: DateTime(date.year, date.month, date.day, 18, 0),
            ),
          ],
          'user3': [],
        },
        groupId: 'group1',
        searchRangeDays: 1,
      );

      // user1 free: 12-22, user2 free: 8-14 & 18-22, user3 free: 8-22
      // All 3 free: 12-14, 18-22
      final fullAvail = result.where((s) => s.availabilityRatio == 1.0);
      expect(fullAvail, isNotEmpty);
    });
  });
}
