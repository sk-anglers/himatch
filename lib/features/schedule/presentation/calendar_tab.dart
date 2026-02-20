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
import 'package:himatch/features/schedule/presentation/widgets/shift_type_editor_sheet.dart';
import 'package:himatch/features/suggestion/presentation/providers/weather_providers.dart';
import 'package:himatch/providers/holiday_providers.dart';
import 'package:himatch/features/schedule/presentation/providers/month_data_providers.dart';
import 'package:himatch/features/schedule/presentation/widgets/quick_input_field.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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

    // Month-level batch data for calendar cells (avoids per-cell .family providers)
    final monthKey = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final weatherMap = ref.watch(monthWeatherProvider(monthKey));
    final holidayMap = ref.watch(monthHolidayProvider(monthKey));

    return Scaffold(
      body: Column(
        children: [
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
            rowHeight: 72,
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
                  weather: weatherMap[key],
                  holidayName: holidayMap[key],
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
                  weather: weatherMap[key],
                  holidayName: holidayMap[key],
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
                  weather: weatherMap[key],
                  holidayName: holidayMap[key],
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

          // 選択日のヘッダー
          if (_selectedDay != null && !_isShiftInputMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                  // 祝日バッジ
                  Builder(builder: (context) {
                    final holiday = ref.watch(holidayForDateProvider(
                        DateTime(_selectedDay!.year, _selectedDay!.month,
                            _selectedDay!.day)));
                    if (holiday == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        holiday,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // 選択日の予定リスト（インライン表示）
          if (_selectedDay != null && !_isShiftInputMode)
            selectedDaySchedules.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.event_available,
                            size: 16, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text(
                          '予定はありません',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Column(
                      children: selectedDaySchedules.map((schedule) {
                        final shiftType = schedule.shiftTypeId != null
                            ? shiftTypeMap[schedule.shiftTypeId]
                            : null;
                        final color = shiftType != null
                            ? shiftTypeColor(shiftType)
                            : _scheduleTypeColor(schedule.scheduleType);
                        return _InlineScheduleTile(
                          schedule: schedule,
                          color: color,
                          shiftType: shiftType,
                          onTap: () => _openEditForm(schedule),
                          onDelete: () => _deleteSchedule(schedule),
                        );
                      }).toList(),
                    ),
                  ),
                  ],
                ),
              ),
            ),
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

  Color _scheduleTypeColor(ScheduleType type) {
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

// ─── Inline schedule tile (below calendar) ───

class _InlineScheduleTile extends StatelessWidget {
  final Schedule schedule;
  final Color color;
  final ShiftType? shiftType;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InlineScheduleTile({
    required this.schedule,
    required this.color,
    required this.shiftType,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = schedule.isAllDay
        ? '終日'
        : '${AppDateUtils.formatTime(schedule.startTime)} - ${AppDateUtils.formatTime(schedule.endTime)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          child: Row(
            children: [
              // シフトバッジ or タイプバッジ
              if (shiftType != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shiftType!.abbreviation,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _typeLabel(schedule.scheduleType),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              // タイトル + 時間
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 編集矢印
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.shift:
        return 'シフト';
      case ScheduleType.event:
        return '予定';
      case ScheduleType.free:
        return '空き';
      case ScheduleType.blocked:
        return '不可';
    }
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
              style: const TextStyle(fontSize: 13, height: 1.0))
          : null,
      bottomContent: isOutside
          ? null
          : markerLabel != null
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: markerColor ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    markerLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : scheduleCount > 0
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$scheduleCount件',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : null,
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
