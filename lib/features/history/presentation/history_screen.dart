import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Past confirmed plans history and statistics screen.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('アクティビティ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '履歴'),
              Tab(text: '統計'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoryTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

// ── History tab: chronological list ──

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    // Demo data for confirmed suggestions history
    final history = _generateDemoHistory();

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history,
                  size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              const Text(
                'まだ履歴がありません',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '予定が確定すると\nここに履歴が表示されます',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _HistoryCard(item: item);
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to detail view with photos/expenses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.activity}の詳細を表示')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + weather
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.weatherIcon != null) ...[
                    Text(item.weatherIcon!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: 10),

              // Activity name
              Row(
                children: [
                  Icon(item.activityIcon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    item.activity,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Group name
              Row(
                children: [
                  const Icon(Icons.group_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    item.groupName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Member avatars
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    ...item.memberNames.take(5).map((name) {
                      return Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }),
                    if (item.memberNames.length > 5)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+${item.memberNames.length - 5}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats tab: aggregated statistics ──

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big number: total activities this year
        _BigStatCard(
          label: '今年の遊び回数',
          value: '24',
          unit: '回',
          icon: Icons.celebration,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),

        // Monthly bar chart
        const _SectionHeader(title: '月別アクティビティ'),
        const SizedBox(height: 8),
        _MonthlyBarChart(),
        const SizedBox(height: 24),

        // Frequent friends
        const _SectionHeader(title: 'よく一緒に遊ぶ人'),
        const SizedBox(height: 8),
        _FriendRanking(),
        const SizedBox(height: 24),

        // Popular activities (pie chart)
        const _SectionHeader(title: '人気のアクティビティ'),
        const SizedBox(height: 8),
        _ActivityPieChart(),
        const SizedBox(height: 24),

        // Day of week distribution
        const _SectionHeader(title: 'よく集まる曜日'),
        const SizedBox(height: 8),
        _DayOfWeekChart(),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _BigStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  // Demo data: monthly activity counts
  final List<int> _data = const [2, 3, 1, 4, 2, 3, 5, 2, 0, 0, 0, 0];
  final List<String> _labels = const [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月',
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal = _data.reduce(max).toDouble();
    const barMaxHeight = 100.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: barMaxHeight + 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_data.length, (i) {
              final height = maxVal > 0
                  ? (_data[i] / maxVal) * barMaxHeight
                  : 0.0;
              final isCurrentMonth = i == DateTime.now().month - 1;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_data[i] > 0)
                      Text(
                        '${_data[i]}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isCurrentMonth
                            ? AppColors.primary
                            : AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 9,
                        color: isCurrentMonth
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontWeight: isCurrentMonth
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FriendRanking extends StatelessWidget {
  final List<(String, int)> _friends = const [
    ('たくや', 12),
    ('さくら', 9),
    ('けんた', 7),
    ('ゆうき', 5),
    ('はるか', 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: _friends.asMap().entries.map((entry) {
            final index = entry.key;
            final (name, count) = entry.value;
            final medalColors = [
              AppColors.warning,
              AppColors.textHint,
              const Color(0xFFCD7F32),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 28,
                    child: index < 3
                        ? Icon(Icons.emoji_events,
                            size: 20, color: medalColors[index])
                        : Text(
                            '${index + 1}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.3),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count回',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActivityPieChart extends StatelessWidget {
  final List<(String, int, Color)> _activities = const [
    ('飲み会', 8, AppColors.secondary),
    ('ランチ', 6, AppColors.primary),
    ('カラオケ', 4, AppColors.success),
    ('映画', 3, Color(0xFF3498DB)),
    ('その他', 3, AppColors.textHint),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _activities.fold<int>(0, (sum, a) => sum + a.$2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Simple pie chart using stacked containers
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _PieChartPainter(
                  data: _activities.map((a) => a.$2.toDouble()).toList(),
                  colors: _activities.map((a) => a.$3).toList(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _activities.map((activity) {
                  final percentage =
                      total > 0 ? (activity.$2 / total * 100).round() : 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: activity.$3,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.$1,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  _PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (sum, d) => sum + d);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 2 * pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Center hole (donut effect)
    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DayOfWeekChart extends StatelessWidget {
  final List<(String, int)> _dayData = const [
    ('月', 2),
    ('火', 1),
    ('水', 3),
    ('木', 1),
    ('金', 5),
    ('土', 8),
    ('日', 4),
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal = _dayData.map((d) => d.$2).reduce(max).toDouble();
    const barMaxHeight = 80.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: barMaxHeight + 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _dayData.map((day) {
              final height = maxVal > 0
                  ? (day.$2 / maxVal) * barMaxHeight
                  : 0.0;
              final isWeekend = day.$1 == '土' || day.$1 == '日';

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (day.$2 > 0)
                      Text(
                        '${day.$2}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isWeekend
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isWeekend
                            ? AppColors.secondary.withValues(alpha: 0.7)
                            : AppColors.primary.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: isWeekend
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                        fontWeight:
                            isWeekend ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
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

// ── Demo data ──

class _HistoryItem {
  final String dateLabel;
  final String activity;
  final IconData activityIcon;
  final String groupName;
  final List<String> memberNames;
  final String? weatherIcon;

  const _HistoryItem({
    required this.dateLabel,
    required this.activity,
    required this.activityIcon,
    required this.groupName,
    required this.memberNames,
    this.weatherIcon,
  });
}

List<_HistoryItem> _generateDemoHistory() {
  return const [
    _HistoryItem(
      dateLabel: '2/8 (土)',
      activity: '飲み会',
      activityIcon: Icons.local_bar,
      groupName: '大学の友達',
      memberNames: ['たくや', 'さくら', 'けんた'],
      weatherIcon: '🌤',
    ),
    _HistoryItem(
      dateLabel: '1/25 (土)',
      activity: 'カラオケ',
      activityIcon: Icons.mic,
      groupName: 'バイト仲間',
      memberNames: ['ゆうき', 'はるか', 'まい', 'りょう'],
      weatherIcon: '☁️',
    ),
    _HistoryItem(
      dateLabel: '1/18 (土)',
      activity: 'ランチ',
      activityIcon: Icons.restaurant,
      groupName: '大学の友達',
      memberNames: ['たくや', 'さくら'],
      weatherIcon: '☀️',
    ),
    _HistoryItem(
      dateLabel: '1/11 (土)',
      activity: '映画',
      activityIcon: Icons.movie,
      groupName: '高校の友達',
      memberNames: ['こうた', 'あや', 'しゅん', 'なな', 'けんじ', 'みく'],
      weatherIcon: '🌧',
    ),
    _HistoryItem(
      dateLabel: '12/28 (土)',
      activity: '忘年会',
      activityIcon: Icons.celebration,
      groupName: '大学の友達',
      memberNames: ['たくや', 'さくら', 'けんた', 'ゆうき', 'はるか'],
      weatherIcon: '❄️',
    ),
  ];
}
