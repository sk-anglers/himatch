import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/routing/app_routes.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';
import 'package:himatch/features/profile/presentation/providers/profile_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/features/profile/presentation/providers/location_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final settings = ref.watch(profileSettingsProvider);
    final groups = ref.watch(localGroupsProvider);
    final schedules = ref.watch(localSchedulesProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demo mode banner
          if (authState.isDemo)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'デモモードで動作中',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Profile header
          _ProfileHeader(
            displayName: authState.displayName ?? settings.displayName,
            groupCount: groups.length,
            scheduleCount: schedules.length,
            onNameTap: () => _showEditNameDialog(context, ref, settings),
          ),
          const SizedBox(height: 24),

          // Quick access features
          _SectionHeader(title: '機能'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _NavTile(
                icon: Icons.currency_yen,
                iconColor: AppColors.typeParttime,
                title: '給料計算',
                subtitle: '月間・年間の給料を確認',
                onTap: () => context.pushNamed(AppRoute.salarySummary.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.work_outline,
                iconColor: AppColors.typeClass,
                title: '勤務先設定',
                subtitle: '時給・締め日・手当の設定',
                onTap: () => context.pushNamed(AppRoute.workplaceSettings.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.repeat,
                iconColor: AppColors.secondary,
                title: 'シフトパターン',
                subtitle: 'ローテーション・パターン設定',
                onTap: () => context.pushNamed(AppRoute.shiftPattern.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.history,
                iconColor: AppColors.success,
                title: '履歴・統計',
                subtitle: '遊んだ記録と統計',
                onTap: () => context.pushNamed(AppRoute.history.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.self_improvement,
                iconColor: AppColors.moodGood,
                title: 'ウェルビーイング',
                subtitle: '気分・習慣トラッカー',
                onTap: () => context.pushNamed(AppRoute.wellbeing.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.calendar_view_day,
                iconColor: AppColors.primary,
                title: '予約ページ',
                subtitle: '空き時間を公開・予約受付',
                onTap: () => context.pushNamed(AppRoute.booking.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.copy_all,
                iconColor: AppColors.typeClub,
                title: 'テンプレート',
                subtitle: 'よく使う予定のテンプレート管理',
                onTap: () => context.pushNamed(AppRoute.templateEditor.name),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Settings section
          _SectionHeader(title: '設定'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _NavTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.primary,
                title: 'テーマ・きせかえ',
                subtitle: 'カラー・ダークモード',
                onTap: () => context.pushNamed(AppRoute.themeSettings.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.warning,
                title: '通知設定',
                subtitle: '通知・リマインダーの設定',
                onTap: () => context.pushNamed(AppRoute.notificationSettings.name),
              ),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.sync,
                iconColor: AppColors.typeClass,
                title: 'カレンダー同期',
                subtitle: 'Apple/Googleカレンダーと同期',
                onTap: () => context.pushNamed(AppRoute.calendarSyncSettings.name),
              ),
              const Divider(height: 1),
              _WeatherLocationTile(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('デフォルト公開範囲'),
                subtitle: Text(_visibilityLabel(settings.defaultVisibility)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showVisibilityPicker(context, ref, settings),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Account section
          _SectionHeader(title: 'アカウント'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('ログアウト',
                    style: TextStyle(color: AppColors.error)),
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // App info section
          _SectionHeader(title: 'アプリ情報'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('バージョン'),
                trailing: Text('0.2.0',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('利用規約'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRoute.termsOfService.name),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('プライバシーポリシー'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRoute.privacyPolicy.name),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.cloud_outlined),
                title: Text('天気データ提供'),
                subtitle: Text(
                  'Open-Meteo.com (CC BY 4.0)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('お問い合わせ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(AppRoute.contact.name),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Center(
            child: Text(
              'Himatch',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _visibilityLabel(String visibility) {
    return switch (visibility) {
      'public' => '全員に公開',
      'friends' => '友達のみ',
      'private' => '自分のみ',
      _ => visibility,
    };
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    ProfileSettings settings,
  ) async {
    final controller = TextEditingController(text: settings.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('表示名を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '表示名',
            hintText: '名前を入力',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && context.mounted) {
      ref.read(profileSettingsProvider.notifier).updateDisplayName(result);
    }
  }

  void _showVisibilityPicker(
    BuildContext context,
    WidgetRef ref,
    ProfileSettings settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('デフォルト公開範囲'),
        children: [
          for (final option in ['public', 'friends', 'private'])
            ListTile(
              leading: Icon(
                option == settings.defaultVisibility
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: option == settings.defaultVisibility
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              title: Text(_visibilityLabel(option)),
              onTap: () {
                ref
                    .read(profileSettingsProvider.notifier)
                    .setDefaultVisibility(option);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('ログアウト',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _WeatherLocationTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(weatherLocationProvider);
    return _NavTile(
      icon: Icons.wb_sunny_outlined,
      iconColor: AppColors.warning,
      title: '天気の地域',
      subtitle: location.name,
      onTap: () => context.pushNamed(AppRoute.weatherLocation.name),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final int groupCount;
  final int scheduleCount;
  final VoidCallback onNameTap;

  const _ProfileHeader({
    required this.displayName,
    required this.groupCount,
    required this.scheduleCount,
    required this.onNameTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Text(
                displayName.isNotEmpty ? displayName[0] : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onNameTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 16, color: AppColors.textHint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  icon: Icons.group,
                  count: groupCount,
                  label: 'グループ',
                ),
                Container(width: 1, height: 32, color: AppColors.surfaceVariant),
                _StatItem(
                  icon: Icons.calendar_month,
                  count: scheduleCount,
                  label: 'スケジュール',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
  }
}
