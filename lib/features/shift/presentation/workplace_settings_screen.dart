import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/workplace.dart';
import 'package:himatch/features/shift/presentation/salary_summary_screen.dart';
import 'package:uuid/uuid.dart';

/// Screen to manage workplace settings (add / edit / delete workplaces).
class WorkplaceSettingsScreen extends ConsumerWidget {
  const WorkplaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workplaces = ref.watch(workplacesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('勤務先設定')),
      body: workplaces.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text(
                    '勤務先が登録されていません',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '右下のボタンから追加してください',
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
              itemCount: workplaces.length,
              itemBuilder: (context, index) {
                return _WorkplaceCard(
                  workplace: workplaces[index],
                  onEdit: () =>
                      _showEditDialog(context, ref, workplace: workplaces[index]),
                  onDelete: () =>
                      _showDeleteConfirmation(context, ref, workplaces[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      {Workplace? workplace}) {
    showDialog(
      context: context,
      builder: (_) => _WorkplaceEditDialog(
        workplace: workplace,
        onSave: (updated) {
          if (workplace != null) {
            ref.read(workplacesProvider.notifier).update(updated);
          } else {
            ref.read(workplacesProvider.notifier).add(updated);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Workplace workplace) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${workplace.name}」を削除しますか？\n関連する給与データにも影響があります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(workplacesProvider.notifier).remove(workplace.id);
              Navigator.pop(ctx);
            },
            child: const Text('削除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Workplace card ───

class _WorkplaceCard extends StatelessWidget {
  final Workplace workplace;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkplaceCard({
    required this.workplace,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = workplace.colorHex != null
        ? Color(int.parse(workplace.colorHex!, radix: 16))
        : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workplace.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.attach_money,
                          label: '¥${workplace.hourlyWage}/h',
                        ),
                        const SizedBox(width: 10),
                        _InfoChip(
                          icon: Icons.calendar_today,
                          label: '締日: ${workplace.closingDay}日',
                        ),
                      ],
                    ),
                    if (workplace.transportCost > 0) ...[
                      const SizedBox(height: 4),
                      _InfoChip(
                        icon: Icons.train,
                        label: '交通費: ¥${workplace.transportCost}',
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.textHint,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Edit dialog ───

class _WorkplaceEditDialog extends StatefulWidget {
  final Workplace? workplace;
  final ValueChanged<Workplace> onSave;

  const _WorkplaceEditDialog({
    this.workplace,
    required this.onSave,
  });

  @override
  State<_WorkplaceEditDialog> createState() => _WorkplaceEditDialogState();
}

class _WorkplaceEditDialogState extends State<_WorkplaceEditDialog> {
  static const _uuid = Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _wageController;
  late final TextEditingController _closingDayController;
  late final TextEditingController _overtimeController;
  late final TextEditingController _nightController;
  late final TextEditingController _holidayController;
  late final TextEditingController _transportController;
  int _selectedColorIndex = 0;

  bool get _isEditing => widget.workplace != null;

  static const _colorOptions = [
    'FF6C5CE7', // purple
    'FFE84393', // pink
    'FF0984E3', // blue
    'FF00B894', // green
    'FFF39C12', // orange
    'FFE17055', // red
    'FF636E72', // gray
  ];

  @override
  void initState() {
    super.initState();
    final wp = widget.workplace;
    _nameController = TextEditingController(text: wp?.name ?? '');
    _wageController =
        TextEditingController(text: wp?.hourlyWage.toString() ?? '');
    _closingDayController =
        TextEditingController(text: (wp?.closingDay ?? 25).toString());
    _overtimeController = TextEditingController(
        text: (wp?.overtimeMultiplier ?? 1.25).toString());
    _nightController =
        TextEditingController(text: (wp?.nightMultiplier ?? 1.25).toString());
    _holidayController = TextEditingController(
        text: (wp?.holidayMultiplier ?? 1.35).toString());
    _transportController =
        TextEditingController(text: (wp?.transportCost ?? 0).toString());

    if (wp?.colorHex != null) {
      final idx = _colorOptions.indexOf(wp!.colorHex!);
      if (idx >= 0) _selectedColorIndex = idx;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wageController.dispose();
    _closingDayController.dispose();
    _overtimeController.dispose();
    _nightController.dispose();
    _holidayController.dispose();
    _transportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '勤務先を編集' : '勤務先を追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '勤務先名',
                hintText: '例: カフェバイト',
              ),
            ),
            const SizedBox(height: 12),

            // Hourly wage
            TextField(
              controller: _wageController,
              decoration: const InputDecoration(
                labelText: '時給（円）',
                hintText: '例: 1200',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),

            // Closing day
            TextField(
              controller: _closingDayController,
              decoration: const InputDecoration(
                labelText: '締日（1-28）',
                hintText: '例: 25',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Multipliers section
            const Text(
              '割増率',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _overtimeController,
                    decoration: const InputDecoration(
                      labelText: '残業',
                      hintText: '1.25',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nightController,
                    decoration: const InputDecoration(
                      labelText: '深夜',
                      hintText: '1.25',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _holidayController,
                    decoration: const InputDecoration(
                      labelText: '休日',
                      hintText: '1.35',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transport cost
            TextField(
              controller: _transportController,
              decoration: const InputDecoration(
                labelText: '交通費（1日あたり、円）',
                hintText: '例: 500',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Color picker
            const Text(
              'カラー',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(_colorOptions.length, (index) {
                final color =
                    Color(int.parse(_colorOptions[index], radix: 16));
                final isSelected = index == _selectedColorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('勤務先名を入力してください')),
      );
      return;
    }

    final wage = int.tryParse(_wageController.text.trim());
    if (wage == null || wage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('時給を正しく入力してください')),
      );
      return;
    }

    final closingDay =
        int.tryParse(_closingDayController.text.trim())?.clamp(1, 28) ?? 25;
    final overtime =
        double.tryParse(_overtimeController.text.trim()) ?? 1.25;
    final night = double.tryParse(_nightController.text.trim()) ?? 1.25;
    final holiday =
        double.tryParse(_holidayController.text.trim()) ?? 1.35;
    final transport =
        int.tryParse(_transportController.text.trim()) ?? 0;

    final workplace = Workplace(
      id: widget.workplace?.id ?? _uuid.v4(),
      userId: widget.workplace?.userId ?? 'local-user',
      name: name,
      hourlyWage: wage,
      closingDay: closingDay,
      overtimeMultiplier: overtime,
      nightMultiplier: night,
      holidayMultiplier: holiday,
      transportCost: transport,
      colorHex: _colorOptions[_selectedColorIndex],
      createdAt: widget.workplace?.createdAt ?? DateTime.now(),
    );

    widget.onSave(workplace);
    Navigator.pop(context);
  }
}
