import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    @JsonKey(name: 'display_name') required String displayName,
    String? email,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'auth_provider') required String authProvider,
    @JsonKey(name: 'auth_provider_id') required String authProviderId,
    @JsonKey(name: 'device_token') String? deviceToken,
    @Default('Asia/Tokyo') String timezone,
    @JsonKey(name: 'privacy_default') @Default('friends') String privacyDefault,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
