import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/app_spacing.dart';
import 'package:himatch/core/theme/app_colors_extension.dart';
import 'package:himatch/providers/theme_providers.dart';

/// A glassmorphism card with frosted-glass effect.
///
/// Uses [BackdropFilter] + semi-transparent background + soft border.
/// When [glassEffectEnabled] is false in theme settings, falls back
/// to a simple semi-transparent container without blur.
class GlassCard extends ConsumerWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  /// Standard glass card with full blur effect.
  const GlassCard({
    super.key,
    required this.child,
    this.blur = AppSpacing.glassBlur,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  /// Lightweight glass card with reduced blur for use in lists/scrolls.
  const GlassCard.lite({
    super.key,
    required this.child,
    this.blur = AppSpacing.glassBlurLite,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final glassEnabled = ref.watch(
      themeSettingsProvider.select((s) => s.glassEffectEnabled),
    );
    final radius = borderRadius ?? AppSpacing.radiusLg;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glassEnabled
            ? colors.glassBackground
            : colors.surface.withValues(alpha: 0.85),
        borderRadius: radius,
        border: Border.all(
          color: glassEnabled ? colors.glassBorder : colors.glassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.glassShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (glassEnabled) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
