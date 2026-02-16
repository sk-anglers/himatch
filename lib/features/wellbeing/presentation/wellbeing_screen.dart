import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Health & wellbeing dashboard screen.
/// Tracks mood, energy, stress, habits, and provides insights.
class WellbeingScreen extends ConsumerStatefulWidget {
  const WellbeingScreen({super.key});

  @override
  ConsumerState<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends ConsumerState<WellbeingScreen> {
  // Today's mood state
  int? _selectedMoodIndex;
  int? _selectedEnergyIndex;
  double _stressLevel = 5;
  final _noteController = TextEditingController();

  // Demo habit data
  final List<_HabitData> _habits = [
    _HabitData(
      name: '早起き',
      emoji: '🌅',
      color: AppColors.warning,
      streak: 5,
      completedToday: true,
      weekProgress: [true, true, true, false, true, true, false],
    ),
    _HabitData(
      name: '運動',
      emoji: '🏃',
      color: AppColors.success,
      streak: 3,
      completedToday: false,
      weekProgress: [true, false, true, true, false, false, false],
    ),
    _HabitData(
      name: '読書',
      emoji: '📚',
      color: AppColors.primary,
      streak: 12,
      completedToday: true,
      weekProgress: [true, true, true, true, true, true, true],
    ),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ウェルビーイング'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mood input section
          _SectionHeader(title: '今日の気分'),
          const SizedBox(height: 8),
          _MoodInputCard(
            selectedIndex: _selectedMoodIndex,
            onSelected: (i) => setState(() => _selectedMoodIndex = i),
          ),
          const SizedBox(height: 16),

          // Energy level
          _SectionHeader(title: 'エネルギーレベル'),
          const SizedBox(height: 8),
          _EnergyInputCard(
            selectedIndex: _selectedEnergyIndex,
            onSelected: (i) => setState(() => _selectedEnergyIndex = i),
          ),
          const SizedBox(height: 16),

          // Stress slider
          _SectionHeader(title: 'ストレス'),
          const SizedBox(height: 8),
          _StressSliderCard(
            value: _stressLevel,
            onChanged: (v) => setState(() => _stressLevel = v),
          ),
          const SizedBox(height: 16),

          // Optional note
          _SectionHeader(title: 'メモ (任意)'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: '今日の気持ちをメモ...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),

          // Save button
          if (_selectedMoodIndex != null)
            ElevatedButton(
              onPressed: _saveMoodEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '記録する',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          const SizedBox(height: 24),

          // Weekly mood chart
          _SectionHeader(title: '今週の気分'),
          const SizedBox(height: 8),
          _WeeklyMoodChart(),
          const SizedBox(height: 24),

          // Habit tracker
          _SectionHeader(title: '習慣トラッカー'),
          const SizedBox(height: 8),
          ...List.generate(_habits.length, (index) {
            final habit = _habits[index];
            return _HabitCard(
              habit: habit,
              onToggle: () {
                setState(() {
                  _habits[index] = habit.copyWith(
                    completedToday: !habit.completedToday,
                  );
                });
              },
            );
          }),
          const SizedBox(height: 8),

          // Add habit button
          OutlinedButton.icon(
            onPressed: _showAddHabitDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('習慣を追加'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Insight cards
          _SectionHeader(title: 'インサイト'),
          const SizedBox(height: 8),
          _InsightCard(
            icon: Icons.movie,
            iconColor: AppColors.primary,
            text: '映画の後は気分が良い傾向があります',
          ),
          const SizedBox(height: 8),
          _InsightCard(
            icon: Icons.wb_sunny,
            iconColor: AppColors.warning,
            text: '晴れの日は運動の達成率が高いです',
          ),
          const SizedBox(height: 8),
          _InsightCard(
            icon: Icons.group,
            iconColor: AppColors.success,
            text: '友達と遊んだ翌日はストレスが低い傾向',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _saveMoodEntry() {
    // TODO: Save via wellbeing_providers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('今日の気分を記録しました'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showAddHabitDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新しい習慣'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '習慣の名前',
            hintText: '例: 瞑想、散歩、日記',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _habits.add(_HabitData(
                    name: name,
                    emoji: '✅',
                    color: AppColors.primary,
                    streak: 0,
                    completedToday: false,
                    weekProgress: List.filled(7, false),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
    nameController.dispose();
  }
}

// ── Mood input ──

class _MoodInputCard extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  static const _moods = [
    ('😊', '最高', AppColors.moodGreat),
    ('😌', '良い', AppColors.moodGood),
    ('😐', '普通', AppColors.moodNeutral),
    ('😔', '低め', AppColors.moodLow),
    ('😢', '悪い', AppColors.moodBad),
  ];

  const _MoodInputCard({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_moods.length, (i) {
            final (emoji, label, color) = _moods[i];
            final isSelected = selectedIndex == i;

            return GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Energy input ──

class _EnergyInputCard extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  static const _levels = [
    ('⚡', '高い', AppColors.success),
    ('💪', '普通', AppColors.warning),
    ('😴', '低い', AppColors.error),
  ];

  const _EnergyInputCard({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_levels.length, (i) {
            final (emoji, label, color) = _levels[i];
            final isSelected = selectedIndex == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: color, width: 2)
                        : Border.all(
                            color: AppColors.surfaceVariant, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? color : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Stress slider ──

class _StressSliderCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _StressSliderCard({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stressColor = value <= 3
        ? AppColors.success
        : value <= 6
            ? AppColors.warning
            : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '低い',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: stressColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${value.round()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: stressColor,
                    ),
                  ),
                ),
                const Text(
                  '高い',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: stressColor,
              inactiveColor: stressColor.withValues(alpha: 0.2),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly mood chart ──

class _WeeklyMoodChart extends StatelessWidget {
  // Demo data: mood levels for 7 days (0=no data, 1-5 mood scale)
  final List<int> _weekMoods = const [5, 4, 3, 4, 0, 5, 3];
  final List<String> _dayLabels = const ['月', '火', '水', '木', '金', '土', '日'];

  static const _moodColors = [
    Colors.transparent,
    AppColors.moodBad,
    AppColors.moodLow,
    AppColors.moodNeutral,
    AppColors.moodGood,
    AppColors.moodGreat,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) {
            final mood = _weekMoods[i];
            final hasData = mood > 0;
            final color = hasData ? _moodColors[mood] : AppColors.surfaceVariant;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hasData
                        ? color.withValues(alpha: 0.3)
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: hasData
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: hasData
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            '-',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dayLabels[i],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Habit card ──

class _HabitData {
  final String name;
  final String emoji;
  final Color color;
  final int streak;
  final bool completedToday;
  final List<bool> weekProgress;

  const _HabitData({
    required this.name,
    required this.emoji,
    required this.color,
    required this.streak,
    required this.completedToday,
    required this.weekProgress,
  });

  _HabitData copyWith({
    String? name,
    String? emoji,
    Color? color,
    int? streak,
    bool? completedToday,
    List<bool>? weekProgress,
  }) {
    return _HabitData(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      streak: streak ?? this.streak,
      completedToday: completedToday ?? this.completedToday,
      weekProgress: weekProgress ?? this.weekProgress,
    );
  }
}

class _HabitCard extends StatelessWidget {
  final _HabitData habit;
  final VoidCallback onToggle;

  const _HabitCard({required this.habit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final completedDays = habit.weekProgress.where((b) => b).length;
    final progressRatio = completedDays / 7.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox for today
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: habit.completedToday
                      ? habit.color
                      : habit.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: habit.color,
                    width: habit.completedToday ? 0 : 2,
                  ),
                ),
                child: habit.completedToday
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : Center(
                        child: Text(
                          habit.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + streak
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (habit.streak > 0)
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text(
                          '${habit.streak}日連続',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: habit.color,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Progress ring
            SizedBox(
              width: 44,
              height: 44,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: progressRatio,
                  color: habit.color,
                ),
                child: Center(
                  child: Text(
                    '$completedDays/7',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: habit.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 3;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ── Insight card ──

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
