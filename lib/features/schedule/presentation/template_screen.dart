import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/event_template.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/models/schedule.dart';
import 'package:uuid/uuid.dart';

// ─── Provider ───

final eventTemplatesProvider =
    NotifierProvider<EventTemplatesNotifier, List<EventTemplate>>(
  EventTemplatesNotifier.new,
);

class EventTemplatesNotifier extends Notifier<List<EventTemplate>> {
  @override
  List<EventTemplate> build() => [
        const EventTemplate(
          id: 'tmpl-1',
          name: '授業',
          title: '授業',
          defaultStartTime: '09:00',
          defaultEndTime: '10:30',
          iconEmoji: '\u{1F4DA}',
          colorHex: 'FF3498DB',
        ),
        const EventTemplate(
          id: 'tmpl-2',
          name: 'バイト',
          title: 'バイト',
          defaultStartTime: '17:00',
          defaultEndTime: '22:00',
          iconEmoji: '\u{1F4BC}',
          colorHex: 'FFF39C12',
        ),
        const EventTemplate(
          id: 'tmpl-3',
          name: 'ジム',
          title: 'ジム',
          defaultStartTime: '18:00',
          defaultEndTime: '19:30',
          iconEmoji: '\u{1F4AA}',
          colorHex: 'FF00B894',
        ),
        const EventTemplate(
          id: 'tmpl-4',
          name: '友達とごはん',
          title: '友達とごはん',
          defaultStartTime: '12:00',
          defaultEndTime: '13:30',
          iconEmoji: '\u{1F37D}',
          colorHex: 'FFE84393',
        ),
        const EventTemplate(
          id: 'tmpl-5',
          name: 'デート',
          title: 'デート',
          iconEmoji: '\u{2764}',
          colorHex: 'FFE17055',
        ),
        const EventTemplate(
          id: 'tmpl-6',
          name: 'サークル',
          title: 'サークル',
          defaultStartTime: '15:00',
          defaultEndTime: '18:00',
          iconEmoji: '\u{1F3C3}',
          colorHex: 'FF6C5CE7',
        ),
      ];

  void add(EventTemplate template) {
    state = [...state, template];
  }

