import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/group/presentation/group_detail_screen.dart';
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
        backgroundColor: AppColors.primary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'グループがありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'グループを作成するか、\n招待コードで参加しましょう',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showJoinDialog(context, ref),
              icon: const Icon(Icons.login),
              label: const Text('招待コードで参加'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  void _openGroupDetail(BuildContext context, Group group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: group),
      ),
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
    final membersMap = ref.watch(localGroupMembersProvider);
    final memberCount = (membersMap[group.id] ?? []).length;
    final notificationCount =
        ref.watch(groupNotificationCountProvider(group.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                child: Text(
                  group.name.isNotEmpty ? group.name[0] : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                        const Icon(Icons.people_outline,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount人',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (group.description != null &&
                            group.description!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              group.description!,
                              style: const TextStyle(
                                color: AppColors.textHint,
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
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
