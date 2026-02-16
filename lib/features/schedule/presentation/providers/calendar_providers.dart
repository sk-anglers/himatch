import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  List<Schedule> build() => [];

  void addSchedule({
    required String title,
    required ScheduleType scheduleType,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? memo,
    String? color,
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [...state, schedule];
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
