import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Skeleton placeholder card with shimmer animation.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: 140, color: colors.textHint),
            const SizedBox(height: 12),
            _SkeletonLine(width: double.infinity, color: colors.textHint),
            const SizedBox(height: 8),
            _SkeletonLine(width: 200, color: colors.textHint),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: colors.surface.withValues(alpha: 0.5));
  }
}

/// A list of skeleton cards for loading states.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const SkeletonList({super.key, this.count = 3, this.itemHeight = 120});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (_, _) => SkeletonCard(height: itemHeight),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final Color color;
  const _SkeletonLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}
