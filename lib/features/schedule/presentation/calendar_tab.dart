import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/models/schedule.dart';
import 'package:himatch/models/shift_type.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/routing/app_routes.dart';
import 'package:himatch/features/schedule/presentation/providers/calendar_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/shift_type_providers.dart';
import 'package:himatch/features/schedule/presentation/widgets/base_calendar_cell.dart';
import 'package:himatch/features/schedule/presentation/widgets/shift_badge.dart';
import 'package:himatch/features/schedule/presentation/widgets/shift_type_editor_sheet.dart';
import 'package:himatch/features/suggestion/presentation/providers/weather_providers.dart';
import 'package:himatch/providers/holiday_providers.dart';
import 'package:himatch/features/schedule/presentation/widgets/week_view.dart';
import 'package:himatch/features/schedule/presentation/widgets/day_view.dart';
import 'package:himatch/features/schedule/presentation/widgets/quick_input_field.dart';

enum _CalendarViewMode { calendar, week, day }

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  _CalendarViewMode _viewMode = _CalendarViewMode.calendar;

  /// シフトペイントモード
  bool _showShiftPanel = false;
  ShiftType? _activeShiftType;
  bool get _isShiftInputMode => _activeShiftType != null;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(localSchedulesProvider);
    final shiftTypeMap = ref.watch(shiftTypeMapProvider);
    final selectedDaySchedules = _getSchedulesForDay(_selectedDay, schedules);

    return Scaffold(
      body: Column(
        children: [
          // 表示モード切替
          _buildViewModeToggle(),
          if (_viewMode == _CalendarViewMode.calendar)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // クイック入力フィールド
                    QuickInputField(onFallbackToForm: _openAddForm),
                    // カレンダー（枠線+天気+大きなセル）
          TableCalendar<Schedule>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'ja_JP',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getSchedulesForDay(day, schedules),
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: 64,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final key = DateTime(day.year, day.month, day.day);
                final events = _getSchedulesForDay(day, schedules);
                return _CalendarCell(
                  day: day,
                  isToday: false,
                  isSelected: false,
                  isOutside: false,
                  scheduleCount: events.length,
                  weather: ref.watch(weatherForDateProvider(key)),
                  holidayName: ref.watch(holidayForDateProvider(key)),
                  shiftTypeMap: shiftTypeMap,
                  events: events,
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final key = DateTime(day.year, day.month, day.day);
                final events = _getSchedulesForDay(day, schedules);
                return _CalendarCell(
                  day: day,
                  isToday: true,
                  isSelected: isSameDay(_selectedDay, day),
                  isOutside: false,
                  scheduleCount: events.length,
                  weather: ref.watch(weatherForDateProvider(key)),
                  holidayName: ref.watch(holidayForDateProvider(key)),
                  shiftTypeMap: shiftTypeMap,
                  events: events,
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final key = DateTime(day.year, day.month, day.day);
                final events = _getSchedulesForDay(day, schedules);
                return _CalendarCell(
                  day: day,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: true,
                  isOutside: false,
                  scheduleCount: events.length,
                  weather: ref.watch(weatherForDateProvider(key)),
                  holidayName: ref.watch(holidayForDateProvider(key)),
                  shiftTypeMap: shiftTypeMap,
                  events: events,
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                return _CalendarCell(
                  day: day,
                  isToday: false,
                  isSelected: false,
                  isOutside: true,
                  scheduleCount: 0,
                  weather: null,
                  shiftTypeMap: shiftTypeMap,
                  events: const [],
                );
              },
              markerBuilder: (context, day, events) =>
                  const SizedBox.shrink(),
            ),
            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
              markersMaxCount: 0,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (_isShiftInputMode) {
                // ペイントモード: 即座にシフトを割当
                ref.read(localSchedulesProvider.notifier).addShiftSchedule(
                  date: selectedDay,
                  shiftTypeId: _activeShiftType!.id,
                  title: _activeShiftType!.name,
                  color: _activeShiftType!.colorHex,
                  startTime: _activeShiftType!.startTime,
                  endTime: _activeShiftType!.endTime,
                  isOff: _activeShiftType!.isOff,
                );
              }
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          const SizedBox(height: 8),

          // シフトペイントパネル（FABメニューの「シフト入力」で表示）
          if (_showShiftPanel)
            _ShiftPaintPanel(
              activeShiftType: _activeShiftType,
              onShiftTypeSelected: (st) {
                setState(() {
                  _activeShiftType =
                      _activeShiftType?.id == st.id ? null : st;
                });
              },
              onDone: () => setState(() {
                _activeShiftType = null;
                _showShiftPanel = false;
              }),
              onEditShiftTypes: _openShiftTypeEditor,
            ),

          // 選択日のヘッダー + 予定表示ボタン
          if (_selectedDay != null && !_isShiftInputMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    AppDateUtils.formatMonthDayWeek(_selectedDay!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // 天気表示
                  Builder(builder: (context) {
                    final weather = ref.watch(weatherForDateProvider(
                        DateTime(_selectedDay!.year, _selectedDay!.month,
                            _selectedDay!.day)));
                    if (weather == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${weather.icon ?? ''} ${weather.condition}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                  const Spacer(),
                  // 予定表示ボタン
                  TextButton.icon(
                    onPressed: () => _showScheduleSheet(
                        context, selectedDaySchedules, shiftTypeMap),
                    icon: const Icon(Icons.list, size: 18),
                    label: Text('${selectedDaySchedules.length}件'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

          // 祝日名
          if (_selectedDay != null && !_isShiftInputMode)
            Builder(builder: (context) {
              final holiday = ref.watch(holidayForDateProvider(
                  DateTime(_selectedDay!.year, _selectedDay!.month,
                      _selectedDay!.day)));
              if (holiday == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        holiday,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
                  ],
                ),
              ),
            ),
          if (_viewMode == _CalendarViewMode.week)
            Expanded(child: _buildWeekView(schedules)),
          if (_viewMode == _CalendarViewMode.day)
            Expanded(child: _buildDayView(schedules)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: Theme.of(context).extension<AppColorsExtension>()!.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Schedule> _getSchedulesForDay(DateTime? day, List<Schedule> schedules) {
    if (day == null) return [];
    return schedules.where((s) {
      final scheduleDate = DateTime(
        s.startTime.year,
        s.startTime.month,
        s.startTime.day,
      );
      final targetDate = DateTime(day.year, day.month, day.day);
      return scheduleDate == targetDate;
    }).toList();
  }

  void _showScheduleSheet(
    BuildContext context,
    List<Schedule> schedules,
    Map<String, ShiftType> shiftTypeMap,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleListSheet(
        day: _selectedDay!,
        schedules: schedules,
        shiftTypeMap: shiftTypeMap,
        onEdit: _openEditForm,
        onDelete: _deleteSchedule,
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<AppColorsExtension>()!;
        return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.edit_calendar,
              label: 'シフト入力',
              subtitle: 'ワンタップでシフトを登録',
              onTap: () {
                Navigator.pop(context);
                _showShiftQuickInput(context);
              },
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.add_circle_outline,
              label: '予定を追加',
              subtitle: '時間を指定して予定を作成',
              onTap: () {
                Navigator.pop(context);
                _openAddForm();
              },
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.tune,
              label: 'シフト種類を編集',
              subtitle: 'シフトの種類を追加・変更',
              onTap: () {
                Navigator.pop(context);
                _openShiftTypeEditor();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      );
      },
    );
  }

  void _showShiftQuickInput(BuildContext context) {
    setState(() => _showShiftPanel = true);
  }

  void _openAddForm() {
    context.pushNamed(
      AppRoute.scheduleForm.name,
      extra: {'initialDate': _selectedDay ?? DateTime.now()},
    );
  }

  void _openEditForm(Schedule schedule) {
    context.pushNamed(
      AppRoute.scheduleForm.name,
      extra: {'initialDate': schedule.startTime, 'schedule': schedule},
    );
  }

  void _deleteSchedule(Schedule schedule) {
    ref.read(localSchedulesProvider.notifier).removeSchedule(schedule.id);
  }

  void _openShiftTypeEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShiftTypeEditorSheet(),
    );
  }

  Widget _buildViewModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<_CalendarViewMode>(
        segments: const [
          ButtonSegment(
            value: _CalendarViewMode.calendar,
            icon: Icon(Icons.calendar_month, size: 16),
            label: Text('月'),
          ),
          ButtonSegment(
            value: _CalendarViewMode.week,
            icon: Icon(Icons.view_week, size: 16),
            label: Text('週'),
          ),
          ButtonSegment(
            value: _CalendarViewMode.day,
            icon: Icon(Icons.view_day, size: 16),
            label: Text('日'),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (Set<_CalendarViewMode> newSelection) {
          setState(() => _viewMode = newSelection.first);
        },
      ),
    );
  }

  Widget _buildWeekView(List<Schedule> schedules) {
    final weatherAsync = ref.watch(weatherForecastProvider);
    final weatherData = weatherAsync.value;

    return WeekView(
      selectedDay: _selectedDay ?? DateTime.now(),
      schedules: schedules,
      onDaySelected: (day) {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });
      },
      onTimeSlotTapped: (time) {
        context.pushNamed(
          AppRoute.scheduleForm.name,
          extra: {'initialDate': time},
        );
      },
      weatherData: weatherData,
      holidayService: (date) {
        final key = DateTime(date.year, date.month, date.day);
        return ref.read(holidayForDateProvider(key));
      },
    );
  }

  Widget _buildDayView(List<Schedule> schedules) {
    final day = _selectedDay ?? DateTime.now();
    final daySchedules = _getSchedulesForDay(day, schedules);
    final weather = ref.watch(weatherForDateProvider(
        DateTime(day.year, day.month, day.day)));

    return DayView(
      selectedDay: day,
      schedules: daySchedules,
      onTimeSlotTapped: (time) {
        context.pushNamed(
          AppRoute.scheduleForm.name,
          extra: {'initialDate': time},
        );
      },
      weather: weather,
    );
  }
}

// ─── Custom calendar cell with border + weather ───

class _CalendarCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final int scheduleCount;
  final dynamic weather; // WeatherSummary?
  final String? holidayName;
  final Map<String, ShiftType> shiftTypeMap;
  final List<Schedule> events;

  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isOutside,
    required this.scheduleCount,
    required this.weather,
    this.holidayName,
    required this.shiftTypeMap,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    // シフトマーカーの色を取得
    Color? markerColor;
    String? markerLabel;
    if (events.isNotEmpty) {
      final first = events.first;
      final shiftType = first.shiftTypeId != null
          ? shiftTypeMap[first.shiftTypeId]
          : null;
      if (shiftType != null) {
        markerColor = shiftTypeColor(shiftType);
        markerLabel = shiftType.abbreviation;
      }
    }

    return BaseCalendarCell(
      day: day,
      isToday: isToday,
      isSelected: isSelected,
      isOutside: isOutside,
      holidayName: holidayName,
      middleContent: weather != null
          ? Text(weather.icon ?? '',
              style: const TextStyle(fontSize: 12, height: 1.2))
          : null,
      bottomContent: isOutside
          ? null
          : markerLabel != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: markerColor?.withValues(alpha: 0.2) ??
                        AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    markerLabel.length > 2
                        ? markerLabel.substring(0, 2)
                        : markerLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: markerColor ?? AppColors.textSecondary,
                    ),
                  ),
                )
              : scheduleCount > 0
                  ? Text(
                      '$scheduleCount件',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
    );
  }
}

// ─── Schedule list bottom sheet ───

class _ScheduleListSheet extends StatelessWidget {
  final DateTime day;
  final List<Schedule> schedules;
  final Map<String, ShiftType> shiftTypeMap;
  final void Function(Schedule) onEdit;
  final void Function(Schedule) onDelete;

  const _ScheduleListSheet({
    required this.day,
    required this.schedules,
    required this.shiftTypeMap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
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
              color: colors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  AppDateUtils.formatMonthDayWeek(day),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${schedules.length}件の予定',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 予定リスト
          Flexible(
            child: schedules.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        '予定がありません',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      return _ScheduleCard(
                        schedule: schedules[index],
                        shiftTypeMap: shiftTypeMap,
                        onTap: () {
                          Navigator.pop(context);
                          onEdit(schedules[index]);
                        },
                        onDelete: () {
                          Navigator.pop(context);
                          onDelete(schedules[index]);
                        },
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─── Schedule card ───

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final Map<String, ShiftType> shiftTypeMap;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.shiftTypeMap,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final shiftType = schedule.shiftTypeId != null
        ? shiftTypeMap[schedule.shiftTypeId]
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: shiftType != null
                      ? shiftTypeColor(shiftType)
                      : _getTypeColor(schedule.scheduleType),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (shiftType != null)
                          ShiftBadgeInline(shiftType: shiftType)
                        else
                          _ScheduleTypeBadge(type: schedule.scheduleType),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            schedule.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.isAllDay
                          ? '終日'
                          : '${AppDateUtils.formatTime(schedule.startTime)} - ${AppDateUtils.formatTime(schedule.endTime)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.textHint,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('削除確認'),
                      content: Text('「${schedule.title}」を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete();
                          },
                          child: const Text('削除',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.shift:
        return AppColors.primary;
      case ScheduleType.event:
        return AppColors.warning;
      case ScheduleType.free:
        return AppColors.success;
      case ScheduleType.blocked:
        return AppColors.error;
    }
  }
}

class _ScheduleTypeBadge extends StatelessWidget {
  final ScheduleType type;

  const _ScheduleTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ScheduleType.shift => ('シフト', AppColors.primary),
      ScheduleType.event => ('予定', AppColors.warning),
      ScheduleType.free => ('空き', AppColors.success),
      ScheduleType.blocked => ('不可', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── FAB menu tile ───

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Shift paint panel (inline below calendar) ───

class _ShiftPaintPanel extends ConsumerWidget {
  final ShiftType? activeShiftType;
  final ValueChanged<ShiftType> onShiftTypeSelected;
  final VoidCallback onDone;
  final VoidCallback onEditShiftTypes;

  const _ShiftPaintPanel({
    required this.activeShiftType,
    required this.onShiftTypeSelected,
    required this.onDone,
    required this.onEditShiftTypes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftTypes = ref.watch(shiftTypesProvider);
    final isActive = activeShiftType != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: isActive
            ? shiftTypeColor(activeShiftType!).withValues(alpha: 0.06)
            : AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(
                color: shiftTypeColor(activeShiftType!).withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー行
          Row(
            children: [
              Icon(
                isActive ? Icons.touch_app : Icons.edit_calendar,
                size: 16,
                color: isActive
                    ? shiftTypeColor(activeShiftType!)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                isActive
                    ? '「${activeShiftType!.name}」を入力中 — 日付をタップ'
                    : 'シフト入力',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? shiftTypeColor(activeShiftType!)
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (isActive)
                GestureDetector(
                  onTap: onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '完了',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onEditShiftTypes,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 14, color: AppColors.textHint),
                      SizedBox(width: 2),
                      Text(
                        '編集',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // シフト種別ボタン
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: shiftTypes.map((st) {
              final isSelected = activeShiftType?.id == st.id;
              final color = shiftTypeColor(st);
              return GestureDetector(
                onTap: () => onShiftTypeSelected(st),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? color : color.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    st.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
