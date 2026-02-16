import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/demo_data.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';
import 'package:himatch/models/poll.dart';
import 'package:uuid/uuid.dart';

/// Local poll state for offline-first development.
///
/// Key: groupId, Value: list of polls in that group.
/// Will be replaced with Supabase-backed provider when connected.
final localPollsProvider =
    NotifierProvider<PollsNotifier, Map<String, List<Poll>>>(
  PollsNotifier.new,
);

/// Notifier that manages polls for all groups.
class PollsNotifier extends Notifier<Map<String, List<Poll>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<Poll>> build() {
    final authState = ref.watch(authNotifierProvider);
    if (authState.isDemo) {
      return _demoPolls();
    }
    return {};
  }

  static Map<String, List<Poll>> _demoPolls() {
    final now = DateTime.now();
    return {
      DemoData.demoGroupId: [
        Poll(
          id: 'demo-poll-1',
          groupId: DemoData.demoGroupId,
          createdBy: 'demo-user-a',
          creatorName: 'あかり',
          question: '今週末ランチどこ行く？',
          options: [
            const PollOption(
              id: 'demo-poll-opt-1',
              text: 'ハンバーガー',
              voterIds: ['demo-user-a', 'demo-user-b'],
              voterNames: ['あかり', 'けんた'],
            ),
            const PollOption(
              id: 'demo-poll-opt-2',
              text: 'パスタ',
              voterIds: ['demo-user-c'],
              voterNames: ['みく'],
            ),
            const PollOption(
              id: 'demo-poll-opt-3',
              text: 'ラーメン',
              voterIds: [],
              voterNames: [],
            ),
          ],
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ],
    };
  }

  /// Create a new poll in a group.
  ///
  /// [options] is a list of option text strings. Each will be assigned a
  /// unique ID and initialized with empty voter lists.
  void createPoll({
    required String groupId,
    required String createdBy,
    required String creatorName,
    required String question,
    required List<String> options,
    bool isMultiSelect = false,
    bool isAnonymous = false,
    DateTime? deadline,
  }) {
    final pollOptions = options
        .map((text) => PollOption(
              id: _uuid.v4(),
              text: text,
              voterIds: const [],
              voterNames: const [],
            ))
        .toList();

    final poll = Poll(
      id: _uuid.v4(),
      groupId: groupId,
      createdBy: createdBy,
      creatorName: creatorName,
      question: question,
      options: pollOptions,
      isMultiSelect: isMultiSelect,
      isAnonymous: isAnonymous,
      deadline: deadline,
      isClosed: false,
      createdAt: DateTime.now(),
    );

    final current = List<Poll>.from(state[groupId] ?? []);
    current.insert(0, poll); // Newest first
    state = {...state, groupId: current};
  }

  /// Cast a vote on a poll option.
  ///
  /// For single-select polls, removes any previous vote by this user
  /// before adding the new one. For multi-select polls, toggles the vote
  /// on the specified option.
  void vote({
    required String groupId,
    required String pollId,
    required String optionId,
    required String userId,
    required String userName,
  }) {
    final polls = List<Poll>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final p in polls)
          if (p.id == pollId)
            _applyVote(p, optionId, userId, userName)
          else
            p,
      ],
    };
  }

  /// Close a poll so no further votes can be cast.
  void closePoll(String groupId, String pollId) {
    final polls = List<Poll>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final p in polls)
          if (p.id == pollId) p.copyWith(isClosed: true) else p,
      ],
    };
  }

  /// Get all polls for a specific group.
  ///
  /// Returns an empty list if no polls exist for the group.
  List<Poll> getPolls(String groupId) {
    return state[groupId] ?? [];
  }

  /// Apply a vote to a poll, handling single/multi-select logic.
  Poll _applyVote(
    Poll poll,
    String optionId,
    String userId,
    String userName,
  ) {
    if (poll.isMultiSelect) {
      // Toggle: add if not present, remove if present
      return poll.copyWith(
        options: [
          for (final opt in poll.options)
            if (opt.id == optionId)
              opt.voterIds.contains(userId)
                  ? opt.copyWith(
                      voterIds:
                          opt.voterIds.where((u) => u != userId).toList(),
                      voterNames:
                          opt.voterNames.where((n) => n != userName).toList(),
                    )
                  : opt.copyWith(
                      voterIds: [...opt.voterIds, userId],
                      voterNames: [...opt.voterNames, userName],
                    )
            else
              opt,
        ],
      );
    } else {
      // Single-select: remove from all options, then add to target
      return poll.copyWith(
        options: [
          for (final opt in poll.options)
            if (opt.id == optionId)
              opt.copyWith(
                voterIds: [
                  ...opt.voterIds.where((u) => u != userId),
                  userId,
                ],
                voterNames: [
                  ...opt.voterNames.where((n) => n != userName),
                  userName,
                ],
              )
            else
              opt.copyWith(
                voterIds: opt.voterIds.where((u) => u != userId).toList(),
                voterNames:
                    opt.voterNames.where((n) => n != userName).toList(),
              ),
        ],
      );
    }
  }
}
