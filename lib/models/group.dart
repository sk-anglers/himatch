import 'package:flutter/painting.dart';
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
    @JsonKey(name: 'color_hex') String? colorHex,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}

/// Default color palette for groups (index-based fallback).
const _defaultGroupColors = [
  'FF3498DB', // blue
  'FFF39C12', // orange
  'FF00B894', // green
  'FFE84393', // pink
  'FF6C5CE7', // purple
  'FFE17055', // red
  'FF0984E3', // ocean
  'FF636E72', // gray
];

/// Predefined color options for the group color picker.
const groupColorOptions = _defaultGroupColors;

/// Returns a [Color] for the given group.
/// Uses [Group.colorHex] if set, otherwise falls back to a palette color
/// based on the group name's hash.
Color groupColor(Group group) {
  if (group.colorHex != null && group.colorHex!.isNotEmpty) {
    return Color(int.parse(group.colorHex!, radix: 16));
  }
  final index = group.name.hashCode.abs() % _defaultGroupColors.length;
  return Color(int.parse(_defaultGroupColors[index], radix: 16));
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
