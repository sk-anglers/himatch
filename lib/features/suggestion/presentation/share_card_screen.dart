import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Share card preview and sharing screen.
/// Generates a visually appealing card for sharing confirmed plans
/// to social media platforms.
class ShareCardScreen extends ConsumerWidget {
  final String? date;
  final String? activity;
  final String? groupName;
  final List<String> memberNames;
  final String? weatherIcon;
  final String? weatherCondition;

  const ShareCardScreen({
    super.key,
    this.date,
    this.activity,
    this.groupName,
    this.memberNames = const [],
    this.weatherIcon,
    this.weatherCondition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repaintKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('シェアカード'),
      ),
      body: Column(
        children: [
          // Card preview
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: RepaintBoundary(
                  key: repaintKey,
                  child: _ShareCard(
                    date: date ?? '2/22 (土)',
                    activity: activity ?? '飲み会',
                    groupName: groupName ?? '大学の友達',
                    memberNames:
                        memberNames.isNotEmpty ? memberNames : ['たくや', 'さくら', 'けんた'],
                    weatherIcon: weatherIcon ?? '🌤',
                    weatherCondition: weatherCondition ?? '晴れ',
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.surfaceVariant),
              ),
            ),
            child: Column(
              children: [
                // Primary actions
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.save_alt,
                        label: '画像を保存',
                        color: AppColors.textPrimary,
                        onTap: () {
                          // TODO: Capture RepaintBoundary and save to gallery
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('画像を保存しました'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share,
                        label: 'シェア',
                        color: AppColors.primary,
                        isPrimary: true,
                        onTap: () {
                          // TODO: Use share_plus to share captured image
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('シェア機能を準備中...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Platform shortcuts
                const _SectionLabel(text: 'SNSへシェア'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SnsButton(
                      label: 'Instagram\nStories',
                      icon: Icons.camera_alt,
                      color: const Color(0xFFE4405F),
                      onTap: () {
                        // TODO: Share to Instagram Stories via deep link
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Instagramストーリーズへ共有...'),
                          ),
                        );
                      },
                    ),
                    _SnsButton(
                      label: 'LINE',
                      icon: Icons.chat_bubble,
                      color: const Color(0xFF00B900),
                      onTap: () {
                        // TODO: Share via LINE
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('LINEへ共有...')),
                        );
                      },
                    ),
                    _SnsButton(
                      label: 'X\n(Twitter)',
                      icon: Icons.alternate_email,
                      color: const Color(0xFF1DA1F2),
                      onTap: () {
                        // TODO: Share via X/Twitter
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('X (Twitter) へ共有...')),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── The actual share card widget ──

class _ShareCard extends StatelessWidget {
  final String date;
  final String activity;
  final String groupName;
  final List<String> memberNames;
  final String weatherIcon;
  final String weatherCondition;

  const _ShareCard({
    required this.date,
    required this.activity,
    required this.groupName,
    required this.memberNames,
    required this.weatherIcon,
    required this.weatherCondition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFFA29BFE),
            Color(0xFFFF6B6B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App branding
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Himatch',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  weatherIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date
            Text(
              date,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weatherCondition,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),

            // Activity
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getActivityEmoji(activity),
                  const SizedBox(width: 8),
                  Text(
                    activity,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Group name
            Row(
              children: [
                Icon(Icons.group,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Member names
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: memberNames.map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Decorative divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '予定確定！',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '🎉',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getActivityEmoji(String activity) {
    final emoji = switch (activity) {
      'ランチ' => '🍽',
      '飲み会' || 'ディナー' => '🍻',
      'カフェ' => '☕',
      '日帰り旅行' => '🚗',
      'お出かけ' || '遊び' => '🎉',
      'カラオケ' => '🎤',
      '映画' => '🎬',
      'BBQ' => '🔥',
      _ => '📅',
    };
    return Text(emoji, style: const TextStyle(fontSize: 22));
  }
}

// ── Action button ──

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ── SNS button ──

class _SnsButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SnsButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
