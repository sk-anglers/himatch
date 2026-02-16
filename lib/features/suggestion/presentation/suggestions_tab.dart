import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/models/vote.dart';
import 'package:himatch/features/suggestion/presentation/providers/suggestion_providers.dart';
import 'package:himatch/features/suggestion/presentation/providers/vote_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';

class SuggestionsTab extends ConsumerWidget {
  const SuggestionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(localSuggestionsProvider);
    final groups = ref.watch(localGroupsProvider);

    return Scaffold(
      body: groups.isEmpty
          ? _NoGroupState()
          : suggestions.isEmpty
              ? _EmptySuggestionState(ref: ref)
              : _SuggestionList(suggestions: suggestions),
      floatingActionButton: groups.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ref
                    .read(localSuggestionsProvider.notifier)
                    .refreshSuggestions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('候補日を更新しました')),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('更新',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

class _NoGroupState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'グループに参加しましょう',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'グループタブでグループを作成または\n招待コードで参加すると候補日が表示されます',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySuggestionState extends StatelessWidget {
  final WidgetRef ref;

  const _EmptySuggestionState({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              '候補日がありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '右下の「更新」ボタンをタップして\n候補日を検索しましょう',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(localSuggestionsProvider.notifier)
                    .refreshSuggestions();
              },
              icon: const Icon(Icons.search),
              label: const Text('候補日を検索'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionList extends ConsumerWidget {
  final List<Suggestion> suggestions;

  const _SuggestionList({required this.suggestions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposed =
        suggestions.where((s) => s.status == SuggestionStatus.proposed).toList();
    final confirmed =
        suggestions.where((s) => s.status == SuggestionStatus.confirmed).toList();
    final accepted =
        suggestions.where((s) => s.status == SuggestionStatus.accepted).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats header
        Row(
          children: [
            Text(
              '${suggestions.length}件の候補',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (confirmed.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${confirmed.length}件確定',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (accepted.isNotEmpty && confirmed.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${accepted.length}件承認済み',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Confirmed suggestions at top
        if (confirmed.isNotEmpty) ...[
          const _SectionLabel(
            icon: Icons.check_circle,
            label: '確定済み',
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          ...confirmed.map((s) => _SuggestionCard(suggestion: s)),
          const SizedBox(height: 16),
        ],

        // Proposed suggestions (votable)
        if (proposed.isNotEmpty) ...[
          const _SectionLabel(
            icon: Icons.how_to_vote,
            label: '投票受付中',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          ...proposed.map((s) => _SuggestionCard(suggestion: s)),
        ],

        // Accepted suggestions (legacy)
        if (accepted.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel(
            icon: Icons.thumb_up,
            label: '承認済み',
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          ...accepted.map((s) => _SuggestionCard(suggestion: s)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends ConsumerWidget {
  final Suggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfirmed = suggestion.status == SuggestionStatus.confirmed;
    final isProposed = suggestion.status == SuggestionStatus.proposed;
    final groups = ref.watch(localGroupsProvider);
    final groupName = groups
        .where((g) => g.id == suggestion.groupId)
        .map((g) => g.name)
        .firstOrNull;

    // Check if current user is group owner
    final members = ref.watch(localGroupMembersProvider);
    final groupMembers = members[suggestion.groupId] ?? [];
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.userId ?? 'local-user';
    final isOwner = groupMembers.any(
        (m) => m.userId == currentUserId && m.role == 'owner');

    // Vote state
    final voteSummary = ref.watch(localVotesProvider.select(
        (votes) => ref.read(localVotesProvider.notifier).getVoteSummary(suggestion.id)));
    final myVote = ref.watch(localVotesProvider.select(
        (votes) => ref.read(localVotesProvider.notifier).getUserVote(
            suggestion.id, currentUserId)));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isConfirmed
            ? const BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: date & score
            Row(
              children: [
                // Date badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isConfirmed ? AppColors.success : AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                // Score indicator
                _ScoreBadge(score: suggestion.score),
              ],
            ),
            const SizedBox(height: 12),

            // Activity & time
            Row(
              children: [
                Icon(
                  _getActivityIcon(suggestion.activityType),
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  suggestion.activityType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                _TimeCategoryBadge(category: suggestion.timeCategory),
              ],
            ),
            const SizedBox(height: 8),

            // Time range
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${AppDateUtils.formatTime(suggestion.startTime)} - ${AppDateUtils.formatTime(suggestion.endTime)}'
                  ' (${suggestion.durationHours.toStringAsFixed(1)}h)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Members & group
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${suggestion.availableMembers.length}/${suggestion.totalMembers}人が参加可能',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (groupName != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    groupName,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Availability bar
            _AvailabilityBar(ratio: suggestion.availabilityRatio),
            const SizedBox(height: 12),

            // Vote summary (if any votes exist)
            if (voteSummary.hasVotes) ...[
              _VoteSummaryBar(summary: voteSummary),
              const SizedBox(height: 12),
            ],

            // Voting buttons (for proposed suggestions)
            if (isProposed) ...[
              _VotingButtons(
                suggestionId: suggestion.id,
                currentVote: myVote,
                currentUserId: currentUserId,
                displayName: authState.displayName,
              ),
              // Confirm button for group owner
              if (isOwner && voteSummary.hasVotes) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showConfirmDialog(context, ref, suggestion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('この日に決定'),
                  ),
                ),
              ],
            ],

            // Confirmed display
            if (isConfirmed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, color: AppColors.success, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '予定確定！',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Suggestion suggestion,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('予定を確定'),
        content: Text(
          '${AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate)}の'
          '${suggestion.activityType}を確定しますか？\n\n'
          '他の候補日は自動的に見送りになります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(localSuggestionsProvider.notifier)
                  .confirmSuggestion(suggestion.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate)}の'
                    '${suggestion.activityType}を確定しました！',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('確定する'),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    return switch (activityType) {
      'ランチ' => Icons.restaurant,
      '飲み会' || 'ディナー' => Icons.local_bar,
      'カフェ' => Icons.coffee,
      '日帰り旅行' => Icons.directions_car,
      'お出かけ' || '遊び' => Icons.celebration,
      _ => Icons.event,
    };
  }
}

/// 3-choice voting buttons: 参加OK / 微妙 / NG
class _VotingButtons extends ConsumerWidget {
  final String suggestionId;
  final VoteType? currentVote;
  final String currentUserId;
  final String? displayName;

  const _VotingButtons({
    required this.suggestionId,
    required this.currentVote,
    required this.currentUserId,
    this.displayName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _VoteButton(
            icon: Icons.circle_outlined,
            label: '参加OK',
            color: AppColors.success,
            isSelected: currentVote == VoteType.ok,
            onPressed: () => _castVote(ref, VoteType.ok),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _VoteButton(
            icon: Icons.change_history,
            label: '微妙',
            color: AppColors.warning,
            isSelected: currentVote == VoteType.maybe,
            onPressed: () => _castVote(ref, VoteType.maybe),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _VoteButton(
            icon: Icons.close,
            label: 'NG',
            color: AppColors.error,
            isSelected: currentVote == VoteType.ng,
            onPressed: () => _castVote(ref, VoteType.ng),
          ),
        ),
      ],
    );
  }

  void _castVote(WidgetRef ref, VoteType voteType) {
    ref.read(localVotesProvider.notifier).castVote(
          suggestionId: suggestionId,
          userId: currentUserId,
          voteType: voteType,
          displayName: displayName,
        );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _VoteButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : color,
        backgroundColor: isSelected ? color : Colors.transparent,
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Visual summary of votes: OK/Maybe/NG counts with bar
class _VoteSummaryBar extends StatelessWidget {
  final VoteSummary summary;

  const _VoteSummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.totalVotes;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vote count chips
        Row(
          children: [
            const Icon(Icons.how_to_vote, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              '投票 $total件',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 8),
            _VoteChip(
              icon: Icons.circle_outlined,
              count: summary.okCount,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            _VoteChip(
              icon: Icons.change_history,
              count: summary.maybeCount,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            _VoteChip(
              icon: Icons.close,
              count: summary.ngCount,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (summary.okCount > 0)
                  Expanded(
                    flex: summary.okCount,
                    child: Container(color: AppColors.success),
                  ),
                if (summary.maybeCount > 0)
                  Expanded(
                    flex: summary.maybeCount,
                    child: Container(color: AppColors.warning),
                  ),
                if (summary.ngCount > 0)
                  Expanded(
                    flex: summary.ngCount,
                    child: Container(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ),
        // Individual vote list
        if (summary.votes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: summary.votes.map((v) => _VoterTag(vote: v)).toList(),
          ),
        ],
      ],
    );
  }
}

class _VoteChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _VoteChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoterTag extends StatelessWidget {
  final Vote vote;

  const _VoterTag({required this.vote});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (vote.voteType) {
      VoteType.ok => (AppColors.success, Icons.circle_outlined),
      VoteType.maybe => (AppColors.warning, Icons.change_history),
      VoteType.ng => (AppColors.error, Icons.close),
    };
    final name = vote.displayName ?? vote.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = score >= 0.7
        ? AppColors.success
        : score >= 0.4
            ? AppColors.warning
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCategoryBadge extends StatelessWidget {
  final TimeCategory category;

  const _TimeCategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (category) {
      TimeCategory.morning => ('朝', Icons.wb_sunny),
      TimeCategory.lunch => ('昼', Icons.restaurant),
      TimeCategory.afternoon => ('午後', Icons.wb_cloudy),
      TimeCategory.evening => ('夜', Icons.nightlight_round),
      TimeCategory.allDay => ('終日', Icons.calendar_today),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBar extends StatelessWidget {
  final double ratio;

  const _AvailabilityBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final color = ratio >= 0.8
        ? AppColors.success
        : ratio >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '参加可能率',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const Spacer(),
            Text(
              '${(ratio * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.surfaceVariant,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
