import 'package:flutter_test/flutter_test.dart';
import 'package:himatch/models/suggestion.dart';

void main() {
  group('Suggestion', () {
    test('fromJson creates suggestion with weather', () {
      final json = {
        'id': 'suggestion-001',
        'group_id': 'group-001',
        'suggested_date': '2026-03-15T00:00:00.000Z',
        'start_time': '2026-03-15T18:00:00.000Z',
        'end_time': '2026-03-15T23:00:00.000Z',
        'duration_hours': 5.0,
        'time_category': 'evening',
        'activity_type': '飲み会',
        'available_members': ['user-001', 'user-002', 'user-003'],
        'total_members': 4,
        'availability_ratio': 0.75,
        'weather_summary': {
          'condition': '晴れ',
          'temp_high': 22.0,
          'temp_low': 14.0,
          'icon': '01d',
        },
        'score': 85.5,
        'status': 'proposed',
        'expires_at': '2026-03-14T00:00:00.000Z',
      };

      final suggestion = Suggestion.fromJson(json);

      expect(suggestion.activityType, '飲み会');
      expect(suggestion.timeCategory, TimeCategory.evening);
      expect(suggestion.availableMembers.length, 3);
      expect(suggestion.availabilityRatio, 0.75);
      expect(suggestion.weatherSummary?.condition, '晴れ');
      expect(suggestion.score, 85.5);
      expect(suggestion.status, SuggestionStatus.proposed);
    });

    test('fromJson creates suggestion without weather', () {
      final json = {
        'id': 'suggestion-002',
        'group_id': 'group-001',
        'suggested_date': '2026-03-20T00:00:00.000Z',
        'start_time': '2026-03-20T09:00:00.000Z',
        'end_time': '2026-03-20T21:00:00.000Z',
        'duration_hours': 12.0,
        'time_category': 'all_day',
        'activity_type': '日帰り旅行',
        'available_members': ['user-001', 'user-002'],
        'total_members': 2,
        'availability_ratio': 1.0,
        'score': 92.0,
        'status': 'proposed',
        'expires_at': '2026-03-19T00:00:00.000Z',
      };

      final suggestion = Suggestion.fromJson(json);

      expect(suggestion.timeCategory, TimeCategory.allDay);
      expect(suggestion.activityType, '日帰り旅行');
      expect(suggestion.weatherSummary, isNull);
      expect(suggestion.availabilityRatio, 1.0);
    });

    test('TimeCategory has all expected values', () {
      expect(TimeCategory.values.length, 5);
      expect(TimeCategory.values, contains(TimeCategory.morning));
      expect(TimeCategory.values, contains(TimeCategory.lunch));
      expect(TimeCategory.values, contains(TimeCategory.afternoon));
      expect(TimeCategory.values, contains(TimeCategory.evening));
      expect(TimeCategory.values, contains(TimeCategory.allDay));
    });
  });
}
