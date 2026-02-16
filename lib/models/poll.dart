import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll.freezed.dart';
part 'poll.g.dart';

@freezed
abstract class PollOption with _$PollOption {
  const factory PollOption({
    required String id,
    required String text,
    @Default([]) List<String> voterIds,
    @Default([]) List<String> voterNames,
  }) = _PollOption;

  factory PollOption.fromJson(Map<String, dynamic> json) =>
      _$PollOptionFromJson(json);
}

@freezed
abstract class Poll with _$Poll {
  const factory Poll({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'creator_name') required String creatorName,
    required String question,
    required List<PollOption> options,
    @JsonKey(name: 'is_multi_select') @Default(false) bool isMultiSelect,
    @JsonKey(name: 'is_anonymous') @Default(false) bool isAnonymous,
    @JsonKey(name: 'deadline') DateTime? deadline,
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}
