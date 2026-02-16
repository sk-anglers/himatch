import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/vote.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/suggestion/presentation/providers/vote_providers.dart';
import 'package:himatch/features/suggestion/presentation/providers/suggestion_providers.dart';

void main() {
  group('LocalVotesNotifier', () {
    late ProviderContainer container;
    late LocalVotesNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(localVotesProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('initial state is empty', () {
      expect(container.read(localVotesProvider), isEmpty);
    });

    test('castVote adds a vote', () {
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ok,
        displayName: 'テストユーザー',
      );

      final votes = container.read(localVotesProvider);
      expect(votes['sug-1'], hasLength(1));
      expect(votes['sug-1']!.first.voteType, VoteType.ok);
      expect(votes['sug-1']!.first.displayName, 'テストユーザー');
    });

    test('castVote replaces existing vote by same user', () {
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ok,
      );
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ng,
      );

      final votes = container.read(localVotesProvider);
      expect(votes['sug-1'], hasLength(1));
      expect(votes['sug-1']!.first.voteType, VoteType.ng);
    });

    test('multiple users can vote on same suggestion', () {
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ok,
      );
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-2',
        voteType: VoteType.maybe,
      );
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-3',
        voteType: VoteType.ng,
      );

      final votes = container.read(localVotesProvider);
      expect(votes['sug-1'], hasLength(3));
    });

    test('getUserVote returns correct vote type', () {
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.maybe,
      );

      expect(notifier.getUserVote('sug-1', 'user-1'), VoteType.maybe);
      expect(notifier.getUserVote('sug-1', 'user-2'), isNull);
      expect(notifier.getUserVote('sug-2', 'user-1'), isNull);
    });

    test('getVoteSummary returns correct counts', () {
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ok,
      );
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-2',
        voteType: VoteType.ok,
      );
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-3',
        voteType: VoteType.maybe,
      );
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-4',
        voteType: VoteType.ng,
      );

      final summary = notifier.getVoteSummary('sug-1');
      expect(summary.okCount, 2);
      expect(summary.maybeCount, 1);
      expect(summary.ngCount, 1);
      expect(summary.totalVotes, 4);
      expect(summary.hasVotes, isTrue);
    });

    test('getVoteSummary for empty suggestion', () {
      final summary = notifier.getVoteSummary('nonexistent');
      expect(summary.okCount, 0);
      expect(summary.maybeCount, 0);
      expect(summary.ngCount, 0);
      expect(summary.totalVotes, 0);
      expect(summary.hasVotes, isFalse);
    });

    test('clearVotes removes all votes for suggestion', () {
      notifier.castVote(
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ok,
      );
      notifier.castVote(
        suggestionId: 'sug-2',
        userId: 'user-1',
        voteType: VoteType.ng,
      );

      notifier.clearVotes('sug-1');

      final votes = container.read(localVotesProvider);
      expect(votes.containsKey('sug-1'), isFalse);
      expect(votes['sug-2'], hasLength(1));
    });
  });

  group('SuggestionNotifier.confirmSuggestion', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('confirmSuggestion does not crash on empty state', () {
      final notifier = container.read(localSuggestionsProvider.notifier);
      notifier.confirmSuggestion('nonexistent');
      expect(container.read(localSuggestionsProvider), isEmpty);
    });

    test('confirmed status exists in SuggestionStatus enum', () {
      expect(SuggestionStatus.confirmed, isNotNull);
      expect(SuggestionStatus.confirmed.name, 'confirmed');
    });
  });

  group('Vote model', () {
    test('fromJson creates vote correctly', () {
      final json = {
        'id': 'vote-1',
        'suggestion_id': 'sug-1',
        'user_id': 'user-1',
        'display_name': 'テストユーザー',
        'vote_type': 'ok',
        'voted_at': '2025-03-15T10:00:00.000',
      };

      final vote = Vote.fromJson(json);
      expect(vote.id, 'vote-1');
      expect(vote.suggestionId, 'sug-1');
      expect(vote.userId, 'user-1');
      expect(vote.displayName, 'テストユーザー');
      expect(vote.voteType, VoteType.ok);
    });

    test('toJson serializes correctly', () {
      final vote = Vote(
        id: 'vote-1',
        suggestionId: 'sug-1',
        userId: 'user-1',
        displayName: 'テスト',
        voteType: VoteType.maybe,
        votedAt: DateTime(2025, 3, 15, 10),
      );

      final json = vote.toJson();
      expect(json['suggestion_id'], 'sug-1');
      expect(json['vote_type'], 'maybe');
      expect(json['display_name'], 'テスト');
    });

    test('copyWith works correctly', () {
      final vote = Vote(
        id: 'vote-1',
        suggestionId: 'sug-1',
        userId: 'user-1',
        voteType: VoteType.ok,
        votedAt: DateTime.now(),
      );

      final updated = vote.copyWith(voteType: VoteType.ng);
      expect(updated.voteType, VoteType.ng);
      expect(updated.id, 'vote-1');
    });

    test('VoteType enum values', () {
      expect(VoteType.values, hasLength(3));
      expect(VoteType.ok.name, 'ok');
      expect(VoteType.maybe.name, 'maybe');
      expect(VoteType.ng.name, 'ng');
    });
  });
}
