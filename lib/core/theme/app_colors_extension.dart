import 'package:flutter/material.dart';

/// Theme-aware color extension that replaces hardcoded [AppColors] references.
///
/// Usage:
/// ```dart
/// final colors = Theme.of(context).extension<AppColorsExtension>()!;
/// Container(color: colors.surface);
/// ```
///
/// Migration note: AppColors static constants remain available for cases where
/// BuildContext is unavailable (e.g., provider logic). UI widgets should
/// gradually migrate to this extension for proper dark mode support.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.success,
    required this.warning,
    required this.error,
    required this.glassBackground,
    required this.glassBorder,
    required this.glassShadow,
    required this.gradientStart,
    required this.gradientMiddle,
    required this.gradientEnd,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryLight;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color success;
  final Color warning;
  final Color error;

  // Glass morphism colors
  final Color glassBackground;
  final Color glassBorder;
  final Color glassShadow;
  final Color gradientStart;
  final Color gradientMiddle;
  final Color gradientEnd;

  /// Generate gradient colors from a seed color using HSL hue rotation.
  static ({Color start, Color middle, Color end}) gradientFromSeed(
    Color seedColor, {
    required bool isDark,
  }) {
    final hsl = HSLColor.fromColor(seedColor);
    final baseLightness = isDark ? 0.15 : 0.92;
    final baseSaturation = isDark ? 0.6 : 0.55;
    return (
      start: HSLColor.fromAHSL(
        1.0,
        (hsl.hue - 20) % 360,
        baseSaturation,
        baseLightness,
      ).toColor(),
      middle: HSLColor.fromAHSL(
        1.0,
        hsl.hue,
        baseSaturation * 0.8,
        isDark ? baseLightness + 0.05 : baseLightness - 0.02,
      ).toColor(),
      end: HSLColor.fromAHSL(
        1.0,
        (hsl.hue + 20) % 360,
        baseSaturation,
        baseLightness,
      ).toColor(),
    );
  }

  /// Light theme colors (matches current AppColors defaults).
  static const light = AppColorsExtension(
    primary: Color(0xFF6C5CE7),
    primaryLight: Color(0xFFA29BFE),
    primaryDark: Color(0xFF4834D4),
    secondary: Color(0xFFFF6B6B),
    secondaryLight: Color(0xFFFF8A80),
    background: Color(0xFFF8F9FA),
    surface: Colors.white,
    surfaceVariant: Color(0xFFF1F3F5),
    textPrimary: Color(0xFF2D3436),
    textSecondary: Color(0xFF636E72),
    textHint: Color(0xFFB2BEC3),
    success: Color(0xFF00B894),
    warning: Color(0xFFFDCB6E),
    error: Color(0xFFE17055),
    glassBackground: Color(0x26FFFFFF),
    glassBorder: Color(0x4DFFFFFF),
    glassShadow: Color(0x1A000000),
    gradientStart: Color(0xFFE8DEFF),
    gradientMiddle: Color(0xFFF0E6FF),
    gradientEnd: Color(0xFFDEE8FF),
  );

  /// Dark theme colors.
  static const dark = AppColorsExtension(
    primary: Color(0xFFA29BFE),
    primaryLight: Color(0xFF6C5CE7),
    primaryDark: Color(0xFFD4C4FF),
    secondary: Color(0xFFFF8A80),
    secondaryLight: Color(0xFFFF6B6B),
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF16213E),
    surfaceVariant: Color(0xFF0F3460),
    textPrimary: Color(0xFFE8E8E8),
    textSecondary: Color(0xFFB0B0B0),
    textHint: Color(0xFF666666),
    success: Color(0xFF55EFC4),
    warning: Color(0xFFFDCB6E),
    error: Color(0xFFFF7675),
    glassBackground: Color(0x14FFFFFF),
    glassBorder: Color(0x26FFFFFF),
    glassShadow: Color(0x33000000),
    gradientStart: Color(0xFF1A1A3E),
    gradientMiddle: Color(0xFF16213E),
    gradientEnd: Color(0xFF0F1A3E),
  );

  /// Create extension with dynamic gradient colors from seed.
  AppColorsExtension withSeedGradient(Color seedColor, {required bool isDark}) {
    final grad = gradientFromSeed(seedColor, isDark: isDark);
    return copyWith(
      gradientStart: grad.start,
      gradientMiddle: grad.middle,
      gradientEnd: grad.end,
    );
  }

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? secondaryLight,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? success,
    Color? warning,
    Color? error,
    Color? glassBackground,
    Color? glassBorder,
    Color? glassShadow,
    Color? gradientStart,
    Color? gradientMiddle,
    Color? gradientEnd,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShadow: glassShadow ?? this.glassShadow,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMiddle: gradientMiddle ?? this.gradientMiddle,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientMiddle: Color.lerp(gradientMiddle, other.gradientMiddle, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}
