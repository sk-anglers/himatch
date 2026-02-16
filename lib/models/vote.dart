import 'package:freezed_annotation/freezed_annotation.dart';

part 'vote.freezed.dart';
part 'vote.g.dart';

enum VoteType {
  @JsonValue('ok')
  ok,
  @JsonValue('maybe')
  maybe,
  @JsonValue('ng')
  ng,
}

@freezed
abstract class Vote with _$Vote {
  const factory Vote({
    required String id,
    @JsonKey(name: 'suggestion_id') required String suggestionId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'vote_type') required VoteType voteType,
    @JsonKey(name: 'voted_at') required DateTime votedAt,
  }) = _Vote;

  factory Vote.fromJson(Map<String, dynamic> json) => _$VoteFromJson(json);
}
