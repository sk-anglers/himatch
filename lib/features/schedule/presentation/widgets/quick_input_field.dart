import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Natural language input widget for quick event creation.
/// Expandable text field at top of calendar view that parses
/// free-form Japanese input into structured schedule data.
class QuickInputField extends ConsumerStatefulWidget {
  final VoidCallback? onFallbackToForm;

  const QuickInputField({super.key, this.onFallbackToForm});

  @override
  ConsumerState<QuickInputField> createState() => _QuickInputFieldState();
}

class _QuickInputFieldState extends ConsumerState<QuickInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  _ParsedEvent? _parsed;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _parsed = null);
      return;
    }
    setState(() {
      _parsed = _parseNaturalLanguage(text);
    });
  }

  /// Simple natural language parser for Japanese schedule input.
  /// In production this would delegate to NaturalLanguageParser from core/utils.
  _ParsedEvent? _parseNaturalLanguage(String input) {
    String? title;
    String? dateStr;
    String? timeRange;
    String? location;
    double confidence = 0.0;
    int matchCount = 0;

    // Extract date patterns
    final datePatterns = <RegExp, String Function(Match)>{
      RegExp(r'今日'): (_) {
        final now = DateTime.now();
        return '${now.month}/${now.day}';
      },
      RegExp(r'明日'): (_) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return '${tomorrow.month}/${tomorrow.day}';
      },
      RegExp(r'明後日'): (_) {
        final day = DateTime.now().add(const Duration(days: 2));
        return '${day.month}/${day.day}';
      },
      RegExp(r'来週(月|火|水|木|金|土|日)曜?日?'): (m) {
        final weekdays = {'月': 1, '火': 2, '水': 3, '木': 4, '金': 5, '土': 6, '日': 7};
        final targetDay = weekdays[m.group(1)] ?? 1;
        final now = DateTime.now();
        final daysUntilTarget = ((targetDay - now.weekday) + 7) % 7 + 7;
        final target = now.add(Duration(days: daysUntilTarget));
        return '${target.month}/${target.day}';
      },
      RegExp(r'(\d{1,2})[/月](\d{1,2})日?'): (m) {
        return '${m.group(1)}/${m.group(2)}';
      },
    };

    var remaining = input;
    for (final entry in datePatterns.entries) {
      final match = entry.key.firstMatch(remaining);
      if (match != null) {
        dateStr = entry.value(match);
        remaining = remaining.replaceFirst(match.group(0)!, '').trim();
        matchCount++;
        break;
      }
    }

    // Extract time patterns
    final timeRegex = RegExp(r'(\d{1,2})[時:](\d{0,2})分?(?:から|〜|~|-)?(\d{1,2})?[時:]?(\d{0,2})分?');
    final timeMatch = timeRegex.firstMatch(remaining);
    if (timeMatch != null) {
      final startHour = timeMatch.group(1) ?? '';
      final startMin = timeMatch.group(2)?.isNotEmpty == true ? timeMatch.group(2) : '00';
      final endHour = timeMatch.group(3);
      if (endHour != null) {
        final endMin = timeMatch.group(4)?.isNotEmpty == true ? timeMatch.group(4) : '00';
        timeRange = '$startHour:$startMin - $endHour:$endMin';
      } else {
        timeRange = '$startHour:$startMin -';
      }
      remaining = remaining.replaceFirst(timeMatch.group(0)!, '').trim();
      matchCount++;
    }

    // Extract location patterns
    final locationRegex = RegExp(r'(?:場所[：:]?\s*|@|＠)(.+?)(?:\s|$)');
    final locationMatch = locationRegex.firstMatch(remaining);
    if (locationMatch != null) {
      location = locationMatch.group(1)?.trim();
      remaining = remaining.replaceFirst(locationMatch.group(0)!, '').trim();
      matchCount++;
    }

    // Remaining text is the title
    // Remove common particles
    remaining = remaining
        .replaceAll(RegExp(r'^[にでをはがのとから]+'), '')
        .replaceAll(RegExp(r'[にでをはがのとから]+$'), '')
        .trim();
    if (remaining.isNotEmpty) {
      title = remaining;
      matchCount++;
    }

    // Calculate confidence
    if (matchCount == 0) return null;
    confidence = (matchCount / 4.0).clamp(0.1, 1.0);
    if (dateStr != null && title != null) confidence = (confidence + 0.2).clamp(0.0, 1.0);
    if (timeRange != null) confidence = (confidence + 0.1).clamp(0.0, 1.0);

    return _ParsedEvent(
      title: title,
      date: dateStr,
      timeRange: timeRange,
      location: location,
      confidence: confidence,
    );
  }

  void _onSubmit() {
    if (_parsed == null || _parsed!.confidence < 0.3) {
      // Parse failed or low confidence → fallback to full form
      widget.onFallbackToForm?.call();
      return;
    }

    // TODO: Create schedule from parsed data via provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('予定を作成しました: ${_parsed!.title ?? "無題"}'),
        backgroundColor: AppColors.success,
      ),
    );

    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _parsed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceVariant,
            width: 1,
          ),
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '予定を入力... (例: 来週金曜18時から飲み会)',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _focusNode.unfocus();
                        setState(() {
                          _isExpanded = false;
                          _parsed = null;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSubmit(),
          ),

          // Live preview
          if (_isExpanded && _parsed != null) ...[
            const SizedBox(height: 8),
            _ParsePreview(
              parsed: _parsed!,
              onSubmit: _onSubmit,
              onFallback: widget.onFallbackToForm,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Parse result model ──

class _ParsedEvent {
  final String? title;
  final String? date;
  final String? timeRange;
  final String? location;
  final double confidence;

  const _ParsedEvent({
    this.title,
    this.date,
    this.timeRange,
    this.location,
    required this.confidence,
  });
}

// ── Preview widget ──

class _ParsePreview extends StatelessWidget {
  final _ParsedEvent parsed;
  final VoidCallback onSubmit;
  final VoidCallback? onFallback;

  const _ParsePreview({
    required this.parsed,
    required this.onSubmit,
    this.onFallback,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceColor = parsed.confidence >= 0.7
        ? AppColors.success
        : parsed.confidence >= 0.4
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confidenceColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence indicator
          Row(
            children: [
              Icon(
                parsed.confidence >= 0.7
                    ? Icons.check_circle
                    : parsed.confidence >= 0.4
                        ? Icons.info
                        : Icons.warning,
                size: 14,
                color: confidenceColor,
              ),
              const SizedBox(width: 4),
              Text(
                parsed.confidence >= 0.7
                    ? '解析成功'
                    : parsed.confidence >= 0.4
                        ? '一部解析'
                        : '解析に自信がありません',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: confidenceColor,
                ),
              ),
              const Spacer(),
              // Confidence dots
              Row(
                children: List.generate(5, (i) {
                  final filled = i < (parsed.confidence * 5).round();
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? confidenceColor
                          : confidenceColor.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Parsed fields
          if (parsed.title != null)
            _ParsedField(
              icon: Icons.title,
              label: 'タイトル',
              value: parsed.title!,
            ),
          if (parsed.date != null)
            _ParsedField(
              icon: Icons.calendar_today,
              label: '日付',
              value: parsed.date!,
            ),
          if (parsed.timeRange != null)
            _ParsedField(
              icon: Icons.access_time,
              label: '時間',
              value: parsed.timeRange!,
            ),
          if (parsed.location != null)
            _ParsedField(
              icon: Icons.location_on_outlined,
              label: '場所',
              value: parsed.location!,
            ),

          const SizedBox(height: 8),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFallback,
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('詳細入力'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                    side: const BorderSide(color: AppColors.textHint),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: parsed.confidence >= 0.3 ? onSubmit : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParsedField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ParsedField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
