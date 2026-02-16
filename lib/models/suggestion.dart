import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggestion.freezed.dart';
part 'suggestion.g.dart';

enum TimeCategory {
  @JsonValue('morning')
  morning,
  @JsonValue('lunch')
  lunch,
  @JsonValue('afternoon')
  afternoon,
  @JsonValue('evening')
  evening,
  @JsonValue('all_day')
  allDay,
}

enum SuggestionStatus {
  @JsonValue('proposed')
  proposed,
  @JsonValue('accepted')
  accepted,
  @JsonValue('declined')
  declined,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('expired')
  expired,
}

@freezed
abstract class WeatherSummary with _$WeatherSummary {
  const factory WeatherSummary({
    required String condition,
    @JsonKey(name: 'temp_high') double? tempHigh,
    @JsonKey(name: 'temp_low') double? tempLow,
    String? icon,
  }) = _WeatherSummary;

  factory WeatherSummary.fromJson(Map<String, dynamic> json) =>
      _$WeatherSummaryFromJson(json);
}

@freezed
abstract class Suggestion with _$Suggestion {
  const factory Suggestion({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'suggested_date') required DateTime suggestedDate,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    @JsonKey(name: 'duration_hours') required double durationHours,
    @JsonKey(name: 'time_category') required TimeCategory timeCategory,
    @JsonKey(name: 'activity_type') required String activityType,
    @JsonKey(name: 'available_members') required List<String> availableMembers,
    @JsonKey(name: 'total_members') required int totalMembers,
    @JsonKey(name: 'availability_ratio') required double availabilityRatio,
    @JsonKey(name: 'weather_summary') WeatherSummary? weatherSummary,
    String? location,
    @JsonKey(name: 'location_name') String? locationName,
    required double score,
    @Default(SuggestionStatus.proposed) SuggestionStatus status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _Suggestion;

  factory Suggestion.fromJson(Map<String, dynamic> json) =>
      _$SuggestionFromJson(json);
}
