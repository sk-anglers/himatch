import 'dart:math' as math;

import 'package:himatch/models/suggestion.dart';

/// Learn from confirmed suggestions to improve future scoring.
///
/// Uses a simple counting-based approach to track which activity types,
/// weekdays, and time categories a group tends to confirm. Applies learned
/// weights to adjust base suggestion scores.
class LearningEngine {
  final List<SuggestionFeedback> _feedbackHistory = [];

  /// Record feedback for a suggestion (confirmed or declined).
  void recordFeedback(SuggestionFeedback feedback) {
    _feedbackHistory.add(feedback);
  }

  /// Record a batch of feedback entries.
  void recordFeedbackBatch(List<SuggestionFeedback> feedbacks) {
    _feedbackHistory.addAll(feedbacks);
  }

  /// Get learned preferences for a group.
  GroupPreferences getGroupPreferences(String groupId) {
    final groupFeedback =
        _feedbackHistory.where((f) => f.groupId == groupId).toList();

    if (groupFeedback.isEmpty) {
      return GroupPreferences.empty();
    }

    // ── Activity weights ──
    final activityCounts = <String, _ConfirmCount>{};
    for (final f in groupFeedback) {
      activityCounts.putIfAbsent(f.activityType, () => _ConfirmCount());
      activityCounts[f.activityType]!.total++;
      if (f.wasConfirmed) {
        activityCounts[f.activityType]!.confirmed++;
      }
    }
    final activityWeights = activityCounts.map(
      (key, value) => MapEntry(key, value.rate),
    );

    // ── Weekday weights ──
    final weekdayCounts = <int, _ConfirmCount>{};
    for (final f in groupFeedback) {
      weekdayCounts.putIfAbsent(f.weekday, () => _ConfirmCount());
      weekdayCounts[f.weekday]!.total++;
      if (f.wasConfirmed) {
        weekdayCounts[f.weekday]!.confirmed++;
      }
    }
    final weekdayWeights = weekdayCounts.map(
      (key, value) => MapEntry(key, value.rate),
    );

    // ── Time category weights ──
    final timeCounts = <TimeCategory, _ConfirmCount>{};
    for (final f in groupFeedback) {
      timeCounts.putIfAbsent(f.timeCategory, () => _ConfirmCount());
      timeCounts[f.timeCategory]!.total++;
      if (f.wasConfirmed) {
        timeCounts[f.timeCategory]!.confirmed++;
      }
    }
    final timeCategoryWeights = timeCounts.map(
      (key, value) => MapEntry(key, value.rate),
    );

    // ── Overall confirmation rate ──
    final totalConfirmed =
        groupFeedback.where((f) => f.wasConfirmed).length;
    final avgConfirmationRate = totalConfirmed / groupFeedback.length;

    return GroupPreferences(
      activityWeights: activityWeights,
      weekdayWeights: weekdayWeights,
      timeCategoryWeights: timeCategoryWeights,
      avgConfirmationRate: avgConfirmationRate,
    );
  }

  /// Apply learned adjustments to a base score.
  ///
  /// The adjusted score is the base score multiplied by factors derived
  /// from historical confirmation rates for the suggestion's attributes.
  /// If no data exists for an attribute, a neutral factor (1.0) is used.
  double adjustScore(
    double baseScore,
    Suggestion suggestion,
    GroupPreferences prefs,
  ) {
    if (prefs.isEmpty) return baseScore;

    double multiplier = 1.0;

    // Activity type factor
    final activityWeight = prefs.activityWeights[suggestion.activityType];
    if (activityWeight != null) {
      // Scale: 0.0 confirmation rate → 0.7x, 1.0 → 1.3x
      multiplier *= _lerp(0.7, 1.3, activityWeight);
    }

    // Weekday factor
    final weekday = suggestion.suggestedDate.weekday;
    final weekdayWeight = prefs.weekdayWeights[weekday];
    if (weekdayWeight != null) {
      multiplier *= _lerp(0.8, 1.2, weekdayWeight);
    }

    // Time category factor
    final timeWeight = prefs.timeCategoryWeights[suggestion.timeCategory];
    if (timeWeight != null) {
      multiplier *= _lerp(0.8, 1.2, timeWeight);
    }

    // Confidence scaling: with fewer data points, pull toward 1.0
    final dataPoints = _feedbackHistory
        .where((f) => f.groupId == suggestion.groupId)
        .length;
    final confidence = _confidenceFactor(dataPoints);
    multiplier = 1.0 + (multiplier - 1.0) * confidence;

    return baseScore * multiplier;
  }

