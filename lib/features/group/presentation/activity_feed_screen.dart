import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/activity.dart';
import 'package:himatch/features/group/presentation/providers/activity_providers.dart';

/// Chronological activity feed screen for a group.
///
/// Shows a chronological list of group activities with icons, reactions,
/// and pull-to-refresh.
class ActivityFeedScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const ActivityFeedScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  static const _reactionEmojis = [
    '\u{1F44D}', // thumbs up
    '\u{2764}\u{FE0F}', // heart
    '\u{1F602}', // joy
    '\u{1F389}', // party
    '\u{1F64C}', // raising hands
  ];

  IconData _iconForType(ActivityType type) {
    switch (type) {
      case ActivityType.scheduleAdded:
      case ActivityType.scheduleUpdated:
        return Icons.calendar_today;
      case ActivityType.suggestionCreated:
        return Icons.lightbulb;
      case ActivityType.voteCast:
        return Icons.how_to_vote;
      case ActivityType.suggestionConfirmed:
        return Icons.celebration;
      case ActivityType.memberJoined:
        return Icons.person_add;
      case ActivityType.memberLeft:
        return Icons.person_remove;
      case ActivityType.photoAdded:
        return Icons.photo;
      case ActivityType.todoCompleted:
        return Icons.check_circle;
      case ActivityType.pollCreated:
        return Icons.poll;
    }
  }

  Color _colorForType(ActivityType type) {
    switch (type) {
      case ActivityType.scheduleAdded:
      case ActivityType.scheduleUpdated:
        return const Color(0xFF3498DB);
      case ActivityType.suggestionCreated:
        return AppColors.warning;
      case ActivityType.voteCast:
        return AppColors.primary;
      case ActivityType.suggestionConfirmed:
        return AppColors.success;
      case ActivityType.memberJoined:
        return AppColors.success;
      case ActivityType.memberLeft:
        return AppColors.error;
      case ActivityType.photoAdded:
        return const Color(0xFFE84393);
      case ActivityType.todoCompleted:
        return AppColors.success;
      case ActivityType.pollCreated:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allActivities = ref.watch(localActivitiesProvider);
    final activities = allActivities[groupId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('$groupName のアクティビティ'),
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'アクティビティがありません',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'グループの活動がここに表示されます',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                // TODO: Fetch from Supabase when connected
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _ActivityTile(
                    activity: activity,
                    icon: _iconForType(activity.type),
                    iconColor: _colorForType(activity.type),
                    onTapReaction: () =>
                        _showReactionPicker(context, ref, activity),
                  );
                },
              ),
            ),
    );
  }

  void _showReactionPicker(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      ref.read(localActivitiesProvider.notifier).addReaction(
                            groupId: groupId,
                            activityId: activity.id,
                            emoji: emoji,
                            userId: 'local-user',
                          );
                      Navigator.pop(ctx);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity tile
// ---------------------------------------------------------------------------

class _ActivityTile extends StatelessWidget {
  final Activity activity;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTapReaction;

  const _ActivityTile({
    required this.activity,
    required this.icon,
    required this.iconColor,
    required this.onTapReaction,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapReaction,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(activity.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),

                  // Reactions
                  if (activity.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        children: activity.reactions.entries
                            .where((e) => e.value.isNotEmpty)
                            .map(
                              (entry) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.key} ${entry.value.length}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
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

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';

    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
