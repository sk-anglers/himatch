import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/shift_pattern.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/models/schedule.dart';
import 'package:uuid/uuid.dart';

// ─── Provider ───

final shiftPatternsProvider =
    NotifierProvider<ShiftPatternsNotifier, List<ShiftPattern>>(
  ShiftPatternsNotifier.new,
);

class ShiftPatternsNotifier extends Notifier<List<ShiftPattern>> {
  @override
  List<ShiftPattern> build() => [
        ShiftPattern(
          id: 'sp-demo-1',
          userId: 'local-user',
          name: '早番・遅番ローテ',
          color: 'FF6C5CE7',
          shifts: const [
            ShiftDefinition(label: '早番', start: '06:00', end: '14:00', color: 'FF3498DB'),
            ShiftDefinition(label: '遅番', start: '14:00', end: '22:00', color: 'FFE17055'),
            ShiftDefinition(label: '休み', color: 'FF00B894'),
          ],
          rotationDays: 3,
          createdAt: DateTime.now(),
        ),
      ];

  void add(ShiftPattern pattern) {
    state = [...state, pattern];
  }

  void update(ShiftPattern updated) {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

// ─── Screen ───

class ShiftPatternScreen extends ConsumerWidget {
  const ShiftPatternScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(shiftPatternsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('シフトパターン')),
      body: patterns.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text(
                    'パターンがありません',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'シフトの繰り返しパターンを作成しましょう',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: patterns.length,
              itemBuilder: (context, index) {
                return _PatternCard(
                  pattern: patterns[index],
                  onEdit: () => _openEditor(context, ref,
                      pattern: patterns[index]),
                  onDelete: () =>
                      _confirmDelete(context, ref, patterns[index]),
                  onApply: () =>
                      _showApplyDialog(context, ref, patterns[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref,
      {ShiftPattern? pattern}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ShiftPatternEditorScreen(
          pattern: pattern,
          onSave: (p) {
            if (pattern != null) {
              ref.read(shiftPatternsProvider.notifier).update(p);
            } else {
              ref.read(shiftPatternsProvider.notifier).add(p);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ShiftPattern pattern) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${pattern.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shiftPatternsProvider.notifier).remove(pattern.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('削除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(
      BuildContext context, WidgetRef ref, ShiftPattern pattern) {
    DateTime startDate = DateTime.now();
    int days = 28;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('カレンダーに適用'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '「${pattern.name}」を適用します',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              // Start date picker
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    locale: const Locale('ja'),
                  );
                  if (date != null) {
                    setDialogState(() => startDate = date);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  '開始日: ${startDate.year}/${startDate.month}/${startDate.day}',
                ),
              ),
              const SizedBox(height: 12),
              // Number of days
              Row(
                children: [
                  const Text('適用日数: ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: TextEditingController(text: '$days'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        days = int.tryParse(v) ?? 28;
                      },
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const Text('日間',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyPatternToCalendar(ref, pattern, startDate, days);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${pattern.name}を${days}日間適用しました'),
                  ),
                );
              },
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPatternToCalendar(
      WidgetRef ref, ShiftPattern pattern, DateTime startDate, int days) {
    final notifier = ref.read(localSchedulesProvider.notifier);
    final shifts = pattern.shifts;
    if (shifts.isEmpty) return;

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final shiftIndex = i % shifts.length;
      final shift = shifts[shiftIndex];

      DateTime scheduleStart;
      DateTime scheduleEnd;

      if (shift.start != null && shift.end != null) {
        final sp = shift.start!.split(':');
        final ep = shift.end!.split(':');
        scheduleStart = DateTime(
          date.year, date.month, date.day,
          int.parse(sp[0]), int.parse(sp[1]),
        );
        scheduleEnd = DateTime(
          date.year, date.month, date.day,
          int.parse(ep[0]), int.parse(ep[1]),
        );
        if (scheduleEnd.isBefore(scheduleStart)) {
          scheduleEnd = scheduleEnd.add(const Duration(days: 1));
        }
      } else {
        // All-day (off day)
        scheduleStart = DateTime(date.year, date.month, date.day);
        scheduleEnd = DateTime(date.year, date.month, date.day, 23, 59);
      }

      final isOff = shift.start == null;
      notifier.addSchedule(
        title: shift.label,
        scheduleType: isOff ? ScheduleType.free : ScheduleType.shift,
        startTime: scheduleStart,
        endTime: scheduleEnd,
        isAllDay: isOff,
        color: shift.color,
      );
    }
  }
}

// ─── Pattern card ───

class _PatternCard extends StatelessWidget {
  final ShiftPattern pattern;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApply;

  const _PatternCard({
    required this.pattern,
    required this.onEdit,
    required this.onDelete,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    pattern.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (pattern.rotationDays != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pattern.rotationDays}日周期',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('編集')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('削除', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Shift sequence as colored pills
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pattern.shifts.map((shift) {
                final color = shift.color != null
                    ? Color(int.parse(shift.color!, radix: 16))
                    : AppColors.primary;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        shift.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      if (shift.start != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${shift.start}-${shift.end}',
                          style: TextStyle(
                            fontSize: 10,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('カレンダーに適用'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

// ─── Editor screen ───

class _ShiftPatternEditorScreen extends StatefulWidget {
  final ShiftPattern? pattern;
  final ValueChanged<ShiftPattern> onSave;

  const _ShiftPatternEditorScreen({this.pattern, required this.onSave});

  @override
  State<_ShiftPatternEditorScreen> createState() =>
      _ShiftPatternEditorScreenState();
}

class _ShiftPatternEditorScreenState extends State<_ShiftPatternEditorScreen> {
  static const _uuid = Uuid();
  late final TextEditingController _nameController;
  late final TextEditingController _rotationController;
  late List<ShiftDefinition> _shifts;

  bool get _isEditing => widget.pattern != null;

  static const _shiftColors = [
    'FF3498DB', // blue
    'FFE17055', // red
    'FF00B894', // green
    'FFF39C12', // orange
    'FF6C5CE7', // purple
    'FFE84393', // pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.pattern?.name ?? '');
    _rotationController = TextEditingController(
        text: widget.pattern?.rotationDays?.toString() ?? '');
    _shifts = widget.pattern?.shifts.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'パターンを編集' : '新しいパターン'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pattern name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'パターン名',
                hintText: '例: 早番・遅番ローテ',
              ),
            ),
            const SizedBox(height: 16),

            // Rotation days (optional)
            TextField(
              controller: _rotationController,
              decoration: const InputDecoration(
                labelText: '周期日数（任意）',
                hintText: '例: 3',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Shifts list
            Row(
              children: [
                const Text(
                  'シフト一覧',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addShift,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('追加'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_shifts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'シフトを追加してください',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textHint),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shifts.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _shifts.removeAt(oldIndex);
                    _shifts.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final shift = _shifts[index];
                  final color = shift.color != null
                      ? Color(int.parse(shift.color!, radix: 16))
                      : AppColors.primary;

                  return Card(
                    key: ValueKey('shift-$index'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 12,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        shift.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: shift.start != null
                          ? Text('${shift.start} - ${shift.end}')
                          : const Text('終日（休み）'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editShift(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: AppColors.error,
                            onPressed: () {
                              setState(() => _shifts.removeAt(index));
                            },
                          ),
                          const Icon(Icons.drag_handle,
                              color: AppColors.textHint),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addShift() {
    _showShiftEditDialog(null, (shift) {
      setState(() => _shifts.add(shift));
    });
  }

  void _editShift(int index) {
    _showShiftEditDialog(_shifts[index], (shift) {
      setState(() => _shifts[index] = shift);
    });
  }

  void _showShiftEditDialog(
      ShiftDefinition? existing, ValueChanged<ShiftDefinition> onDone) {
    final labelCtrl =
        TextEditingController(text: existing?.label ?? '');
    final startCtrl =
        TextEditingController(text: existing?.start ?? '');
    final endCtrl = TextEditingController(text: existing?.end ?? '');
    int colorIndex = 0;
    if (existing?.color != null) {
      final idx = _shiftColors.indexOf(existing!.color!);
      if (idx >= 0) colorIndex = idx;
    }
    bool isOff = existing?.start == null && existing != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'シフトを編集' : 'シフトを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'ラベル',
                  hintText: '例: 早番',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('休日（終日）'),
                value: isOff,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setDialogState(() => isOff = v),
              ),
              if (!isOff) ...[
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: '開始時刻',
                    hintText: '09:00',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: '終了時刻',
                    hintText: '17:00',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(_shiftColors.length, (i) {
                  final c =
                      Color(int.parse(_shiftColors[i], radix: 16));
                  return GestureDetector(
                    onTap: () => setDialogState(() => colorIndex = i),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: i == colorIndex
                            ? Border.all(
                                color: AppColors.textPrimary, width: 2)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                onDone(ShiftDefinition(
                  label: label,
                  start: isOff ? null : startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
                  end: isOff ? null : endCtrl.text.trim().isEmpty ? null : endCtrl.text.trim(),
                  color: _shiftColors[colorIndex],
                ));
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パターン名を入力してください')),
      );
      return;
    }
    if (_shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('少なくとも1つのシフトを追加してください')),
      );
      return;
    }

    final rotation = int.tryParse(_rotationController.text.trim());

    widget.onSave(ShiftPattern(
      id: widget.pattern?.id ?? _uuid.v4(),
      userId: widget.pattern?.userId ?? 'local-user',
      name: name,
      shifts: _shifts,
      rotationDays: rotation,
      createdAt: widget.pattern?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    Navigator.of(context).pop();
  }
}
