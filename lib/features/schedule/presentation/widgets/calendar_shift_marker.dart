import 'package:flutter/material.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// CalendarBuilders.markerBuilder 用ファクトリ。
/// シフト付きスケジュールはカラーバッジ、それ以外はドットで表示。
Widget? buildCalendarShiftMarker(
  BuildContext context,
  DateTime day,
  List<Schedule> events,
  Map<String, ShiftType> shiftTypeMap,
) {
  if (events.isEmpty) return null;

  // シフト付きイベントを優先表示
  final shiftEvent = events.cast<Schedule?>().firstWhere(
    (e) => e!.shiftTypeId != null,
    orElse: () => null,
  );

  if (shiftEvent != null) {
    final shiftType = shiftTypeMap[shiftEvent.shiftTypeId];
    if (shiftType != null) {
      final color = shiftTypeColor(shiftType);
      return Positioned(
        bottom: 1,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            shiftType.abbreviation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      );
    }
  }

  // シフト以外の予定はドット表示（最大3つ）
  final nonShiftEvents = events.where((e) => e.shiftTypeId == null).toList();
  if (nonShiftEvents.isEmpty) return null;

  return Positioned(
    bottom: 1,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: nonShiftEvents.take(3).map((event) {
        final color = _scheduleTypeColor(event.scheduleType);
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    ),
  );
}

Color _scheduleTypeColor(ScheduleType type) {
  return switch (type) {
    ScheduleType.shift => AppColors.primary,
    ScheduleType.event => AppColors.warning,
    ScheduleType.free => AppColors.success,
    ScheduleType.blocked => AppColors.error,
  };
}
