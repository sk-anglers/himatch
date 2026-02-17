import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/habit.dart';
import 'package:himatch/models/mood_entry.dart';
import 'package:uuid/uuid.dart';

// ── Habit Tracking ──

/// Local habit tracking state for offline-first development.
///
/// Manages habits with daily completion logs and streak tracking.
final habitsProvider = NotifierProvider<HabitsNotifier, List<Habit>>(
  HabitsNotifier.new,
);

/// Notifier that manages user habit entries and daily logs.
class HabitsNotifier extends Notifier<List<Habit>> {
  static const _uuid = Uuid();

  @override
  List<Habit> build() => [];

  /// Add a new habit to track.
  ///
  /// [targetDaysPerWeek] sets the weekly goal (1-7).
  /// [reminderTime] is an optional time string (e.g. "08:00") for notifications.
  void addHabit({
    required String name,
    String iconEmoji = '\u2705',
    int targetDaysPerWeek = 7,
    String? reminderTime,
    String colorHex = 'FF6C5CE7',
  }) {
    final habit = Habit(
      id: _uuid.v4(),
      userId: AppConstants.localUserId,
      name: name,
      iconEmoji: iconEmoji,
      colorHex: colorHex,
      targetDaysPerWeek: targetDaysPerWeek,
      reminderTime: reminderTime,
      logs: const [],
      currentStreak: 0,
      bestStreak: 0,
      createdAt: DateTime.now(),
    );
    state = [...state, habit];
  }

  /// Toggle habit completion for a specific date.
  ///
  /// If the habit was already logged for that date, removes the log.
  /// Otherwise, adds a new completed log entry and recalculates streaks.
  void toggleHabitLog(String habitId, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    state = [
      for (final h in state)
        if (h.id == habitId) _toggleLog(h, normalizedDate) else h,
    ];
  }

  /// Remove a habit by ID.
  void removeHabit(String id) {
    state = state.where((h) => h.id != id).toList();
  }

