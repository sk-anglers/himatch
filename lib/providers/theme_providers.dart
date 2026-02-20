import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// User theme customization settings.
///
/// Stores the selected color [preset], [isDarkMode] toggle,
/// and [glassEffectEnabled] for glassmorphism ON/OFF.
class ThemeSettings {
  /// The selected color preset from [ThemePreset].
  final ThemePreset preset;

  /// Whether dark mode is enabled.
  final bool isDarkMode;

  /// Whether glassmorphism effects (BackdropFilter blur) are enabled.
  /// Disable on low-end devices for better performance.
  final bool glassEffectEnabled;

  const ThemeSettings({
    this.preset = ThemePreset.purple,
    this.isDarkMode = false,
    this.glassEffectEnabled = true,
  });

  ThemeSettings copyWith({
    ThemePreset? preset,
    bool? isDarkMode,
    bool? glassEffectEnabled,
  }) {
    return ThemeSettings(
      preset: preset ?? this.preset,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      glassEffectEnabled: glassEffectEnabled ?? this.glassEffectEnabled,
    );
  }
}

/// Notifier that manages theme customization state.
///
/// Provides methods to switch the color preset, toggle dark mode,
/// and control glassmorphism effects.
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

  /// Toggle glassmorphism effects on or off.
  void toggleGlassEffect() {
    state = state.copyWith(glassEffectEnabled: !state.glassEffectEnabled);
  }

  /// Explicitly set glass effect on or off.
  void setGlassEffect(bool value) {
    state = state.copyWith(glassEffectEnabled: value);
  }
}

/// Local theme settings provider for offline-first development.
///
/// Manages the user's selected [ThemePreset] and dark mode toggle.
final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);
