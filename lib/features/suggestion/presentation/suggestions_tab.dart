import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/suggestion/presentation/providers/suggestion_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';

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
            if (accepted.isNotEmpty)
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
        // Proposed suggestions
        ...proposed.map((s) => _SuggestionCard(suggestion: s)),
        // Accepted suggestions
        if (accepted.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            '承認済み',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          ...accepted.map((s) => _SuggestionCard(suggestion: s)),
        ],
      ],
    );
  }
}

class _SuggestionCard extends ConsumerWidget {
  final Suggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccepted = suggestion.status == SuggestionStatus.accepted;
    final groups = ref.watch(localGroupsProvider);
    final groupName = groups
        .where((g) => g.id == suggestion.groupId)
        .map((g) => g.name)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAccepted
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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

            // Members
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

            // Action buttons
            if (!isAccepted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(localSuggestionsProvider.notifier)
                            .updateStatus(
                                suggestion.id, SuggestionStatus.declined);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('見送り'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(localSuggestionsProvider.notifier)
                            .updateStatus(
                                suggestion.id, SuggestionStatus.accepted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate)}の${suggestion.activityType}を承認しました',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('この日にする！'),
                    ),
                  ),
                ],
              ),
            if (isAccepted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '承認済み',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
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
