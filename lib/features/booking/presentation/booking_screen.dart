import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Booking page management screen.
/// Users can create, manage, and share booking pages
/// for external scheduling with shareable booking pages.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  // Demo booking pages
  final List<_BookingPageData> _pages = [
    _BookingPageData(
      id: '1',
      title: '30分ミーティング',
      description: 'カジュアルな相談・打ち合わせ',
      durationMinutes: 30,
      isActive: true,
      slug: 'meeting-30min',
      availableDays: [1, 2, 3, 4, 5],
      availableStart: '10:00',
      availableEnd: '18:00',
      bufferMinutes: 15,
      maxPerDay: 5,
      bookings: [
        _BookingData(
          name: '田中太郎',
          time: '2/17 (月) 14:00-14:30',
          message: 'プロジェクトについて相談したいです',
          isConfirmed: false,
        ),
        _BookingData(
          name: '佐藤花子',
          time: '2/18 (火) 11:00-11:30',
          message: null,
          isConfirmed: true,
        ),
      ],
    ),
    _BookingPageData(
      id: '2',
      title: 'ランチ',
      description: '気軽にランチしましょう',
      durationMinutes: 60,
      isActive: false,
      slug: 'lunch',
      availableDays: [1, 2, 3, 4, 5],
      availableStart: '11:30',
      availableEnd: '13:30',
      bufferMinutes: 0,
      maxPerDay: 1,
      bookings: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約ページ'),
      ),
      body: _pages.isEmpty ? _buildEmptyState() : _buildPageList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePageSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ページ作成', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            const Text(
              '予約ページがありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '予約ページを作成して\nURLを共有しましょう',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        return _BookingPageCard(
          page: page,
          onToggleActive: () {
            setState(() {
              _pages[index] = page.copyWith(isActive: !page.isActive);
            });
          },
          onShareUrl: () => _shareUrl(page),
          onTap: () => _showBookingDetail(context, page),
        );
      },
    );
  }

  void _shareUrl(_BookingPageData page) {
    final url = 'https://himatch.app/book/${page.slug}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URLをコピーしました: $url'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showBookingDetail(BuildContext context, _BookingPageData page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        page: page,
        onConfirm: (booking) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${booking.name}の予約を確定しました'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        onDecline: (booking) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${booking.name}の予約を辞退しました'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      ),
    );
  }

  void _showCreatePageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateBookingPageSheet(
        onCreated: (page) {
          setState(() {
            _pages.add(page);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予約ページを作成しました'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }
}

// ── Booking page card ──

class _BookingPageCard extends StatelessWidget {
  final _BookingPageData page;
  final VoidCallback onToggleActive;
  final VoidCallback onShareUrl;
  final VoidCallback onTap;

  const _BookingPageCard({
    required this.page,
    required this.onToggleActive,
    required this.onShareUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: page.isActive
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.textHint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      page.isActive ? '公開中' : '非公開',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: page.isActive
                            ? AppColors.success
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
              if (page.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  page.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Duration + pending bookings
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${page.durationMinutes}分',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.event_available,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${page.bookings.length}件の予約',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  // Toggle active
                  _ActionChip(
                    icon: page.isActive ? Icons.pause : Icons.play_arrow,
                    label: page.isActive ? '非公開にする' : '公開する',
                    onTap: onToggleActive,
                  ),
                  const SizedBox(width: 8),
                  // Share URL
                  _ActionChip(
                    icon: Icons.share,
                    label: 'URL共有',
                    color: AppColors.primary,
                    onTap: onShareUrl,
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

// ── Booking detail bottom sheet ──

class _BookingDetailSheet extends StatelessWidget {
  final _BookingPageData page;
  final ValueChanged<_BookingData> onConfirm;
  final ValueChanged<_BookingData> onDecline;

  const _BookingDetailSheet({
    required this.page,
    required this.onConfirm,
    required this.onDecline,
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
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    page.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${page.bookings.length}件',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Bookings list
          if (page.bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox,
                      size: 48,
                      color: AppColors.textHint.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'まだ予約がありません',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: page.bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final booking = page.bookings[index];
                  return _BookingTile(
                    booking: booking,
                    onConfirm: () {
                      Navigator.pop(context);
                      onConfirm(booking);
                    },
                    onDecline: () {
                      Navigator.pop(context);
                      onDecline(booking);
                    },
                  );
                },
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final _BookingData booking;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _BookingTile({
    required this.booking,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: booking.isConfirmed
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppColors.primaryLight.withValues(alpha: 0.3),
                child: Text(
                  booking.name.isNotEmpty ? booking.name[0] : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      booking.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (booking.isConfirmed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '確定',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),

          // Message
          if (booking.message != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.message_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.message!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Confirm / Decline buttons
          if (!booking.isConfirmed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('辞退',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('確定',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Create booking page sheet ──

class _CreateBookingPageSheet extends StatefulWidget {
  final ValueChanged<_BookingPageData> onCreated;

  const _CreateBookingPageSheet({required this.onCreated});

  @override
  State<_CreateBookingPageSheet> createState() =>
      _CreateBookingPageSheetState();
}

class _CreateBookingPageSheetState extends State<_CreateBookingPageSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _durationMinutes = 60;
  final List<int> _availableDays = [1, 2, 3, 4, 5]; // Mon-Fri default
  String _startTime = '09:00';
  String _endTime = '18:00';
  int _bufferMinutes = 15;
  int _maxPerDay = 5;

  static const _durations = [
    (30, '30分'),
    (45, '45分'),
    (60, '60分'),
    (90, '90分'),
  ];

  static const _dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  '予約ページ作成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
              ],
            ),
          ),
          const Divider(),

          // Form
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: '例: 30分ミーティング',
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明 (任意)',
                    hintText: '例: カジュアルな相談・打ち合わせ',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Duration
                const Text(
                  '所要時間',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _durations.map((d) {
                    final isSelected = _durationMinutes == d.$1;
                    return ChoiceChip(
                      label: Text(d.$2),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _durationMinutes = d.$1),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Available days
                const Text(
                  '受付曜日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final dayNum = i + 1; // 1=Mon, 7=Sun
                    final isSelected = _availableDays.contains(dayNum);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _availableDays.remove(dayNum);
                          } else {
                            _availableDays.add(dayNum);
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Available hours
                const Text(
                  '受付時間',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerButton(
                        label: '開始',
                        value: _startTime,
                        onChanged: (v) => setState(() => _startTime = v),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('〜',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: _TimePickerButton(
                        label: '終了',
                        value: _endTime,
                        onChanged: (v) => setState(() => _endTime = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buffer time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'バッファ時間',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _bufferMinutes,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('なし')),
                        DropdownMenuItem(value: 5, child: Text('5分')),
                        DropdownMenuItem(value: 10, child: Text('10分')),
                        DropdownMenuItem(value: 15, child: Text('15分')),
                        DropdownMenuItem(value: 30, child: Text('30分')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _bufferMinutes = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Max bookings per day
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '1日の最大予約数',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _maxPerDay,
                      items: List.generate(10, (i) => i + 1)
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text('$n件'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _maxPerDay = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Create button
                ElevatedButton(
                  onPressed: _onCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '作成する',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCreate() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    final page = _BookingPageData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      durationMinutes: _durationMinutes,
      isActive: true,
      slug: slug.isNotEmpty ? slug : 'booking-${DateTime.now().millisecondsSinceEpoch}',
      availableDays: List.from(_availableDays),
      availableStart: _startTime,
      availableEnd: _endTime,
      bufferMinutes: _bufferMinutes,
      maxPerDay: _maxPerDay,
      bookings: [],
    );

    Navigator.pop(context);
    widget.onCreated(page);
  }
}

// ── Time picker button ──

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimePickerButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onChanged('$h:$m');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action chip ──

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: effectiveColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data models ──

class _BookingPageData {
  final String id;
  final String title;
  final String? description;
  final int durationMinutes;
  final bool isActive;
  final String slug;
  final List<int> availableDays;
  final String availableStart;
  final String availableEnd;
  final int bufferMinutes;
  final int maxPerDay;
  final List<_BookingData> bookings;

  const _BookingPageData({
    required this.id,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.isActive,
    required this.slug,
    required this.availableDays,
    required this.availableStart,
    required this.availableEnd,
    required this.bufferMinutes,
    required this.maxPerDay,
    required this.bookings,
  });

  _BookingPageData copyWith({
    String? id,
    String? title,
    String? description,
    int? durationMinutes,
    bool? isActive,
    String? slug,
    List<int>? availableDays,
    String? availableStart,
    String? availableEnd,
    int? bufferMinutes,
    int? maxPerDay,
    List<_BookingData>? bookings,
  }) {
    return _BookingPageData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      slug: slug ?? this.slug,
      availableDays: availableDays ?? this.availableDays,
      availableStart: availableStart ?? this.availableStart,
      availableEnd: availableEnd ?? this.availableEnd,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      bookings: bookings ?? this.bookings,
    );
  }
}

class _BookingData {
  final String name;
  final String time;
  final String? message;
  final bool isConfirmed;

  const _BookingData({
    required this.name,
    required this.time,
    this.message,
    required this.isConfirmed,
  });
}
