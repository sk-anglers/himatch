import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/demo_data.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/suggestion/domain/suggestion_engine.dart';
import 'package:himatch/features/suggestion/presentation/providers/weather_providers.dart';
import 'package:himatch/features/profile/presentation/providers/location_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';

final suggestionEngineProvider = Provider<SuggestionEngine>((ref) {
  return SuggestionEngine();
});

/// Local suggestions state for offline-first development.
final localSuggestionsProvider =
    NotifierProvider<LocalSuggestionsNotifier, List<Suggestion>>(
  LocalSuggestionsNotifier.new,
);

class LocalSuggestionsNotifier extends Notifier<List<Suggestion>> {
  @override
  List<Suggestion> build() => [];

  /// Run the suggestion engine against local data.
  /// Fetches weather data asynchronously before running the engine.
  Future<void> refreshSuggestions() async {
    final engine = ref.read(suggestionEngineProvider);
    final groups = ref.read(localGroupsProvider);
    final schedules = ref.read(localSchedulesProvider);

    if (groups.isEmpty) {
      state = [];
      return;
    }

    // Fetch weather data using resolved coordinates (graceful: empty map on failure)
    Map<DateTime, WeatherSummary> weatherData = {};
    try {
      final weatherService = ref.read(weatherServiceProvider);
      final coords = await ref.read(resolvedWeatherCoordsProvider.future);
      weatherData = await weatherService.fetchForecast(
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
    } catch (_) {
      // Weather fetch failed — continue with empty weather data
    }

    final allSuggestions = <Suggestion>[];

    for (final group in groups) {
      final members =
          ref.read(localGroupMembersProvider)[group.id] ?? [];
      if (members.length < 2) continue;

      // Build memberSchedules map using demo data for realistic variety
      final allDemoSchedules = DemoData.generateAllMemberSchedules();
      final memberSchedules = <String, List<Schedule>>{};
      for (final member in members) {
        if (member.userId == 'local-user') {
          memberSchedules[member.userId] = schedules;
        } else {
          memberSchedules[member.userId] =
              allDemoSchedules[member.userId] ?? [];
        }
      }

      final suggestions = engine.generateSuggestions(
        memberSchedules: memberSchedules,
        groupId: group.id,
        weatherData: weatherData.isNotEmpty ? weatherData : null,
      );
      allSuggestions.addAll(suggestions);
    }

    // Deduplicate: keep only the best suggestion per (groupId, date)
    final bestPerDayGroup = <String, Suggestion>{};
    for (final s in allSuggestions) {
      final key =
          '${s.groupId}_${s.suggestedDate.year}-${s.suggestedDate.month}-${s.suggestedDate.day}';
      final existing = bestPerDayGroup[key];
      if (existing == null || s.score > existing.score) {
        bestPerDayGroup[key] = s;
      }
    }

    final deduped = bestPerDayGroup.values.toList();

    // Sort by date ascending, then by score descending within the same day
    deduped.sort((a, b) {
      final dateCompare = a.suggestedDate.compareTo(b.suggestedDate);
      if (dateCompare != 0) return dateCompare;
      return b.score.compareTo(a.score);
    });
    state = deduped;
  }

  void updateStatus(String id, SuggestionStatus status) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(status: status) else s,
    ];
  }

  /// Confirm a suggestion (group owner action).
  /// Sets this suggestion to confirmed and declines other proposed suggestions
  /// for the same group on the same date.
  void confirmSuggestion(String id) {
    final target = state.where((s) => s.id == id).firstOrNull;
    if (target == null) return;

    state = [
      for (final s in state)
        if (s.id == id)
          s.copyWith(status: SuggestionStatus.confirmed)
        else if (s.groupId == target.groupId &&
            s.status == SuggestionStatus.proposed)
          s.copyWith(status: SuggestionStatus.declined)
        else
          s,
    ];
  }

  void clear() {
    state = [];
  }
}
