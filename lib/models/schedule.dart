import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

enum ScheduleType {
  @JsonValue('shift')
  shift,
  @JsonValue('event')
  event,
  @JsonValue('free')
  free,
  @JsonValue('blocked')
  blocked,
}

enum Visibility {
  @JsonValue('public')
  public_,
  @JsonValue('friends')
  friends,
  @JsonValue('private')
  private_,
}

@freezed
abstract class Schedule with _$Schedule {
  const factory Schedule({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    @JsonKey(name: 'schedule_type') required ScheduleType scheduleType,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    @JsonKey(name: 'is_all_day') @Default(false) bool isAllDay,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @Default(Visibility.friends) Visibility visibility,
    String? color,
    String? memo,
    String? location,
    @JsonKey(name: 'shift_pattern_id') String? shiftPatternId,
    @JsonKey(name: 'shift_type_id') String? shiftTypeId,
    @JsonKey(name: 'workplace_id') String? workplaceId,
    @Default([]) List<int> reminders,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Schedule;

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
}
