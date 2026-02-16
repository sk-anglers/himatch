import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/features/suggestion/presentation/providers/suggestion_providers.dart';
import 'package:himatch/models/suggestion.dart';

/// History of confirmed meetup suggestions, sorted by date descending.
///
/// Filters [localSuggestionsProvider] to only include suggestions
/// with [SuggestionStatus.confirmed] status.
final confirmedHistoryProvider = Provider<List<Suggestion>>((ref) {
  final suggestions = ref.watch(localSuggestionsProvider);

  final confirmed = suggestions
      .where((s) => s.status == SuggestionStatus.confirmed)
      .toList();

  // Sort by suggested date descending (most recent first)
  confirmed.sort((a, b) => b.suggestedDate.compareTo(a.suggestedDate));
  return confirmed;
});

/// Aggregated statistics for a specific group.
class GroupStats {
  /// Total number of confirmed meetups for this group.
  final int totalMeetups;

  /// Most common day of the week for meetups (1=Monday, 7=Sunday).
  final int? favoriteDayOfWeek;

  /// Most frequently suggested activity type.
  final String? favoriteActivity;

  /// Number of meetups per member (userId -> count of available appearances).
  final Map<String, int> memberMeetupCounts;

  const GroupStats({
    required this.totalMeetups,
    this.favoriteDayOfWeek,
    this.favoriteActivity,
    required this.memberMeetupCounts,
  });
}

/// Per-group statistics derived from confirmed suggestions.
///
/// Provides insights like total meetups, favorite day/activity, and
/// per-member participation counts.
final groupStatsProvider =
    Provider.family<GroupStats, String>((ref, groupId) {
  final confirmed = ref.watch(confirmedHistoryProvider);
  final groupSuggestions =
      confirmed.where((s) => s.groupId == groupId).toList();

  if (groupSuggestions.isEmpty) {
    return const GroupStats(
      totalMeetups: 0,
      memberMeetupCounts: {},
    );
  }

  // Favorite day of week
  final dayCount = <int, int>{};
  for (final s in groupSuggestions) {
    final day = s.suggestedDate.weekday;
    dayCount[day] = (dayCount[day] ?? 0) + 1;
  }
  final favDay = dayCount.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  // Favorite activity type
  final activityCount = <String, int>{};
  for (final s in groupSuggestions) {
    activityCount[s.activityType] =
        (activityCount[s.activityType] ?? 0) + 1;
  }
  final favActivity = activityCount.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;

  // Member meetup counts (based on availableMembers)
  final memberCounts = <String, int>{};
  for (final s in groupSuggestions) {
    for (final memberId in s.availableMembers) {
      memberCounts[memberId] = (memberCounts[memberId] ?? 0) + 1;
    }
  }

  return GroupStats(
    totalMeetups: groupSuggestions.length,
    favoriteDayOfWeek: favDay,
    favoriteActivity: favActivity,
    memberMeetupCounts: memberCounts,
  );
});

/// Yearly statistics across all groups.
class YearlyStats {
  /// Number of meetups per month (1-12).
  final Map<int, int> monthlyMeetupCounts;

  /// Total meetups in the year.
  final int totalMeetups;

  /// Number of unique groups that had at least one confirmed meetup.
  final int uniqueGroupsActive;

  const YearlyStats({
    required this.monthlyMeetupCounts,
    required this.totalMeetups,
    required this.uniqueGroupsActive,
  });
}

/// Yearly aggregated statistics for all groups.
///
/// Provides monthly meetup counts, total meetups, and unique active groups
/// for a given year.
final yearlyStatsProvider =
    Provider.family<YearlyStats, int>((ref, year) {
  final confirmed = ref.watch(confirmedHistoryProvider);
  final yearSuggestions = confirmed.where((s) =>
      s.suggestedDate.year == year).toList();

  // Monthly counts
  final monthlyCounts = <int, int>{};
  for (int m = 1; m <= 12; m++) {
    monthlyCounts[m] = 0;
  }
  for (final s in yearSuggestions) {
    monthlyCounts[s.suggestedDate.month] =
        (monthlyCounts[s.suggestedDate.month] ?? 0) + 1;
  }

  // Unique active groups
  final uniqueGroups = yearSuggestions.map((s) => s.groupId).toSet();

  return YearlyStats(
    monthlyMeetupCounts: monthlyCounts,
    totalMeetups: yearSuggestions.length,
    uniqueGroupsActive: uniqueGroups.length,
  );
});
