import 'package:flutter/widgets.dart';

/// Design-system spacing constants (multiples of 4px).
///
/// Usage:
/// ```dart
/// Padding(padding: EdgeInsets.all(AppSpacing.md))
/// SizedBox(height: AppSpacing.lg)
/// ```
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Border radius
  static const double borderRadiusSm = 12;
  static const double borderRadiusMd = 16;
  static const double borderRadiusLg = 20;
  static const double borderRadiusXl = 24;

  static final BorderRadius radiusLg = BorderRadius.circular(borderRadiusLg);
  static final BorderRadius radiusXl = BorderRadius.circular(borderRadiusXl);

  // Glass blur
  static const double glassBlur = 20;
  static const double glassBlurLite = 10;
}
