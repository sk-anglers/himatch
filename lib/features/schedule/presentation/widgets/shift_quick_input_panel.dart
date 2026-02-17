import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// ナスカレ風ワンタップシフト入力パネル。
/// カレンダータブで日付選択時に表示される。
class ShiftQuickInputPanel extends ConsumerWidget {
  final DateTime selectedDay;
  final VoidCallback? onEditShiftTypes;

  const ShiftQuickInputPanel({
    super.key,
    required this.selectedDay,
    this.onEditShiftTypes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftTypes = ref.watch(shiftTypesProvider);
    final schedules = ref.watch(localSchedulesProvider);

    // 選択日の現在のシフトを取得
    final currentShift = _getCurrentShift(selectedDay, schedules);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー行
          Row(
            children: [
              const Icon(Icons.work_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              const Text(
                'シフト',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // クリアボタン
              if (currentShift != null)
                _ActionChip(
                  label: 'クリア',
                  icon: Icons.close,
                  onTap: () {
                    ref
                        .read(localSchedulesProvider.notifier)
                        .removeShiftForDate(selectedDay);
                  },
                ),
              const SizedBox(width: 4),
              // シフト編集ボタン
              _ActionChip(
                label: 'シフト編集',
                icon: Icons.edit_outlined,
                onTap: onEditShiftTypes,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // シフトボタングリッド
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shiftTypes.map((st) {
              final isSelected = currentShift?.shiftTypeId == st.id;
              return _ShiftButton(
                shiftType: st,
                isSelected: isSelected,
                onTap: () => _onShiftTap(ref, st, isSelected),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Schedule? _getCurrentShift(DateTime day, List<Schedule> schedules) {
    final targetDate = DateTime(day.year, day.month, day.day);
    return schedules.cast<Schedule?>().firstWhere(
      (s) {
        if (s!.shiftTypeId == null) return false;
        final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        return d == targetDate;
      },
      orElse: () => null,
    );
  }

  void _onShiftTap(WidgetRef ref, ShiftType st, bool isSelected) {
    if (isSelected) {
      // 同じシフトを再タップ → クリア
      ref.read(localSchedulesProvider.notifier).removeShiftForDate(selectedDay);
    } else {
      // 新シフトを割当（既存シフトは自動置換）
      ref.read(localSchedulesProvider.notifier).addShiftSchedule(
        date: selectedDay,
        shiftTypeId: st.id,
        title: st.name,
        color: st.colorHex,
        startTime: st.startTime,
        endTime: st.endTime,
        isOff: st.isOff,
      );
    }
  }
}

class _ShiftButton extends StatelessWidget {
  final ShiftType shiftType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShiftButton({
    required this.shiftType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = shiftTypeColor(shiftType);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shiftType.abbreviation,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            Text(
              shiftType.name,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : color.withValues(alpha: 0.7),
                fontSize: 9,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textHint.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
