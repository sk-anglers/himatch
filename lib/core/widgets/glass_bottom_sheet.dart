import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:himatch/core/constants/app_spacing.dart';
import 'package:himatch/core/theme/app_colors_extension.dart';

/// Shows a modal bottom sheet with glassmorphism styling.
///
/// The sheet features a frosted-glass background with blur effect
/// and semi-transparent styling consistent with the glass design system.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  double? maxHeight,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black38,
    constraints: maxHeight != null
        ? BoxConstraints(maxHeight: maxHeight)
        : null,
    builder: (context) {
      return _GlassBottomSheetWrapper(builder: builder);
    },
  );
}

class _GlassBottomSheetWrapper extends StatelessWidget {
  final WidgetBuilder builder;

  const _GlassBottomSheetWrapper({required this.builder});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSpacing.glassBlur,
          sigmaY: AppSpacing.glassBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.glassBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.borderRadiusXl),
            ),
            border: Border(
              top: BorderSide(color: colors.glassBorder),
              left: BorderSide(color: colors.glassBorder),
              right: BorderSide(color: colors.glassBorder),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      ),
    );
  }
}
