import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_template.freezed.dart';
part 'event_template.g.dart';

@freezed
abstract class EventTemplate with _$EventTemplate {
  const factory EventTemplate({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'group_id') String? groupId,
    required String name,
    required String title,
    @JsonKey(name: 'default_start_time') String? defaultStartTime,
    @JsonKey(name: 'default_end_time') String? defaultEndTime,
    @JsonKey(name: 'is_all_day') @Default(false) bool isAllDay,
    String? location,
    String? memo,
    @JsonKey(name: 'icon_emoji') String? iconEmoji,
    @JsonKey(name: 'color_hex') String? colorHex,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _EventTemplate;

  factory EventTemplate.fromJson(Map<String, dynamic> json) =>
      _$EventTemplateFromJson(json);
}
