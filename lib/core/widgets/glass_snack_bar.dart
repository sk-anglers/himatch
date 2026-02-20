import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:himatch/core/constants/app_spacing.dart';
import 'package:himatch/core/theme/app_colors_extension.dart';

/// Shows a glassmorphism-styled top banner notification.
///
/// Uses [OverlayEntry] for positioning at the top of the screen
/// with blur backdrop and entrance/exit animations.
void showGlassSnackBar(
  BuildContext context, {
  required String message,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
  Color? iconColor,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _GlassSnackBarWidget(
      message: message,
      icon: icon,
      iconColor: iconColor,
      onDismiss: () => entry.remove(),
      duration: duration,
    ),
  );

  overlay.insert(entry);
}

class _GlassSnackBarWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onDismiss;
  final Duration duration;

  const _GlassSnackBarWidget({
    required this.message,
    this.icon,
    this.iconColor,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_GlassSnackBarWidget> createState() => _GlassSnackBarWidgetState();
}

class _GlassSnackBarWidgetState extends State<_GlassSnackBarWidget> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: AppSpacing.radiusLg,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppSpacing.glassBlur,
              sigmaY: AppSpacing.glassBlur,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.glassBackground,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: colors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.glassShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.iconColor ?? colors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: colors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .slideY(begin: -0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
          .scale(begin: const Offset(0.96, 0.96), duration: 300.ms),
    );
  }
}
