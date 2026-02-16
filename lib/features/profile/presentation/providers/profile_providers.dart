import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local profile settings for offline-first development.
/// Will be replaced with Supabase-backed + SharedPreferences when connected.

class ProfileSettings {
  final String displayName;
  final String? avatarUrl;
  final bool notificationsEnabled;
  final String defaultVisibility; // 'public', 'friends', 'private'

  const ProfileSettings({
    this.displayName = 'ユーザー',
    this.avatarUrl,
    this.notificationsEnabled = true,
    this.defaultVisibility = 'friends',
  });

  ProfileSettings copyWith({
    String? displayName,
    String? avatarUrl,
    bool? notificationsEnabled,
    String? defaultVisibility,
  }) {
    return ProfileSettings(
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultVisibility: defaultVisibility ?? this.defaultVisibility,
    );
  }
}

final profileSettingsProvider =
    NotifierProvider<ProfileSettingsNotifier, ProfileSettings>(
  ProfileSettingsNotifier.new,
);

class ProfileSettingsNotifier extends Notifier<ProfileSettings> {
  @override
  ProfileSettings build() => const ProfileSettings();

  void updateDisplayName(String name) {
    state = state.copyWith(displayName: name);
  }

  void toggleNotifications() {
    state = state.copyWith(
        notificationsEnabled: !state.notificationsEnabled);
  }

  void setDefaultVisibility(String visibility) {
    state = state.copyWith(defaultVisibility: visibility);
  }
}
