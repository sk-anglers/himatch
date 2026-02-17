import 'package:flutter/material.dart';
import 'package:himatch/core/theme/app_colors_extension.dart';

export 'package:himatch/core/theme/app_colors_extension.dart';

abstract class AppColors {
  // Primary - Purple
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4834D4);

  // Secondary
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF8A80);

  // Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Text
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);

  // Status
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFE17055);

  // Schedule
  static const Color free = Color(0xFF00B894);
  static const Color busy = Color(0xFFE17055);
  static const Color tentative = Color(0xFFFDCB6E);

  // Weather
  static const Color weatherSunny = Color(0xFFF39C12);
  static const Color weatherCloudy = Color(0xFF95A5A6);
  static const Color weatherRainy = Color(0xFF3498DB);
  static const Color weatherSnowy = Color(0xFF74B9FF);
  static const Color weatherStorm = Color(0xFF6C5CE7);

  // Quick-input type palette
  static const Color typeParttime = Color(0xFFF39C12);
  static const Color typeClass = Color(0xFF3498DB);
  static const Color typeClub = Color(0xFF00B894);
  static const Color typeBusy = Color(0xFFE17055);
  static const Color typeFreeMorning = Color(0xFF1ABC9C);
  static const Color typeFreeAfternoon = Color(0xFF6C5CE7);
  static const Color typeFreeAllday = Color(0xFF27AE60);
  static const Color typeOff = Color(0xFFFF6B6B);

  // Heatmap
  static const Color heatmapFull = Color(0xFF00B894);
  static const Color heatmapHigh = Color(0xFF55EFC4);
  static const Color heatmapMedium = Color(0xFFFDCB6E);
  static const Color heatmapLow = Color(0xFFFFAB91);
  static const Color heatmapNone = Color(0xFFE0E0E0);

  // Mood
  static const Color moodGreat = Color(0xFF00B894);
  static const Color moodGood = Color(0xFF55EFC4);
  static const Color moodNeutral = Color(0xFFFDCB6E);
  static const Color moodLow = Color(0xFFFFAB91);
  static const Color moodBad = Color(0xFFE17055);
}

/// Theme color presets for user customization.
enum ThemePreset {
  purple('パープル', Color(0xFF6C5CE7)),
  pink('ピンク', Color(0xFFE84393)),
  blue('ブルー', Color(0xFF0984E3)),
  green('グリーン', Color(0xFF00B894)),
  orange('オレンジ', Color(0xFFF39C12)),
  mono('モノクロ', Color(0xFF636E72));

  const ThemePreset(this.label, this.seedColor);
  final String label;
  final Color seedColor;
}

abstract class AppTheme {
  /// Custom TextTheme based on design doc §4 type scale.
  static const _textThemeLight = TextTheme(
    displayLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleMedium: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    bodyLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
    bodySmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
    labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
  );

  static const _textThemeDark = TextTheme(
    displayLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE8E8E8)),
    titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFE8E8E8)),
    titleMedium: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFE8E8E8)),
    bodyLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.normal, color: Color(0xFFE8E8E8)),
    bodySmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.normal, color: Color(0xFFB0B0B0)),
    labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFB0B0B0)),
  );

  static ThemeData light({Color? seedColor}) {
    final seed = seedColor ?? AppColors.primary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textThemeLight,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          side: BorderSide(color: seed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: AppColors.surface,
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: const StadiumBorder(),
        indicatorColor: seed.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: seed);
          }
          return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      extensions: const [AppColorsExtension.light],
    );
  }

  static ThemeData dark({Color? seedColor}) {
    final seed = seedColor ?? AppColors.primary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: seed,
      secondary: AppColors.secondaryLight,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _textThemeDark,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          side: BorderSide(color: seed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: Color(0xFF16213E),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: const StadiumBorder(),
        indicatorColor: seed.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: seed);
          }
          return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB0B0B0));
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      extensions: const [AppColorsExtension.dark],
    );
  }
}
