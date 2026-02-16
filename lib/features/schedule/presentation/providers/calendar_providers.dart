import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/demo_data.dart';
import 'package:himatch/models/schedule.dart';
import 'package:uuid/uuid.dart';

/// Local schedule state for offline-first development.
/// Will be replaced with Supabase-backed provider when connected.
final localSchedulesProvider =
    NotifierProvider<LocalSchedulesNotifier, List<Schedule>>(
  LocalSchedulesNotifier.new,
);

class LocalSchedulesNotifier extends Notifier<List<Schedule>> {
  static const _uuid = Uuid();

  @override
  List<Schedule> build() => DemoData.generateMySchedules();

  void addSchedule({
    required String title,
    required ScheduleType scheduleType,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? memo,
    String? color,
    String? shiftTypeId,
  }) {
    final schedule = Schedule(
      id: _uuid.v4(),
      userId: 'local-user',
      title: title,
      scheduleType: scheduleType,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      memo: memo,
      color: color,
      shiftTypeId: shiftTypeId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [...state, schedule];
  }

  /// ワンタップシフト入力: 指定日のシフトを置換（1日1シフトルール）
  void addShiftSchedule({
    required DateTime date,
    required String shiftTypeId,
    required String title,
    String? color,
    String? startTime,
    String? endTime,
    bool isOff = false,
  }) {
    // 既存のシフトを除去（同日のshift種別のみ）
    removeShiftForDate(date);

    final dayStart = DateTime(date.year, date.month, date.day);
    DateTime scheduleStart;
    DateTime scheduleEnd;

    if (startTime != null && endTime != null) {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      scheduleStart = DateTime(
        date.year, date.month, date.day,
        int.parse(startParts[0]), int.parse(startParts[1]),
      );
      scheduleEnd = DateTime(
        date.year, date.month, date.day,
        int.parse(endParts[0]), int.parse(endParts[1]),
      );
      // 夜勤等: 終了 < 開始の場合は翌日扱い
      if (scheduleEnd.isBefore(scheduleStart)) {
        scheduleEnd = scheduleEnd.add(const Duration(days: 1));
      }
    } else {
      // 終日（休み・明け等）
      scheduleStart = dayStart;
      scheduleEnd = dayStart.add(const Duration(days: 1));
    }

    final schedule = Schedule(
      id: _uuid.v4(),
      userId: 'local-user',
      title: title,
      scheduleType: isOff ? ScheduleType.free : ScheduleType.shift,
      startTime: scheduleStart,
      endTime: scheduleEnd,
      isAllDay: startTime == null,
      color: color,
      shiftTypeId: shiftTypeId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [...state, schedule];
  }

  /// 指定日のシフト種別スケジュールを削除
  void removeShiftForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    state = state.where((s) {
      if (s.shiftTypeId == null) return true; // シフト以外は残す
      final scheduleDate = DateTime(
        s.startTime.year, s.startTime.month, s.startTime.day,
      );
      return scheduleDate != targetDate;
    }).toList();
  }

  void updateSchedule(Schedule updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
  }

  void removeSchedule(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}
