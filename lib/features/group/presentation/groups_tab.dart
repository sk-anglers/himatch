import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/widgets/empty_state_widget.dart';
import 'package:himatch/core/widgets/glass_card.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/routing/app_routes.dart';
import 'package:himatch/features/group/presentation/widgets/create_group_dialog.dart';
import 'package:himatch/features/group/presentation/widgets/join_group_dialog.dart';
import 'package:himatch/features/group/presentation/providers/notification_providers.dart';

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(localGroupsProvider);

    return Scaffold(
      body: groups.isEmpty ? const _EmptyState() : _GroupList(groups: groups),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: Theme.of(context).extension<AppColorsExtension>()!.primary,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const CreateGroupDialog(),
    );
    if (result != null && context.mounted) {
      ref.read(localGroupsProvider.notifier).createGroup(
            name: result['name']!,
            description: result['description'],
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${result['name']}」を作成しました')),
      );
    }
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyStateWidget(
      icon: Icons.group_outlined,
      title: 'グループがありません',
      subtitle: 'グループを作成するか、\n招待コードで参加しましょう',
      actionLabel: '招待コードで参加',
      onAction: () => _showJoinDialog(context, ref),
    );
  }

  Future<void> _showJoinDialog(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const JoinGroupDialog(),
    );
    if (code != null && context.mounted) {
      final group =
          ref.read(localGroupsProvider.notifier).joinByInviteCode(code);
      if (group != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${group.name}」に参加しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待コードが見つかりません'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _GroupList extends ConsumerWidget {
  final List<Group> groups;

  const _GroupList({required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Join button bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '${groups.length}グループ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showJoinDialog(context, ref),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('招待コードで参加'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Group cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return _GroupCard(
                group: groups[index],
                onTap: () => _openGroupDetail(context, groups[index]),
              )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: (60 * index).ms,
                  )
                  .slideY(
                    begin: 0.08,
                    duration: 400.ms,
                    delay: (60 * index).ms,
                    curve: Curves.easeOut,
                  )
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    duration: 400.ms,
                    delay: (60 * index).ms,
                    curve: Curves.easeOut,
                  );
            },
          ),
        ),
      ],
    );
  }

  void _openGroupDetail(BuildContext context, Group group) {
    context.pushNamed(
      AppRoute.groupDetail.name,
      pathParameters: {'groupId': group.id},
      extra: {'group': group},
    );
  }

  Future<void> _showJoinDialog(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const JoinGroupDialog(),
    );
    if (code != null && context.mounted) {
      final group =
          ref.read(localGroupsProvider.notifier).joinByInviteCode(code);
      if (group != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${group.name}」に参加しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待コードが見つかりません'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _GroupCard extends ConsumerWidget {
  final Group group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final membersMap = ref.watch(localGroupMembersProvider);
    final memberCount = (membersMap[group.id] ?? []).length;
    final notificationCount =
        ref.watch(groupNotificationCountProvider(group.id));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: Row(
        children: [
          // Group avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.primary.withValues(alpha: 0.15),
            child: Text(
              group.name.isNotEmpty ? group.name[0] : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 14, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$memberCount人',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          group.description!,
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Notification badge + Arrow
          if (notificationCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Badge(
                label: Text('$notificationCount'),
                child: const SizedBox.shrink(),
              ),
            ),
          Icon(
            Icons.chevron_right,
            color: colors.textHint,
          ),
        ],
      ),
    );
  }
}
