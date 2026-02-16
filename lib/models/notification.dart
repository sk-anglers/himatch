import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

enum NotificationType {
  @JsonValue('suggestion_new')
  suggestionNew,
  @JsonValue('suggestion_accepted')
  suggestionAccepted,
  @JsonValue('group_invite')
  groupInvite,
  @JsonValue('schedule_updated')
  scheduleUpdated,
  @JsonValue('member_joined')
  memberJoined,
}

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required NotificationType type,
    required String title,
    required String body,
    @JsonKey(name: 'related_id') String? relatedId,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
