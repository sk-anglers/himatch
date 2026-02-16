import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

enum ActivityType {
  @JsonValue('schedule_added')
  scheduleAdded,
  @JsonValue('schedule_updated')
  scheduleUpdated,
  @JsonValue('suggestion_created')
  suggestionCreated,
  @JsonValue('vote_cast')
  voteCast,
  @JsonValue('suggestion_confirmed')
  suggestionConfirmed,
  @JsonValue('member_joined')
  memberJoined,
  @JsonValue('member_left')
  memberLeft,
  @JsonValue('photo_added')
  photoAdded,
  @JsonValue('todo_completed')
  todoCompleted,
  @JsonValue('poll_created')
  pollCreated,
}

@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    required ActivityType type,
    required String message,
    @JsonKey(name: 'related_id') String? relatedId,
    @Default({}) Map<String, List<String>> reactions,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
