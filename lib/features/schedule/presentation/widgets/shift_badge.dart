import 'package:flutter/material.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// カレンダーセルやカード内で使う再利用可能なシフトバッジ。
/// 略称テキスト + 背景色で表示（例: 青地に白「日」）。
class ShiftBadge extends StatelessWidget {
  final ShiftType shiftType;
  final double size;

  const ShiftBadge({
    super.key,
    required this.shiftType,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final color = shiftTypeColor(shiftType);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        shiftType.abbreviation,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}

/// インライン表示用（カード内テキスト横など）のコンパクトバッジ。
class ShiftBadgeInline extends StatelessWidget {
  final ShiftType shiftType;

  const ShiftBadgeInline({super.key, required this.shiftType});

  @override
  Widget build(BuildContext context) {
    final color = shiftTypeColor(shiftType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        shiftType.name,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
