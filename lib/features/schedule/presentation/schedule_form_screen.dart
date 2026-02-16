import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Schedule? schedule;

  const ScheduleFormScreen({
    super.key,
    required this.initialDate,
    this.schedule,
  });

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  late final TextEditingController _titleController;
  late ScheduleType _selectedType;
  late DateTime _startTime;
  late DateTime _endTime;
  late bool _isAllDay;
  final _memoController = TextEditingController();

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _titleController = TextEditingController(text: s?.title ?? '');
    _selectedType = s?.scheduleType ?? ScheduleType.free;
    _isAllDay = s?.isAllDay ?? false;

    if (s != null) {
      _startTime = s.startTime;
      _endTime = s.endTime;
      _memoController.text = s.memo ?? '';
    } else {
      final date = widget.initialDate;
      _startTime = DateTime(date.year, date.month, date.day, 9, 0);
      _endTime = DateTime(date.year, date.month, date.day, 17, 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '予定を編集' : '予定を追加'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule type selector
            const Text('種別', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _TypeSelector(
              selected: _selectedType,
              onChanged: (type) {
                setState(() {
                  _selectedType = type;
                  if (_titleController.text.isEmpty) {
                    _titleController.text = _defaultTitle(type);
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: '例: 早番、デート、空き',
              ),
            ),
            const SizedBox(height: 20),

            // All day toggle
            SwitchListTile(
              title: const Text('終日'),
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
            ),

            // Date & time pickers
            const Text('日時', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _DateTimePicker(
              label: '開始',
              dateTime: _startTime,
              showTime: !_isAllDay,
              onChanged: (dt) {
                setState(() {
                  _startTime = dt;
                  if (_endTime.isBefore(_startTime)) {
                    _endTime = _startTime.add(const Duration(hours: 1));
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            _DateTimePicker(
              label: '終了',
              dateTime: _endTime,
              showTime: !_isAllDay,
              onChanged: (dt) => setState(() => _endTime = dt),
            ),
            const SizedBox(height: 20),

            // Memo
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                hintText: '備考があれば入力',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  String _defaultTitle(ScheduleType type) {
    return switch (type) {
      ScheduleType.shift => 'シフト',
      ScheduleType.event => '予定',
      ScheduleType.free => '空き',
      ScheduleType.blocked => '予定あり',
    };
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final startTime = _isAllDay
        ? DateTime(_startTime.year, _startTime.month, _startTime.day)
        : _startTime;
    final endTime = _isAllDay
        ? DateTime(_startTime.year, _startTime.month, _startTime.day, 23, 59)
        : _endTime;

    if (!endTime.isAfter(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('終了時刻は開始時刻より後にしてください')),
      );
      return;
    }

    final notifier = ref.read(localSchedulesProvider.notifier);

    if (_isEditing) {
      notifier.updateSchedule(
        widget.schedule!.copyWith(
          title: title,
          scheduleType: _selectedType,
          startTime: startTime,
          endTime: endTime,
          isAllDay: _isAllDay,
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
        ),
      );
    } else {
      notifier.addSchedule(
        title: title,
        scheduleType: _selectedType,
        startTime: startTime,
        endTime: endTime,
        isAllDay: _isAllDay,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      );
    }

    Navigator.of(context).pop();
  }
}

class _TypeSelector extends StatelessWidget {
  final ScheduleType selected;
  final ValueChanged<ScheduleType> onChanged;

  const _TypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ScheduleType.values.map((type) {
        final isSelected = type == selected;
        final (label, color) = switch (type) {
          ScheduleType.shift => ('シフト', AppColors.primary),
          ScheduleType.event => ('予定', AppColors.warning),
          ScheduleType.free => ('空き', AppColors.success),
          ScheduleType.blocked => ('不可', AppColors.error),
        };

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
              selectedColor: color.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? color : AppColors.textHint,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final bool showTime;
  final ValueChanged<DateTime> onChanged;

  const _DateTimePicker({
    required this.label,
    required this.dateTime,
    required this.showTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: dateTime,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
                locale: const Locale('ja'),
              );
              if (date != null) {
                onChanged(DateTime(
                  date.year,
                  date.month,
                  date.day,
                  dateTime.hour,
                  dateTime.minute,
                ));
              }
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(AppDateUtils.formatDate(dateTime)),
          ),
        ),
        if (showTime) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(dateTime),
                );
                if (time != null) {
                  onChanged(DateTime(
                    dateTime.year,
                    dateTime.month,
                    dateTime.day,
                    time.hour,
                    time.minute,
                  ));
                }
              },
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(AppDateUtils.formatTime(dateTime)),
            ),
          ),
        ],
      ],
    );
  }
}
