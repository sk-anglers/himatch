import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit.freezed.dart';
part 'habit.g.dart';

@freezed
abstract class HabitLog with _$HabitLog {
  const factory HabitLog({
    required DateTime date,
    @Default(true) bool completed,
    String? note,
  }) = _HabitLog;

  factory HabitLog.fromJson(Map<String, dynamic> json) =>
      _$HabitLogFromJson(json);
}

@freezed
abstract class Habit with _$Habit {
  const factory Habit({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'icon_emoji') @Default('✅') String iconEmoji,
    @JsonKey(name: 'color_hex') @Default('FF6C5CE7') String colorHex,
    @JsonKey(name: 'target_days_per_week') @Default(7) int targetDaysPerWeek,
    @JsonKey(name: 'reminder_time') String? reminderTime,
    required List<HabitLog> logs,
    @JsonKey(name: 'current_streak') @Default(0) int currentStreak,
    @JsonKey(name: 'best_streak') @Default(0) int bestStreak,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Habit;

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
}
