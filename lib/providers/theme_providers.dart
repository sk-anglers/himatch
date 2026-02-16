import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// User theme customization settings.
///
/// Stores the selected color [preset] and [isDarkMode] toggle.
/// Defaults to purple preset with light mode.
class ThemeSettings {
  /// The selected color preset from [ThemePreset].
  final ThemePreset preset;

  /// Whether dark mode is enabled.
  final bool isDarkMode;

  const ThemeSettings({
    this.preset = ThemePreset.purple,
    this.isDarkMode = false,
  });

  ThemeSettings copyWith({ThemePreset? preset, bool? isDarkMode}) {
    return ThemeSettings(
      preset: preset ?? this.preset,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// Notifier that manages theme customization state.
///
/// Provides methods to switch the color preset and toggle dark mode.
/// Will be persisted to SharedPreferences when connected.
class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => const ThemeSettings();

  /// Set the theme color preset.
  void setPreset(ThemePreset preset) {
    state = state.copyWith(preset: preset);
  }

  /// Toggle between light and dark mode.
  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  /// Explicitly set dark mode on or off.
  void setDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }
}

/// Local theme settings provider for offline-first development.
///
/// Manages the user's selected [ThemePreset] and dark mode toggle.
final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);
