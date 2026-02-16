import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';

/// シフト種別の追加/編集/削除/並べ替えを行うボトムシート。
class ShiftTypeEditorSheet extends ConsumerStatefulWidget {
  const ShiftTypeEditorSheet({super.key});

  @override
  ConsumerState<ShiftTypeEditorSheet> createState() =>
      _ShiftTypeEditorSheetState();
}

class _ShiftTypeEditorSheetState extends ConsumerState<ShiftTypeEditorSheet> {
  @override
  Widget build(BuildContext context) {
    final shiftTypes = ref.watch(shiftTypesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'シフト種別の編集',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('リセット'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // リスト（ドラッグ並べ替え可能）
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shiftTypes.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                ref
                    .read(shiftTypesProvider.notifier)
                    .reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final st = shiftTypes[index];
                return _ShiftTypeListTile(
                  key: ValueKey(st.id),
                  shiftType: st,
                  onEdit: () => _showEditDialog(st),
                  onDelete: () => _confirmDelete(st),
                );
              },
            ),
          ),
          // 追加ボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('シフト種別を追加'),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _showShiftTypeFormDialog(null);
  }

  void _showEditDialog(ShiftType shiftType) {
    _showShiftTypeFormDialog(shiftType);
  }

  void _showShiftTypeFormDialog(ShiftType? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _ShiftTypeFormDialog(
        existing: existing,
        onSave: (shiftType) {
          if (existing != null) {
            ref.read(shiftTypesProvider.notifier).update(shiftType);
          } else {
            ref.read(shiftTypesProvider.notifier).add(shiftType);
          }
        },
      ),
    );
  }

  void _confirmDelete(ShiftType st) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${st.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(shiftTypesProvider.notifier).remove(st.id);
            },
            child: const Text('削除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('リセット確認'),
        content: const Text('カスタムシフト種別を削除し、デフォルトに戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(shiftTypesProvider.notifier).resetToDefault();
            },
            child: const Text('リセット',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ShiftTypeListTile extends StatelessWidget {
  final ShiftType shiftType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShiftTypeListTile({
    super.key,
    required this.shiftType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = shiftTypeColor(shiftType);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            shiftType.abbreviation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          shiftType.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          shiftType.startTime != null
              ? '${shiftType.startTime} - ${shiftType.endTime}'
              : shiftType.isOff
                  ? '休み'
                  : '終日',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
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
            const Icon(Icons.drag_handle, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// シフト種別の追加/編集フォームダイアログ。
class _ShiftTypeFormDialog extends StatefulWidget {
  final ShiftType? existing;
  final ValueChanged<ShiftType> onSave;

  const _ShiftTypeFormDialog({
    this.existing,
    required this.onSave,
  });

  @override
  State<_ShiftTypeFormDialog> createState() => _ShiftTypeFormDialogState();
}

class _ShiftTypeFormDialogState extends State<_ShiftTypeFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _abbrController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late bool _isOff;
  late int _selectedColorIndex;

  static const _colorOptions = [
    'FF3498DB', // Blue
    'FF8E44AD', // Purple
    'FFF39C12', // Orange
    'FFFF6B6B', // Red/Pink
    'FF00B894', // Green
    'FFE17055', // Coral
    'FF2C3E50', // Dark Navy
    'FF1ABC9C', // Teal
    'FFE91E63', // Pink
    'FF795548', // Brown
    'FF607D8B', // Blue Grey
    'FF9C27B0', // Deep Purple
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _abbrController = TextEditingController(text: e?.abbreviation ?? '');
    _startController = TextEditingController(text: e?.startTime ?? '');
    _endController = TextEditingController(text: e?.endTime ?? '');
    _isOff = e?.isOff ?? false;
    _selectedColorIndex = e != null
        ? _colorOptions.indexOf(e.colorHex).clamp(0, _colorOptions.length - 1)
        : 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbrController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      title: Text(isEditing ? 'シフト種別を編集' : 'シフト種別を追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名前',
                hintText: '例: 日勤',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _abbrController,
              decoration: const InputDecoration(
                labelText: '略称（1文字）',
                hintText: '例: 日',
              ),
              maxLength: 2,
            ),
            const SizedBox(height: 8),
            // カラーピッカー
            const Text('色', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_colorOptions.length, (i) {
                final color = Color(int.parse(_colorOptions[i], radix: 16));
                final isSelected = i == _selectedColorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // 時間帯
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      labelText: '開始時刻',
                      hintText: '08:30',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                      labelText: '終了時刻',
                      hintText: '17:00',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('休み扱い'),
              subtitle: const Text(
                '提案エンジンで「空き」として扱います',
                style: TextStyle(fontSize: 12),
              ),
              value: _isOff,
              onChanged: (v) => setState(() => _isOff = v),
              contentPadding: EdgeInsets.zero,
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
    final abbr = _abbrController.text.trim();
    if (name.isEmpty || abbr.isEmpty) return;

    final start = _startController.text.trim();
    final end = _endController.text.trim();

    final shiftType = ShiftType(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      abbreviation: abbr,
      colorHex: _colorOptions[_selectedColorIndex],
      startTime: start.isNotEmpty ? start : null,
      endTime: end.isNotEmpty ? end : null,
      isOff: _isOff,
      sortOrder: widget.existing?.sortOrder ?? 99,
      isDefault: false,
    );

    widget.onSave(shiftType);
    Navigator.pop(context);
  }
}