  void update(EventTemplate updated) {
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

// ─── Screen ───

class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(eventTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('テンプレート')),
      body: templates.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard_customize_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text(
                    'テンプレートがありません',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'よく使う予定をテンプレートに登録しましょう',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                return _TemplateCard(
                  template: templates[index],
                  onTap: () =>
                      _quickCreateSchedule(context, ref, templates[index]),
                  onLongPress: () =>
                      _openEditor(context, ref, template: templates[index]),
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

  void _quickCreateSchedule(
      BuildContext context, WidgetRef ref, EventTemplate template) {
    final now = DateTime.now();
    DateTime startTime;
    DateTime endTime;

    if (template.isAllDay) {
      startTime = DateTime(now.year, now.month, now.day);
      endTime = DateTime(now.year, now.month, now.day, 23, 59);
    } else if (template.defaultStartTime != null &&
        template.defaultEndTime != null) {
      final sp = template.defaultStartTime!.split(':');
      final ep = template.defaultEndTime!.split(':');
      startTime = DateTime(
        now.year, now.month, now.day,
        int.parse(sp[0]), int.parse(sp[1]),
      );
      endTime = DateTime(
        now.year, now.month, now.day,
        int.parse(ep[0]), int.parse(ep[1]),
      );
    } else {
      startTime = DateTime(now.year, now.month, now.day, 9, 0);
      endTime = DateTime(now.year, now.month, now.day, 10, 0);
    }

    ref.read(localSchedulesProvider.notifier).addSchedule(
      title: template.title,
      scheduleType: ScheduleType.event,
      startTime: startTime,
      endTime: endTime,
      isAllDay: template.isAllDay,
      memo: template.memo,
      color: template.colorHex,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${template.title}」を今日の予定に追加しました'),
        action: SnackBarAction(
          label: '取消',
          onPressed: () {
            // Would need the ID to undo; simplified here
          },
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref,
      {EventTemplate? template}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TemplateEditorScreen(
          template: template,
          onSave: (t) {
            if (template != null) {
              ref.read(eventTemplatesProvider.notifier).update(t);
            } else {
              ref.read(eventTemplatesProvider.notifier).add(t);
            }
          },
          onDelete: template != null
              ? () {
                  ref
                      .read(eventTemplatesProvider.notifier)
                      .remove(template.id);
                }
              : null,
        ),
      ),
    );
  }
}

// ─── Template grid card ───

class _TemplateCard extends StatelessWidget {
  final EventTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = template.colorHex != null
        ? Color(int.parse(template.colorHex!, radix: 16))
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji icon
              Text(
                template.iconEmoji ?? '\u{1F4C5}',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Time hint
              if (template.defaultStartTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${template.defaultStartTime}-${template.defaultEndTime ?? ""}',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Template editor screen ───

class _TemplateEditorScreen extends StatefulWidget {
  final EventTemplate? template;
  final ValueChanged<EventTemplate> onSave;
  final VoidCallback? onDelete;

  const _TemplateEditorScreen({
    this.template,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<_TemplateEditorScreen> {
  static const _uuid = Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _titleController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _locationController;
  late final TextEditingController _memoController;
  late bool _isAllDay;
  late String _selectedEmoji;
  late int _selectedColorIndex;

  bool get _isEditing => widget.template != null;

  static const _emojiOptions = [
    '\u{1F4DA}', // books
    '\u{1F4BC}', // briefcase
    '\u{1F4AA}', // muscle
    '\u{1F37D}', // plate
    '\u{2764}',  // heart
    '\u{1F3C3}', // runner
    '\u{1F3B5}', // music
    '\u{1F4C5}', // calendar
    '\u{2708}',  // plane
    '\u{1F3AE}', // game
    '\u{1F4BB}', // laptop
    '\u{1F6CD}', // shopping
    '\u{2615}',  // coffee
    '\u{1F3E5}', // hospital
    '\u{1F697}', // car
    '\u{1F3E0}', // home
  ];

  static const _colorOptions = [
    'FF3498DB', // blue
    'FFE17055', // red
    'FF00B894', // green
    'FFF39C12', // orange
    'FF6C5CE7', // purple
    'FFE84393', // pink
    'FF636E72', // gray
    'FF1ABC9C', // teal
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _titleController = TextEditingController(text: t?.title ?? '');
    _startTimeController =
        TextEditingController(text: t?.defaultStartTime ?? '');
    _endTimeController =
        TextEditingController(text: t?.defaultEndTime ?? '');
    _locationController = TextEditingController(text: t?.location ?? '');
    _memoController = TextEditingController(text: t?.memo ?? '');
    _isAllDay = t?.isAllDay ?? false;
    _selectedEmoji = t?.iconEmoji ?? _emojiOptions[0];
    _selectedColorIndex = 0;
    if (t?.colorHex != null) {
      final idx = _colorOptions.indexOf(t!.colorHex!);
      if (idx >= 0) _selectedColorIndex = idx;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'テンプレートを編集' : '新しいテンプレート'),
        actions: [
          if (_isEditing && widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('削除確認'),
                    content: Text(
                        '「${widget.template!.name}」を削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onDelete!();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('削除',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
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
            // Emoji picker
            const Text('アイコン',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojiOptions.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Color picker
            const Text('カラー',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(_colorOptions.length, (index) {
                final color =
                    Color(int.parse(_colorOptions[index], radix: 16));
                final isSelected = index == _selectedColorIndex;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.textPrimary, width: 3)
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
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'テンプレート名',
                hintText: '例: 授業',
              ),
            ),
            const SizedBox(height: 12),

            // Title (pre-filled schedule title)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '予定タイトル',
                hintText: '例: 3限 情報工学',
              ),
            ),
            const SizedBox(height: 16),

            // All-day toggle
            SwitchListTile(
              title: const Text('終日'),
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
            ),

            // Time fields
            if (!_isAllDay) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: '開始時刻',
                        hintText: '09:00',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: '終了時刻',
                        hintText: '10:30',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '場所（任意）',
                hintText: '例: 3号館 201教室',
                prefixIcon: Icon(Icons.place, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Memo
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                hintText: '備考があれば入力',
                prefixIcon: Icon(Icons.note, size: 20),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレート名を入力してください')),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予定タイトルを入力してください')),
      );
      return;
    }

    final template = EventTemplate(
      id: widget.template?.id ?? _uuid.v4(),
      userId: widget.template?.userId ?? AppConstants.localUserId,
      name: name,
      title: title,
      defaultStartTime:
          _isAllDay ? null : _startTimeController.text.trim().isEmpty ? null : _startTimeController.text.trim(),
      defaultEndTime:
          _isAllDay ? null : _endTimeController.text.trim().isEmpty ? null : _endTimeController.text.trim(),
      isAllDay: _isAllDay,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      iconEmoji: _selectedEmoji,
      colorHex: _colorOptions[_selectedColorIndex],
      createdAt: widget.template?.createdAt ?? DateTime.now(),
    );

    widget.onSave(template);
    Navigator.of(context).pop();
  }
}
