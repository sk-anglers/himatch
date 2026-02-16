import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('system')
  system,
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    required String content,
    @JsonKey(name: 'message_type') @Default(MessageType.text) MessageType messageType,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'related_suggestion_id') String? relatedSuggestionId,
    @Default({}) Map<String, List<String>> reactions,
    @JsonKey(name: 'read_by') @Default([]) List<String> readBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
