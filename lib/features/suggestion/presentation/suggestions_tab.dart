import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/core/utils/date_utils.dart';
import 'package:himatch/core/widgets/empty_state_widget.dart';
import 'package:himatch/models/group.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/models/vote.dart';
import 'package:himatch/features/schedule/presentation/widgets/base_calendar_cell.dart';
import 'package:himatch/features/suggestion/presentation/providers/suggestion_providers.dart';
import 'package:himatch/features/suggestion/presentation/providers/vote_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';
import 'package:himatch/providers/holiday_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:himatch/features/chat/presentation/providers/chat_providers.dart';
import 'package:himatch/features/group/presentation/providers/poll_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:himatch/routing/app_routes.dart';

class SuggestionsTab extends ConsumerStatefulWidget {
  const SuggestionsTab({super.key});

  @override
  ConsumerState<SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends ConsumerState<SuggestionsTab> {
  /// null = 全グループ表示
  String? _selectedGroupId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefreshIfNeeded();
    });
  }

  Future<void> _autoRefreshIfNeeded() async {
    final groups = ref.read(localGroupsProvider);
    final suggestions = ref.read(localSuggestionsProvider);
    if (groups.isNotEmpty && suggestions.isEmpty) {
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await ref.read(localSuggestionsProvider.notifier).refreshSuggestions();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSuggestions = ref.watch(localSuggestionsProvider);
    final groups = ref.watch(localGroupsProvider);

    // 選択グループでフィルタ
    final suggestions = _selectedGroupId == null
        ? allSuggestions
        : allSuggestions
            .where((s) => s.groupId == _selectedGroupId)
            .toList();

    return Scaffold(
      body: groups.isEmpty
          ? _NoGroupState()
          : Column(
              children: [
                // グループ切り替えチップ
                _GroupSelector(
                  groups: groups,
                  selectedGroupId: _selectedGroupId,
                  onSelected: (id) =>
                      setState(() => _selectedGroupId = id),
                ),
                // メインコンテンツ
                Expanded(
                  child: _isLoading
                      ? const _LoadingState()
                      : suggestions.isEmpty
                          ? const _EmptySuggestionState()
                          : _SuggestionCalendar(suggestions: suggestions),
                ),
              ],
            ),
      floatingActionButton: groups.isNotEmpty && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: () async {
                await _refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('候補日を更新しました')),
                  );
                }
              },
              backgroundColor: Theme.of(context).extension<AppColorsExtension>()!.primary,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label:
                  const Text('更新', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

// ─── Group selector chips ───

class _GroupSelector extends StatelessWidget {
  final List<Group> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onSelected;

  const _GroupSelector({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _buildChip(
            label: 'すべて',
            isSelected: selectedGroupId == null,
            onTap: () => onSelected(null),
          ),
          ...groups.map((g) => _buildGroupChip(
                group: g,
                isSelected: selectedGroupId == g.id,
                onTap: () => onSelected(g.id),
              )),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupChip({
    required Group group,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = groupColor(group);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            group.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty states ───

class _NoGroupState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.group_add_outlined,
      title: 'グループに参加しましょう',
      subtitle: 'グループタブでグループを作成または\n招待コードで参加すると候補日が表示されます',
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('候補日を検索中...',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text(
              '天気予報と空き時間を分析しています',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySuggestionState extends StatelessWidget {
  const _EmptySuggestionState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.lightbulb_outline,
      title: '候補日がありません',
      subtitle: 'メンバーの空き時間が見つかりませんでした\n右下の「更新」ボタンで再検索できます',
    );
  }
}

// ─── Calendar-based suggestion view ───

class _SuggestionCalendar extends ConsumerStatefulWidget {
  final List<Suggestion> suggestions;
  const _SuggestionCalendar({required this.suggestions});

  @override
  ConsumerState<_SuggestionCalendar> createState() =>
      _SuggestionCalendarState();
}

class _SuggestionCalendarState extends ConsumerState<_SuggestionCalendar> {
  DateTime _focusedDay = DateTime.now();

  /// 日付 → その日の候補リスト
  Map<DateTime, List<Suggestion>> get _grouped {
    final map = <DateTime, List<Suggestion>>{};
    for (final s in widget.suggestions) {
      final key = DateTime(s.suggestedDate.year, s.suggestedDate.month,
          s.suggestedDate.day);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final confirmedCount = widget.suggestions
        .where((s) => s.status == SuggestionStatus.confirmed)
        .length;
    final dateCount = grouped.keys.length;

    return Column(
      children: [
        // ヘッダー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '$dateCount日の候補',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  context.pushNamed(AppRoute.publicVote.name);
                },
                icon: const Icon(Icons.how_to_vote_outlined, size: 20),
                tooltip: '公開投票',
                color: AppColors.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (confirmedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$confirmedCount件確定',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),

        // カレンダー
        TableCalendar<Suggestion>(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          locale: 'ja_JP',
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          rowHeight: 64,
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return grouped[key] ?? [];
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final key = DateTime(day.year, day.month, day.day);
              final events = grouped[key] ?? [];
              return _SuggestionCalendarCell(
                day: day,
                events: events,
                isToday: false,
                isSelected: false,
                holidayName: ref.watch(holidayForDateProvider(key)),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final key = DateTime(day.year, day.month, day.day);
              final events = grouped[key] ?? [];
              return _SuggestionCalendarCell(
                day: day,
                events: events,
                isToday: true,
                isSelected: false,
                holidayName: ref.watch(holidayForDateProvider(key)),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              final key = DateTime(day.year, day.month, day.day);
              final events = grouped[key] ?? [];
              return _SuggestionCalendarCell(
                day: day,
                events: events,
                isToday: false,
                isSelected: true,
                holidayName: ref.watch(holidayForDateProvider(key)),
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return _SuggestionCalendarCell(
                day: day,
                events: const [],
                isToday: false,
                isSelected: false,
                isOutside: true,
              );
            },
            markerBuilder: (context, day, events) => const SizedBox.shrink(),
          ),
          calendarStyle: const CalendarStyle(
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
            markersMaxCount: 0,
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() => _focusedDay = focusedDay);
            final key = DateTime(
                selectedDay.year, selectedDay.month, selectedDay.day);
            final daySuggestions = grouped[key];
            if (daySuggestions != null && daySuggestions.isNotEmpty) {
              _showDayDetail(context, selectedDay, daySuggestions);
            }
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
          },
        ),

        const SizedBox(height: 8),

        // 凡例
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.success, label: 'おすすめ/確定'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.warning, label: 'まあまあ'),
              const SizedBox(width: 16),
              _LegendItem(
                  color: AppColors.textSecondary, label: '候補あり'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ヒントテキスト
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'マーカーのある日付をタップして詳細を確認',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ),

        const Spacer(),
      ],
    );
  }

  void _showDayDetail(
    BuildContext context,
    DateTime day,
    List<Suggestion> suggestions,
  ) {
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(
        day: day,
        suggestions: suggestions,
        isWeekend: isWeekend,
      ),
    );
  }
}

// ─── Custom calendar cell with border + weather ───

class _SuggestionCalendarCell extends StatelessWidget {
  final DateTime day;
  final List<Suggestion> events;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  final String? holidayName;

  const _SuggestionCalendarCell({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    this.isOutside = false,
    this.holidayName,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvents = events.isNotEmpty;
    final weatherIcon = hasEvents
        ? events
            .map((s) => s.weatherSummary?.icon)
            .firstWhere((i) => i != null, orElse: () => null)
        : null;
    final hasConfirmed =
        events.any((s) => s.status == SuggestionStatus.confirmed);
    final bestScore = events.fold<double>(
        0, (max, s) => s.score > max ? s.score : max);
    final badgeColor = hasConfirmed
        ? AppColors.success
        : bestScore >= 0.7
            ? AppColors.success
            : bestScore >= 0.4
                ? AppColors.warning
                : AppColors.textSecondary;

    return BaseCalendarCell(
      day: day,
      isToday: isToday,
      isSelected: isSelected,
      isOutside: isOutside,
      holidayName: holidayName,
      middleContent: weatherIcon != null
          ? Text(weatherIcon,
              style: const TextStyle(fontSize: 12, height: 1.2))
          : null,
      bottomContent: hasEvents
          ? Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: hasConfirmed
                  ? const Icon(Icons.check,
                      size: 10, color: Colors.white)
                  : Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )
          : null,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Day detail bottom sheet ───

class _DayDetailSheet extends ConsumerWidget {
  final DateTime day;
  final List<Suggestion> suggestions;
  final bool isWeekend;

  const _DayDetailSheet({
    required this.day,
    required this.suggestions,
    required this.isWeekend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final groups = ref.watch(localGroupsProvider);
    final hasConfirmed =
        suggestions.any((s) => s.status == SuggestionStatus.confirmed);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
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

          // 日付ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasConfirmed
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isWeekend
                            ? AppColors.secondary.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppDateUtils.formatMonthDayWeek(day),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: hasConfirmed
                          ? AppColors.success
                          : isWeekend
                              ? AppColors.secondary
                              : AppColors.primary,
                    ),
                  ),
                ),
                // 天気情報（日付の横に大きく表示）
                if (suggestions.first.weatherSummary != null) ...[
                  const SizedBox(width: 10),
                  _DayWeatherBanner(
                      weather: suggestions.first.weatherSummary!),
                ],
                const Spacer(),
                Text('${suggestions.length}件の候補',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 候補リスト
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = suggestions[index];
                final matchedGroup = groups
                    .where((g) => g.id == s.groupId)
                    .firstOrNull;
                return _SuggestionTile(
                    suggestion: s,
                    groupName: matchedGroup?.name,
                    groupColor: matchedGroup != null
                        ? groupColor(matchedGroup)
                        : null)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (60 * index).ms)
                    .slideX(begin: 0.05, duration: 300.ms, delay: (60 * index).ms);
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─── Suggestion tile in bottom sheet ───

class _SuggestionTile extends ConsumerWidget {
  final Suggestion suggestion;
  final String? groupName;
  final Color? groupColor;

  const _SuggestionTile({
    required this.suggestion,
    this.groupName,
    this.groupColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.userId ?? AppConstants.localUserId;
    final membersMap = ref.watch(localGroupMembersProvider);
    final groupMembers = membersMap[suggestion.groupId] ?? [];
    final isOwner =
        groupMembers.any((m) => m.userId == currentUserId && m.role == 'owner');
    final isProposed = suggestion.status == SuggestionStatus.proposed;
    final isConfirmed = suggestion.status == SuggestionStatus.confirmed;

    final allVotes = ref.watch(localVotesProvider);
    final suggestionVotes = allVotes[suggestion.id] ?? [];
    final voteSummary = VoteSummary(
      okCount:
          suggestionVotes.where((v) => v.voteType == VoteType.ok).length,
      maybeCount:
          suggestionVotes.where((v) => v.voteType == VoteType.maybe).length,
      ngCount:
          suggestionVotes.where((v) => v.voteType == VoteType.ng).length,
      votes: suggestionVotes,
    );
    final myVote = suggestionVotes
        .where((v) => v.userId == currentUserId)
        .firstOrNull
        ?.voteType;

    final scoreColor = suggestion.score >= 0.7
        ? AppColors.success
        : suggestion.score >= 0.4
            ? AppColors.warning
            : AppColors.textSecondary;

    final gColor = groupColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gColor != null
            ? gColor.withValues(alpha: 0.14)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConfirmed
              ? AppColors.success
              : gColor?.withValues(alpha: 0.4) ??
                  Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.3),
          width: isConfirmed ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // グループ + アクティビティ + 天気 + スコア
          Row(
            children: [
              if (groupName != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gColor?.withValues(alpha: 0.25) ??
                        AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(groupName!,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: gColor ?? AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
              ],
              Icon(_getActivityIcon(suggestion.activityType),
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(suggestion.activityType,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Weather info
              if (suggestion.weatherSummary != null) ...[
                _WeatherChip(weather: suggestion.weatherSummary!),
                const SizedBox(width: 6),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: scoreColor),
                    const SizedBox(width: 2),
                    Text('${(suggestion.score * 100).round()}%',
                        style: TextStyle(
                            color: scoreColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 時間 + 参加人数
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text(
                '${AppDateUtils.formatTime(suggestion.startTime)}-${AppDateUtils.formatTime(suggestion.endTime)}'
                ' (${suggestion.durationHours.toStringAsFixed(1)}h)',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text(
                '${suggestion.availableMembers.length}/${suggestion.totalMembers}人',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 参加率バー
          _MiniAvailabilityBar(ratio: suggestion.availabilityRatio),

          // 投票サマリー
          if (voteSummary.hasVotes) ...[
            const SizedBox(height: 8),
            _CompactVoteSummary(summary: voteSummary),
          ],

          // 投票ボタン
          if (isProposed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _CompactVoteButton(
                  icon: Icons.circle_outlined,
                  label: 'OK',
                  color: AppColors.success,
                  isSelected: myVote == VoteType.ok,
                  onPressed: () => _castVote(
                      ref, VoteType.ok, currentUserId, authState.displayName),
                ),
                const SizedBox(width: 6),
                _CompactVoteButton(
                  icon: Icons.change_history,
                  label: '微妙',
                  color: AppColors.warning,
                  isSelected: myVote == VoteType.maybe,
                  onPressed: () => _castVote(ref, VoteType.maybe,
                      currentUserId, authState.displayName),
                ),
                const SizedBox(width: 6),
                _CompactVoteButton(
                  icon: Icons.close,
                  label: 'NG',
                  color: AppColors.error,
                  isSelected: myVote == VoteType.ng,
                  onPressed: () => _castVote(
                      ref, VoteType.ng, currentUserId, authState.displayName),
                ),
                if (isOwner && voteSummary.hasVotes) ...[
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmSuggestion(context, ref);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('決定',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],

          // お誘いボタン
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sendInvite(context, ref),
              icon: const Icon(Icons.send, size: 14),
              label: const Text('お誘いを送る'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // 確定表示
          if (isConfirmed) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text('予定確定！',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  context.pushNamed(
                    AppRoute.shareCard.name,
                    extra: {
                      'date': AppDateUtils.formatMonthDayWeek(
                          suggestion.suggestedDate),
                      'activity': suggestion.activityType,
                      'groupName': groupName,
                      'weatherIcon': suggestion.weatherSummary?.icon,
                      'weatherCondition': suggestion.weatherSummary?.condition,
                    },
                  );
                },
                icon: const Icon(Icons.share, size: 14),
                label: const Text('シェアカードを作成'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _castVote(WidgetRef ref, VoteType voteType, String userId,
      String? displayName) {
    ref.read(localVotesProvider.notifier).castVote(
          suggestionId: suggestion.id,
          userId: userId,
          voteType: voteType,
          displayName: displayName,
        );
  }

  void _sendInvite(BuildContext context, WidgetRef ref) {
    final date = AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate);
    final time =
        '${AppDateUtils.formatTime(suggestion.startTime)}-${AppDateUtils.formatTime(suggestion.endTime)}';
    final weather = suggestion.weatherSummary;
    final weatherLine = weather != null
        ? '${weather.icon ?? ''} ${weather.condition}'
            '${weather.tempHigh != null ? ' ${weather.tempHigh!.round()}°/${weather.tempLow!.round()}°' : ''}'
        : null;

    final messageText = [
      '一緒に遊ぼう！',
      '',
      date,
      suggestion.activityType,
      time,
      ?weatherLine,
      ?groupName,
      '',
      'Himatchで予定を確認してね！',
    ].join('\n');

    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InviteDestinationSheet(
        date: date,
        activityType: suggestion.activityType,
      ),
    ).then((destination) {
      if (destination == null || !context.mounted) return;
      switch (destination) {
        case 'chat':
          final authState = ref.read(authNotifierProvider);
          ref.read(chatMessagesProvider.notifier).sendMessage(
                groupId: suggestion.groupId,
                content: messageText,
                userId: authState.userId ?? AppConstants.localUserId,
                displayName: authState.displayName ?? 'You',
                relatedSuggestionId: suggestion.id,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('チャットにお誘いを送信しました'),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        case 'poll':
          final authState = ref.read(authNotifierProvider);
          ref.read(localPollsProvider.notifier).createPoll(
                groupId: suggestion.groupId,
                createdBy: authState.userId ?? AppConstants.localUserId,
                creatorName: authState.displayName ?? 'You',
                question: '$date ${suggestion.activityType}に参加できる？',
                options: ['参加OK', '微妙…', '不参加'],
                deadline:
                    suggestion.suggestedDate.subtract(const Duration(days: 1)),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('アンケートを作成しました'),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        case 'share':
          SharePlus.instance.share(ShareParams(text: messageText));
      }
    });
  }

  void _confirmSuggestion(BuildContext context, WidgetRef ref) {
    ref
        .read(localSuggestionsProvider.notifier)
        .confirmSuggestion(suggestion.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppDateUtils.formatMonthDayWeek(suggestion.suggestedDate)}の'
          '${suggestion.activityType}を確定しました！',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    return switch (activityType) {
      'ランチ' => Icons.restaurant,
      '飲み会' || 'ディナー' => Icons.local_bar,
      'カフェ' => Icons.coffee,
      '日帰り旅行' => Icons.directions_car,
      'お出かけ' || '遊び' => Icons.celebration,
      'カラオケ' => Icons.mic,
      '映画' => Icons.movie,
      'BBQ' => Icons.outdoor_grill,
      _ => Icons.event,
    };
  }
}

// ─── Weather banner for day detail header ───

class _DayWeatherBanner extends StatelessWidget {
  final WeatherSummary weather;
  const _DayWeatherBanner({required this.weather});

  @override
  Widget build(BuildContext context) {
    final hasTemp = weather.tempHigh != null && weather.tempLow != null;
    final isRainy = weather.condition.contains('雨') ||
        weather.condition.contains('雪') ||
        weather.condition.contains('雷');
    final bgColor = isRainy
        ? AppColors.weatherRainy.withValues(alpha: 0.10)
        : AppColors.weatherSunny.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weather.icon ?? '', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(weather.condition,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              if (hasTemp)
                Text(
                  '${weather.tempHigh!.round()}° / ${weather.tempLow!.round()}°',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Weather chip widget ───

class _WeatherChip extends StatelessWidget {
  final WeatherSummary weather;
  const _WeatherChip({required this.weather});

  @override
  Widget build(BuildContext context) {
    final tempText = weather.tempHigh != null && weather.tempLow != null
        ? '${weather.tempHigh!.round()}°/${weather.tempLow!.round()}°'
        : '';
    final isRainy = weather.condition.contains('雨') ||
        weather.condition.contains('雪') ||
        weather.condition.contains('雷');
    final bgColor = isRainy
        ? AppColors.weatherRainy.withValues(alpha: 0.12)
        : AppColors.weatherSunny.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weather.icon ?? '', style: const TextStyle(fontSize: 12)),
          if (tempText.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(tempText,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ─── Compact helper widgets ───

class _MiniAvailabilityBar extends StatelessWidget {
  final double ratio;
  const _MiniAvailabilityBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final color = ratio >= 0.8
        ? AppColors.success
        : ratio >= 0.5
            ? AppColors.warning
            : AppColors.error;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.surfaceVariant,
              color: color,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('${(ratio * 100).round()}%',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _CompactVoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _CompactVoteButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? color : Colors.white;
    final fg = isSelected ? Colors.white : color;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                )),
          ],
        ),
      ),
    );
  }
}

class _CompactVoteSummary extends StatelessWidget {
  final VoteSummary summary;
  const _CompactVoteSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.how_to_vote, size: 12, color: AppColors.textHint),
        const SizedBox(width: 4),
        _VoteDot(count: summary.okCount, color: AppColors.success),
        const SizedBox(width: 4),
        _VoteDot(count: summary.maybeCount, color: AppColors.warning),
        const SizedBox(width: 4),
        _VoteDot(count: summary.ngCount, color: AppColors.error),
      ],
    );
  }
}

class _VoteDot extends StatelessWidget {
  final int count;
  final Color color;
  const _VoteDot({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$count',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// ─── Invite destination picker ───

class _InviteDestinationSheet extends StatelessWidget {
  final String date;
  final String activityType;

  const _InviteDestinationSheet({
    required this.date,
    required this.activityType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'お誘いを送る',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$date  $activityType',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // チャットに送る
          _DestinationTile(
            icon: Icons.chat_bubble_outline,
            iconColor: AppColors.primary,
            title: 'チャットに送る',
            subtitle: 'グループチャットにお誘いを投稿',
            onTap: () => Navigator.pop(context, 'chat'),
          ),
          const Divider(height: 1, indent: 56),

          // アンケートを作る
          _DestinationTile(
            icon: Icons.poll_outlined,
            iconColor: AppColors.warning,
            title: 'アンケートを作る',
            subtitle: '「参加できる？」の投票を作成',
            onTap: () => Navigator.pop(context, 'poll'),
          ),
          const Divider(height: 1, indent: 56),

          // LINEなどで共有
          _DestinationTile(
            icon: Icons.share_outlined,
            iconColor: AppColors.success,
            title: 'LINEなどで共有',
            subtitle: '外部アプリでお誘いメッセージを送信',
            onTap: () => Navigator.pop(context, 'share'),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing:
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
