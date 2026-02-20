import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/vote.dart';
import 'package:uuid/uuid.dart';

/// Local vote state for offline-first development.
/// Key: suggestionId, Value: list of votes for that suggestion.
final localVotesProvider =
    NotifierProvider<LocalVotesNotifier, Map<String, List<Vote>>>(
  LocalVotesNotifier.new,
);

class LocalVotesNotifier extends Notifier<Map<String, List<Vote>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<Vote>> build() => {};

  /// Cast, update, or toggle a vote on a suggestion.
  /// If the user already voted with the same [voteType], the vote is removed.
  void castVote({
    required String suggestionId,
    required String userId,
    required VoteType voteType,
    String? displayName,
  }) {
    final currentVotes = List<Vote>.from(state[suggestionId] ?? []);

    // Check if user already voted with the same type (toggle off)
    final existing =
        currentVotes.where((v) => v.userId == userId).firstOrNull;
    currentVotes.removeWhere((v) => v.userId == userId);

    if (existing?.voteType == voteType) {
      // Same type → remove only (toggle off)
      state = {...state, suggestionId: currentVotes};
      return;
    }

    // Add new vote
    currentVotes.add(Vote(
      id: _uuid.v4(),
      suggestionId: suggestionId,
      userId: userId,
      displayName: displayName,
      voteType: voteType,
      votedAt: DateTime.now(),
    ));

    state = {...state, suggestionId: currentVotes};
  }

  /// Get current user's vote for a suggestion.
  VoteType? getUserVote(String suggestionId, String userId) {
    final votes = state[suggestionId] ?? [];
    final userVote = votes.where((v) => v.userId == userId).firstOrNull;
    return userVote?.voteType;
  }

  /// Get vote summary for a suggestion.
  VoteSummary getVoteSummary(String suggestionId) {
    final votes = state[suggestionId] ?? [];
    return VoteSummary(
      okCount: votes.where((v) => v.voteType == VoteType.ok).length,
      maybeCount: votes.where((v) => v.voteType == VoteType.maybe).length,
      ngCount: votes.where((v) => v.voteType == VoteType.ng).length,
      votes: votes,
    );
  }

  /// Clear all votes for a suggestion.
  void clearVotes(String suggestionId) {
    final updated = Map<String, List<Vote>>.from(state);
    updated.remove(suggestionId);
    state = updated;
  }
}

/// Summary of votes for display.
class VoteSummary {
  final int okCount;
  final int maybeCount;
  final int ngCount;
  final List<Vote> votes;

  const VoteSummary({
    required this.okCount,
    required this.maybeCount,
    required this.ngCount,
    required this.votes,
  });

  int get totalVotes => okCount + maybeCount + ngCount;
  bool get hasVotes => totalVotes > 0;
}
