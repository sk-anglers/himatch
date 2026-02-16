import 'package:flutter/material.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// リスト型カレンダーの1行Widget。
/// メンバー名 + シフトバッジ or 時間帯を表示。
class ShiftListRow extends StatelessWidget {
  final String memberName;
  final Color memberColor;
  final List<Schedule> schedules;
  final Map<String, ShiftType> shiftTypeMap;
  final bool showTimeMode;

  const ShiftListRow({
    super.key,
    required this.memberName,
    required this.memberColor,
    required this.schedules,
    required this.shiftTypeMap,
    this.showTimeMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // メンバー名（固定幅）
          SizedBox(
            width: 72,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: memberColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    memberName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // シフト内容
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (schedules.isEmpty) {
      return const Text(
        '空き',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 12,
        ),
      );
    }

    // シフト付き予定を優先
    final shiftSchedule = schedules.cast<Schedule?>().firstWhere(
      (s) => s!.shiftTypeId != null,
      orElse: () => null,
    );

    if (shiftSchedule != null) {
      final st = shiftTypeMap[shiftSchedule.shiftTypeId];
      if (st != null) {
        final color = shiftTypeColor(st);
        if (showTimeMode && st.startTime != null) {
          return Text(
            '${st.startTime} - ${st.endTime}',
            style: TextStyle(fontSize: 12, color: color),
          );
        }
        return Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                st.abbreviation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              st.name,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        );
      }
    }

    // 通常の予定
    final first = schedules.first;
    return Text(
      first.isAllDay
          ? first.title
          : '${AppDateUtils.formatTime(first.startTime)} ${first.title}',
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
    );
  }
}
