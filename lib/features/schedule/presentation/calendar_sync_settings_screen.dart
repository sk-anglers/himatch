import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

// ─── Sync settings state ───

enum SyncFrequency {
  manual('手動のみ'),
  thirtyMinutes('30分ごと'),
  oneHour('1時間ごと');

  const SyncFrequency(this.label);
  final String label;
}

class CalendarSyncState {
  final bool appleCalendarEnabled;
  final bool googleCalendarEnabled;
  final SyncFrequency syncFrequency;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final bool importEnabled;
  final bool exportEnabled;
  final String? appleCalendarStatus;
  final String? googleCalendarStatus;

  const CalendarSyncState({
    this.appleCalendarEnabled = false,
    this.googleCalendarEnabled = false,
    this.syncFrequency = SyncFrequency.manual,
    this.lastSyncTime,
    this.isSyncing = false,
    this.importEnabled = true,
    this.exportEnabled = true,
    this.appleCalendarStatus,
    this.googleCalendarStatus,
  });

  CalendarSyncState copyWith({
    bool? appleCalendarEnabled,
    bool? googleCalendarEnabled,
    SyncFrequency? syncFrequency,
    DateTime? lastSyncTime,
    bool? isSyncing,
    bool? importEnabled,
    bool? exportEnabled,
    String? appleCalendarStatus,
    String? googleCalendarStatus,
  }) {
    return CalendarSyncState(
      appleCalendarEnabled:
          appleCalendarEnabled ?? this.appleCalendarEnabled,
      googleCalendarEnabled:
          googleCalendarEnabled ?? this.googleCalendarEnabled,
      syncFrequency: syncFrequency ?? this.syncFrequency,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      importEnabled: importEnabled ?? this.importEnabled,
      exportEnabled: exportEnabled ?? this.exportEnabled,
      appleCalendarStatus:
          appleCalendarStatus ?? this.appleCalendarStatus,
      googleCalendarStatus:
          googleCalendarStatus ?? this.googleCalendarStatus,
    );
  }
}

// ─── Provider ───

final calendarSyncProvider =
    NotifierProvider<CalendarSyncNotifier, CalendarSyncState>(
  CalendarSyncNotifier.new,
);

class CalendarSyncNotifier extends Notifier<CalendarSyncState> {
  @override
  CalendarSyncState build() => const CalendarSyncState(
        appleCalendarStatus: '未接続',
        googleCalendarStatus: '未接続',
      );

  void toggleAppleCalendar(bool enabled) {
    state = state.copyWith(
      appleCalendarEnabled: enabled,
      appleCalendarStatus: enabled ? '接続済み' : '未接続',
    );
  }

  void toggleGoogleCalendar(bool enabled) {
    state = state.copyWith(
      googleCalendarEnabled: enabled,
      googleCalendarStatus: enabled ? '認証済み' : '未接続',
    );
  }

  void setSyncFrequency(SyncFrequency freq) {
    state = state.copyWith(syncFrequency: freq);
  }

  void toggleImport(bool enabled) {
    state = state.copyWith(importEnabled: enabled);
  }

  void toggleExport(bool enabled) {
    state = state.copyWith(exportEnabled: enabled);
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true);
    // Simulate sync delay
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: DateTime.now(),
    );
  }
}

// ─── Screen ───

class CalendarSyncSettingsScreen extends ConsumerWidget {
  const CalendarSyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(calendarSyncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー同期設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Connected calendars section ───
          _buildSectionHeader('接続済みカレンダー'),
          const SizedBox(height: 8),

          // Apple Calendar
          _buildCalendarToggleCard(
            icon: Icons.apple,
            title: 'Apple カレンダー',
            subtitle: syncState.appleCalendarStatus ?? '未接続',
            value: syncState.appleCalendarEnabled,
            onChanged: (v) {
              ref.read(calendarSyncProvider.notifier).toggleAppleCalendar(v);
            },
          ),
          const SizedBox(height: 8),

          // Google Calendar
          _buildCalendarToggleCard(
            icon: Icons.event,
            iconColor: const Color(0xFF4285F4),
            title: 'Google カレンダー',
            subtitle: syncState.googleCalendarStatus ?? '未接続',
            value: syncState.googleCalendarEnabled,
            onChanged: (v) {
              ref
                  .read(calendarSyncProvider.notifier)
                  .toggleGoogleCalendar(v);
            },
          ),
          const SizedBox(height: 24),

          // ─── Sync frequency ───
          _buildSectionHeader('同期頻度'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: SyncFrequency.values.map((freq) {
                  return RadioListTile<SyncFrequency>(
                    title: Text(
                      freq.label,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: freq,
                    groupValue: syncState.syncFrequency,
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(calendarSyncProvider.notifier)
                            .setSyncFrequency(v);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Import/Export direction ───
          _buildSectionHeader('同期方向'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('インポート（外部 → ヒマッチ）',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text('外部カレンダーの予定を取り込む',
                      style: TextStyle(fontSize: 12)),
                  value: syncState.importEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    ref.read(calendarSyncProvider.notifier).toggleImport(v);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('エクスポート（ヒマッチ → 外部）',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text('ヒマッチの予定を外部カレンダーに反映',
                      style: TextStyle(fontSize: 12)),
                  value: syncState.exportEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    ref.read(calendarSyncProvider.notifier).toggleExport(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Last sync info + sync button ───
          _buildSectionHeader('同期状態'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 18, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Text(
                        syncState.lastSyncTime != null
                            ? '最終同期: ${_formatSyncTime(syncState.lastSyncTime!)}'
                            : '最終同期: まだ同期されていません',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: syncState.isSyncing
                          ? null
                          : () {
                              ref
                                  .read(calendarSyncProvider.notifier)
                                  .syncNow();
                            },
                      icon: syncState.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync, size: 18),
                      label: Text(syncState.isSyncing ? '同期中...' : '今すぐ同期'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCalendarToggleCard({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.textPrimary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.textPrimary),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: value ? AppColors.success : AppColors.textHint,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
