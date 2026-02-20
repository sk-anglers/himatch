import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/widgets/glass_card.dart';
import 'package:himatch/core/widgets/gradient_scaffold.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/routing/app_routes.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/chat/presentation/providers/chat_providers.dart';
import 'package:himatch/features/group/presentation/providers/notification_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final membersMap = ref.watch(localGroupMembersProvider);
    final members = membersMap[group.id] ?? [];

    return GradientScaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('グループを退出',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupInfoCard(group: group),
          const SizedBox(height: 16),

          // Calendar buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed(
                AppRoute.groupCalendar.name,
                pathParameters: {'groupId': group.id},
                extra: {'group': group},
              ),
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('メンバーのカレンダーを見る'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.pushNamed(
                AppRoute.shiftListCalendar.name,
                pathParameters: {'groupId': group.id},
                extra: {'group': group},
              ),
              icon: const Icon(Icons.view_list, size: 18),
              label: const Text('シフト一覧を見る'),
            ),
          ),
          const SizedBox(height: 20),

          // Feature grid
          _SectionLabel(title: '機能'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _FeatureButton(
                icon: Icons.chat_bubble_outline,
                label: 'チャット',
                color: colors.primary,
                badgeCount: ref.watch(unreadCountProvider(group.id)),
                onTap: () => context.pushNamed(
                  AppRoute.chat.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name, 'memberCount': members.length},
                ),
              ),
              _FeatureButton(
                icon: Icons.dynamic_feed,
                label: 'フィード',
                color: AppColors.success,
                onTap: () => context.pushNamed(
                  AppRoute.activityFeed.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name},
                ),
              ),
              _FeatureButton(
                icon: Icons.checklist,
                label: 'ToDo',
                color: AppColors.typeClass,
                badgeCount: ref.watch(incompleteTodoCountProvider(group.id)),
                onTap: () => context.pushNamed(
                  AppRoute.todoList.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name},
                ),
              ),
              _FeatureButton(
                icon: Icons.poll_outlined,
                label: '投票',
                color: AppColors.warning,
                badgeCount: ref.watch(unvotedPollCountProvider(group.id)),
                onTap: () => context.pushNamed(
                  AppRoute.poll.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name},
                ),
              ),
              _FeatureButton(
                icon: Icons.photo_library_outlined,
                label: 'アルバム',
                color: AppColors.typeParttime,
                onTap: () => context.pushNamed(
                  AppRoute.album.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name},
                ),
              ),
              _FeatureButton(
                icon: Icons.forum_outlined,
                label: '掲示板',
                color: AppColors.typeClub,
                onTap: () => context.pushNamed(
                  AppRoute.board.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name},
                ),
              ),
              _FeatureButton(
                icon: Icons.receipt_long_outlined,
                label: '割り勘',
                color: AppColors.secondary,
                onTap: () => context.pushNamed(
                  AppRoute.expense.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'groupId': group.id, 'groupName': group.name},
                ),
              ),
              _FeatureButton(
                icon: Icons.grid_view_outlined,
                label: 'ヒートマップ',
                color: AppColors.heatmapFull,
                onTap: () => context.pushNamed(
                  AppRoute.groupCalendar.name,
                  pathParameters: {'groupId': group.id},
                  extra: {'group': group, 'initialMode': 'heatmap'},
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, duration: 400.ms),
          const SizedBox(height: 20),

          // Invite code card
          _InviteCodeCard(inviteCode: group.inviteCode),
          const SizedBox(height: 24),

          // Members section
          Row(
            children: [
              Text(
                'メンバー (${members.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '上限 ${group.maxMembers}人',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...members.map((member) => _MemberTile(member: member)),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'メンバーがいません',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('グループを退出'),
        content: Text('「${group.name}」から退出しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(localGroupsProvider.notifier).leaveGroup(group.id);
              Navigator.pop(context);
            },
            child: const Text('退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                .extension<AppColorsExtension>()!
                .textSecondary,
          ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard.lite(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: badgeCount > 0,
            label: Text('$badgeCount'),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupInfoCard extends StatelessWidget {
  final Group group;

  const _GroupInfoCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary.withValues(alpha: 0.15),
            child: Text(
              group.name.isNotEmpty ? group.name[0] : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (group.description != null &&
                    group.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      group.description!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String inviteCode;

  const _InviteCodeCard({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              const Text(
                '招待コード',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colors.glassBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                inviteCode,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('コードをコピーしました')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('コピー'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Himatchに参加しよう！招待コード: $inviteCode',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('共有'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final isOwner = member.role == 'owner';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOwner
            ? AppColors.warning.withValues(alpha: 0.2)
            : colors.primary.withValues(alpha: 0.15),
        child: Icon(
          isOwner ? Icons.star : Icons.person,
          color: isOwner ? AppColors.warning : colors.primary,
          size: 20,
        ),
      ),
      title: Text(
        member.nickname ?? (member.userId == AppConstants.localUserId ? 'あなた' : 'メンバー'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isOwner ? 'オーナー' : 'メンバー',
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
      trailing: member.userId == AppConstants.localUserId
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '自分',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
