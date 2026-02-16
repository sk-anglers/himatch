import 'package:flutter_test/flutter_test.dart';
import 'package:himatch/models/schedule.dart';

void main() {
  group('Schedule', () {
    test('fromJson creates schedule correctly', () {
      final json = {
        'id': 'schedule-001',
        'user_id': 'user-001',
        'title': '早番',
        'schedule_type': 'shift',
        'start_time': '2026-03-15T06:00:00.000Z',
        'end_time': '2026-03-15T15:00:00.000Z',
        'is_all_day': false,
        'visibility': 'friends',
      };

      final schedule = Schedule.fromJson(json);

      expect(schedule.title, '早番');
      expect(schedule.scheduleType, ScheduleType.shift);
      expect(schedule.isAllDay, false);
      expect(schedule.visibility, Visibility.friends);
      expect(schedule.startTime.year, 2026);
    });

    test('toJson serializes enum values correctly', () {
      final schedule = Schedule(
        id: 'test-id',
        userId: 'user-001',
        title: '空き時間',
        scheduleType: ScheduleType.free,
        startTime: DateTime(2026, 3, 15, 18, 0),
        endTime: DateTime(2026, 3, 15, 23, 0),
      );

      final json = schedule.toJson();

      expect(json['schedule_type'], 'free');
      expect(json['visibility'], 'friends');
      expect(json['is_all_day'], false);
    });

    test('ScheduleType enum has all expected values', () {
      expect(ScheduleType.values.length, 4);
      expect(ScheduleType.values, contains(ScheduleType.shift));
      expect(ScheduleType.values, contains(ScheduleType.event));
      expect(ScheduleType.values, contains(ScheduleType.free));
      expect(ScheduleType.values, contains(ScheduleType.blocked));
    });
  });
}
