import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_entry.freezed.dart';
part 'mood_entry.g.dart';

enum MoodLevel {
  @JsonValue('great')
  great,
  @JsonValue('good')
  good,
  @JsonValue('neutral')
  neutral,
  @JsonValue('low')
  low,
  @JsonValue('bad')
  bad,
}

enum EnergyLevel {
  @JsonValue('high')
  high,
  @JsonValue('medium')
  medium,
  @JsonValue('low')
  low,
}

@freezed
abstract class MoodEntry with _$MoodEntry {
  const factory MoodEntry({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required DateTime date,
    required MoodLevel mood,
    EnergyLevel? energy,
    @JsonKey(name: 'stress_level') int? stressLevel,
    String? note,
    @JsonKey(name: 'related_schedule_id') String? relatedScheduleId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _MoodEntry;

  factory MoodEntry.fromJson(Map<String, dynamic> json) =>
      _$MoodEntryFromJson(json);
}
