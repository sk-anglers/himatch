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

  /// Cast or update a vote on a suggestion.
  void castVote({
    required String suggestionId,
    required String userId,
    required VoteType voteType,
    String? displayName,
  }) {
    final currentVotes = List<Vote>.from(state[suggestionId] ?? []);

    // Remove existing vote by this user
    currentVotes.removeWhere((v) => v.userId == userId);

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