  /// Get raw feedback history for a group (for debugging / export).
  List<SuggestionFeedback> getFeedbackHistory(String groupId) {
    return _feedbackHistory.where((f) => f.groupId == groupId).toList();
  }

  /// Clear all feedback data (for testing or reset).
  void clear() {
    _feedbackHistory.clear();
  }

  /// Clear feedback for a specific group.
  void clearGroup(String groupId) {
    _feedbackHistory.removeWhere((f) => f.groupId == groupId);
  }

  // ── Private helpers ──

  /// Linear interpolation.
  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  /// Confidence factor based on number of data points.
  /// Returns 0.0 with no data, approaching 1.0 with many data points.
  /// Uses a simple logarithmic curve: confidence = min(1.0, log2(n+1) / 5).
  static double _confidenceFactor(int dataPoints) {
    if (dataPoints <= 0) return 0.0;
    // ~32 data points → full confidence
    final raw = _log2(dataPoints + 1) / 5.0;
    return raw.clamp(0.0, 1.0);
  }

  /// Base-2 logarithm.
  static double _log2(num x) {
    return math.log(x) / math.ln2;
  }
}

/// Helper class for counting confirmations.
class _ConfirmCount {
  int confirmed = 0;
  int total = 0;

  /// Confirmation rate (0.0 - 1.0).
  double get rate => total > 0 ? confirmed / total : 0.5;
}

/// Feedback data for a suggestion.
class SuggestionFeedback {
  final String groupId;
  final String activityType;
  final TimeCategory timeCategory;
  final int weekday; // 1 = Monday (DateTime.monday)
  final bool wasConfirmed;
  final DateTime date;

  const SuggestionFeedback({
    required this.groupId,
    required this.activityType,
    required this.timeCategory,
    required this.weekday,
    required this.wasConfirmed,
    required this.date,
  });
}

/// Learned preferences for a group.
class GroupPreferences {
  /// Activity type → confirmation weight (0.0 - 1.0).
  final Map<String, double> activityWeights;

  /// Weekday (1-7) → confirmation weight (0.0 - 1.0).
  final Map<int, double> weekdayWeights;

  /// Time category → confirmation weight (0.0 - 1.0).
  final Map<TimeCategory, double> timeCategoryWeights;

  /// Average confirmation rate across all suggestions.
  final double avgConfirmationRate;

  const GroupPreferences({
    required this.activityWeights,
    required this.weekdayWeights,
    required this.timeCategoryWeights,
    required this.avgConfirmationRate,
  });

  /// Create empty preferences (no data yet).
  factory GroupPreferences.empty() {
    return const GroupPreferences(
      activityWeights: {},
      weekdayWeights: {},
      timeCategoryWeights: {},
      avgConfirmationRate: 0.0,
    );
  }

  /// Whether there is any learned data.
  bool get isEmpty =>
      activityWeights.isEmpty &&
      weekdayWeights.isEmpty &&
      timeCategoryWeights.isEmpty;

  /// Whether there is sufficient data for reliable adjustments.
  bool get hasSufficientData =>
      activityWeights.length >= 2 || weekdayWeights.length >= 3;

  /// Get the most popular activity type (highest weight).
  String? get favoriteActivity {
    if (activityWeights.isEmpty) return null;
    return activityWeights.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the most popular weekday (highest weight).
  int? get favoriteWeekday {
    if (weekdayWeights.isEmpty) return null;
    return weekdayWeights.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the most popular time category (highest weight).
  TimeCategory? get favoriteTimeCategory {
    if (timeCategoryWeights.isEmpty) return null;
    return timeCategoryWeights.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
