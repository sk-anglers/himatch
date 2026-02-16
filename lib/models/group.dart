import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@freezed
abstract class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'icon_url') String? iconUrl,
    @JsonKey(name: 'invite_code') required String inviteCode,
    @JsonKey(name: 'invite_code_expires_at') DateTime? inviteCodeExpiresAt,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'max_members') @Default(20) int maxMembers,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}

@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'user_id') required String userId,
    @Default('member') String role,
    String? nickname,
    @JsonKey(name: 'joined_at') DateTime? joinedAt,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