  /// Get the current streak for a habit (consecutive days completed).
  ///
  /// Counts backwards from today, returning the number of consecutive
  /// days the habit was completed.
  int getStreak(String habitId) {
    final habit = state.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) return 0;
    return _calculateStreak(habit.logs);
  }

  /// Toggle a log entry and recalculate streaks.
  Habit _toggleLog(Habit habit, DateTime date) {
    final existingIndex = habit.logs.indexWhere((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      return logDate == date;
    });

    List<HabitLog> updatedLogs;
    if (existingIndex >= 0) {
      // Remove existing log
      updatedLogs = List<HabitLog>.from(habit.logs)..removeAt(existingIndex);
    } else {
      // Add new completed log
      updatedLogs = [
        ...habit.logs,
        HabitLog(date: date, completed: true),
      ];
    }

    final currentStreak = _calculateStreak(updatedLogs);
    final bestStreak =
        currentStreak > habit.bestStreak ? currentStreak : habit.bestStreak;

    return habit.copyWith(
      logs: updatedLogs,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  /// Calculate consecutive day streak from today going backwards.
  int _calculateStreak(List<HabitLog> logs) {
    if (logs.isEmpty) return 0;

    final completedDates = logs
        .where((l) => l.completed)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();

    var streak = 0;
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    while (completedDates.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

// ── Mood Tracking ──

/// Weekly mood report aggregation.
class MoodReport {
  final double averageMood;
  final double? averageEnergy;
  final int entryCount;
  final Map<MoodLevel, int> moodDistribution;
  final String? patternInsight;

  const MoodReport({
    required this.averageMood,
    this.averageEnergy,
    required this.entryCount,
    required this.moodDistribution,
    this.patternInsight,
  });
}

/// Local mood tracking state for offline-first development.
///
/// Manages daily mood/energy/stress entries for self-awareness.
final moodEntriesProvider =
    NotifierProvider<MoodEntriesNotifier, List<MoodEntry>>(
  MoodEntriesNotifier.new,
);

/// Notifier that manages mood journal entries.
class MoodEntriesNotifier extends Notifier<List<MoodEntry>> {
  static const _uuid = Uuid();

  @override
  List<MoodEntry> build() => [];

  /// Add a new mood entry.
  ///
  /// [stressLevel] is 1-5 scale where 1 = low stress, 5 = high stress.
  /// [relatedScheduleId] optionally links mood to a specific schedule event.
  void addEntry({
    required DateTime date,
    required MoodLevel mood,
    EnergyLevel? energy,
    int? stressLevel,
    String? note,
    String? relatedScheduleId,
  }) {
    final entry = MoodEntry(
      id: _uuid.v4(),
      userId: AppConstants.localUserId,
      date: DateTime(date.year, date.month, date.day),
      mood: mood,
      energy: energy,
      stressLevel: stressLevel,
      note: note,
      relatedScheduleId: relatedScheduleId,
      createdAt: DateTime.now(),
    );

    // Replace existing entry for the same date, if any
    final existing = state.indexWhere((e) {
      final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
      final newDate = DateTime(date.year, date.month, date.day);
      return entryDate == newDate;
    });

    if (existing >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existing) entry else state[i],
      ];
    } else {
      state = [...state, entry];
    }
  }

  /// Get mood entries within a date range.
  List<MoodEntry> getEntries(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day, 23, 59, 59);

    return state
        .where((e) => !e.date.isBefore(fromDate) && !e.date.isAfter(toDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Generate a weekly mood report for the past 7 days.
  ///
  /// Calculates average mood/energy scores and identifies patterns.
  MoodReport getWeeklyReport() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final entries = getEntries(weekAgo, now);

    if (entries.isEmpty) {
      return const MoodReport(
        averageMood: 0,
        entryCount: 0,
        moodDistribution: {},
      );
    }

    // Mood level to numeric value for averaging
    double moodToValue(MoodLevel mood) {
      switch (mood) {
        case MoodLevel.great:
          return 5.0;
        case MoodLevel.good:
          return 4.0;
        case MoodLevel.neutral:
          return 3.0;
        case MoodLevel.low:
          return 2.0;
        case MoodLevel.bad:
          return 1.0;
      }
    }

    double energyToValue(EnergyLevel energy) {
      switch (energy) {
        case EnergyLevel.high:
          return 3.0;
        case EnergyLevel.medium:
          return 2.0;
        case EnergyLevel.low:
          return 1.0;
      }
    }

    final moodSum = entries.fold<double>(
        0, (sum, e) => sum + moodToValue(e.mood));
    final avgMood = moodSum / entries.length;

    // Energy average (only for entries that have energy data)
    final energyEntries = entries.where((e) => e.energy != null).toList();
    double? avgEnergy;
    if (energyEntries.isNotEmpty) {
      final energySum = energyEntries.fold<double>(
          0, (sum, e) => sum + energyToValue(e.energy!));
      avgEnergy = energySum / energyEntries.length;
    }

    // Mood distribution
    final distribution = <MoodLevel, int>{};
    for (final entry in entries) {
      distribution[entry.mood] = (distribution[entry.mood] ?? 0) + 1;
    }

    // Simple pattern insight
    String? insight;
    if (avgMood >= 4.0) {
      insight = 'Good week overall! Keep up the positive momentum.';
    } else if (avgMood <= 2.0) {
      insight = 'Tough week. Consider reaching out to friends or taking a break.';
    } else if (entries.length >= 5) {
      // Check for trend (improving or declining)
      final firstHalf = entries.sublist(0, entries.length ~/ 2);
      final secondHalf = entries.sublist(entries.length ~/ 2);
      final firstAvg = firstHalf.fold<double>(
              0, (s, e) => s + moodToValue(e.mood)) /
          firstHalf.length;
      final secondAvg = secondHalf.fold<double>(
              0, (s, e) => s + moodToValue(e.mood)) /
          secondHalf.length;

      if (secondAvg - firstAvg > 0.5) {
        insight = 'Your mood is trending upward this week!';
      } else if (firstAvg - secondAvg > 0.5) {
        insight = 'Your mood dipped later in the week. Rest might help.';
      }
    }

    return MoodReport(
      averageMood: avgMood,
      averageEnergy: avgEnergy,
      entryCount: entries.length,
      moodDistribution: distribution,
      patternInsight: insight,
    );
  }
}
