import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';

/// Notification settings screen.
/// Allows users to configure notification preferences per category
/// and per group, with default reminder time selection.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(_notificationSettingsProvider);
    final groups = ref.watch(localGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification toggles
          _SectionHeader(title: '通知設定'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _NotificationToggle(
                  icon: Icons.lightbulb_outline,
                  title: '新しい提案',
                  subtitle: 'グループに新しい候補日が提案されたとき',
                  value: settings.newSuggestions,
                  onChanged: (v) {
                    ref
                        .read(_notificationSettingsProvider.notifier)
                        .update((s) => s.copyWith(newSuggestions: v));
                  },
                ),
                const Divider(height: 1),
                _NotificationToggle(
                  icon: Icons.how_to_vote_outlined,
                  title: '投票リマインド',
                  subtitle: 'まだ投票していない提案があるとき',
                  value: settings.voteReminder,
                  onChanged: (v) {
                    ref
                        .read(_notificationSettingsProvider.notifier)
                        .update((s) => s.copyWith(voteReminder: v));
                  },
                ),
                const Divider(height: 1),
                _NotificationToggle(
                  icon: Icons.event_available,
                  title: '予定確定',
                  subtitle: 'グループの予定が確定したとき',
                  value: settings.scheduleConfirmed,
                  onChanged: (v) {
                    ref
                        .read(_notificationSettingsProvider.notifier)
                        .update((s) => s.copyWith(scheduleConfirmed: v));
                  },
                ),
                const Divider(height: 1),
                _NotificationToggle(
                  icon: Icons.chat_bubble_outline,
                  title: 'チャットメッセージ',
                  subtitle: 'グループチャットの新着メッセージ',
                  value: settings.chatMessages,
                  onChanged: (v) {
                    ref
                        .read(_notificationSettingsProvider.notifier)
                        .update((s) => s.copyWith(chatMessages: v));
                  },
                ),
                const Divider(height: 1),
                _NotificationToggle(
                  icon: Icons.notifications_active_outlined,
                  title: 'アクティビティ',
                  subtitle: 'メンバーのスケジュール更新など',
                  value: settings.activity,
                  onChanged: (v) {
                    ref
                        .read(_notificationSettingsProvider.notifier)
                        .update((s) => s.copyWith(activity: v));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reminder settings
          _SectionHeader(title: 'リマインダー'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.alarm, color: AppColors.primary),
                  title: const Text('デフォルトリマインダー'),
                  subtitle: Text(
                    _reminderLabel(settings.defaultReminderMinutes),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textHint),
                  onTap: () => _showReminderPicker(context, ref, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Per-group mute settings
          _SectionHeader(title: 'グループ別設定'),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'グループに参加するとここに表示されます',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: groups.asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  final isMuted =
                      settings.mutedGroupIds.contains(group.id);

                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 1),
                      SwitchListTile(
                        title: Text(group.name),
                        subtitle: Text(
                          isMuted ? 'ミュート中' : '通知を受け取る',
                          style: TextStyle(
                            fontSize: 12,
                            color: isMuted
                                ? AppColors.textHint
                                : AppColors.textSecondary,
                          ),
                        ),
                        value: !isMuted,
                        onChanged: (enabled) {
                          ref
                              .read(_notificationSettingsProvider.notifier)
                              .update((s) {
                            final updated =
                                Set<String>.from(s.mutedGroupIds);
                            if (enabled) {
                              updated.remove(group.id);
                            } else {
                              updated.add(group.id);
                            }
                            return s.copyWith(mutedGroupIds: updated);
                          });
                        },
                        activeThumbColor: AppColors.primary,
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.primaryLight.withValues(alpha: 0.3),
                          child: Text(
                            group.name.isNotEmpty ? group.name[0] : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _reminderLabel(int? minutes) {
    if (minutes == null) return 'なし';
    return switch (minutes) {
      5 => '5分前',
      15 => '15分前',
      30 => '30分前',
      60 => '1時間前',
      1440 => '1日前',
      _ => '$minutes分前',
    };
  }

  void _showReminderPicker(
    BuildContext context,
    WidgetRef ref,
    _NotificationSettings settings,
  ) {
    final options = <(int?, String)>[
      (null, 'なし'),
      (5, '5分前'),
      (15, '15分前'),
      (30, '30分前'),
      (60, '1時間前'),
      (1440, '1日前'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('デフォルトリマインダー'),
        children: options.map((option) {
          final isSelected =
              settings.defaultReminderMinutes == option.$1;
          return ListTile(
            leading: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            title: Text(option.$2),
            onTap: () {
              ref
                  .read(_notificationSettingsProvider.notifier)
                  .update((s) =>
                      s.copyWith(defaultReminderMinutes: option.$1));
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

// ── Notification toggle tile ──

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      secondary: Icon(icon, color: AppColors.textSecondary),
    );
  }
}

// ── Local notification settings state ──

class _NotificationSettings {
  final bool newSuggestions;
  final bool voteReminder;
  final bool scheduleConfirmed;
  final bool chatMessages;
  final bool activity;
  final int? defaultReminderMinutes;
  final Set<String> mutedGroupIds;

  const _NotificationSettings({
    this.newSuggestions = true,
    this.voteReminder = true,
    this.scheduleConfirmed = true,
    this.chatMessages = true,
    this.activity = true,
    this.defaultReminderMinutes = 15,
    this.mutedGroupIds = const {},
  });

  _NotificationSettings copyWith({
    bool? newSuggestions,
    bool? voteReminder,
    bool? scheduleConfirmed,
    bool? chatMessages,
    bool? activity,
    int? defaultReminderMinutes,
    Set<String>? mutedGroupIds,
  }) {
    return _NotificationSettings(
      newSuggestions: newSuggestions ?? this.newSuggestions,
      voteReminder: voteReminder ?? this.voteReminder,
      scheduleConfirmed: scheduleConfirmed ?? this.scheduleConfirmed,
      chatMessages: chatMessages ?? this.chatMessages,
      activity: activity ?? this.activity,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
      mutedGroupIds: mutedGroupIds ?? this.mutedGroupIds,
    );
  }
}

class _NotificationSettingsNotifier extends Notifier<_NotificationSettings> {
  @override
  _NotificationSettings build() => const _NotificationSettings();

  void update(_NotificationSettings Function(_NotificationSettings s) updater) {
    state = updater(state);
  }
}

final _notificationSettingsProvider =
    NotifierProvider<_NotificationSettingsNotifier, _NotificationSettings>(
  _NotificationSettingsNotifier.new,
);

// ── Section header ──

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
