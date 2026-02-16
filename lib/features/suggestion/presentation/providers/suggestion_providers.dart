import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/suggestion/domain/suggestion_engine.dart';
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
  void refreshSuggestions() {
    final engine = ref.read(suggestionEngineProvider);
    final groups = ref.read(localGroupsProvider);
    final schedules = ref.read(localSchedulesProvider);

    if (groups.isEmpty) {
      state = [];
      return;
    }

    final allSuggestions = <Suggestion>[];

    for (final group in groups) {
      final members =
          ref.read(localGroupMembersProvider)[group.id] ?? [];
      if (members.length < 2) continue;

      // Build memberSchedules map
      // In offline mode, all local schedules belong to 'local-user'
      // Simulate other members having no schedules (fully free)
      final memberSchedules = <String, List<Schedule>>{};
      for (final member in members) {
        if (member.userId == 'local-user') {
          memberSchedules[member.userId] = schedules;
        } else {
          memberSchedules[member.userId] = [];
        }
      }

      final suggestions = engine.generateSuggestions(
        memberSchedules: memberSchedules,
        groupId: group.id,
      );
      allSuggestions.addAll(suggestions);
    }

    // Sort all suggestions by score
    allSuggestions.sort((a, b) => b.score.compareTo(a.score));
    state = allSuggestions;
  }

  void updateStatus(String id, SuggestionStatus status) {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(status: status) else s,
    ];
  }

  void clear() {
    state = [];
  }
}
