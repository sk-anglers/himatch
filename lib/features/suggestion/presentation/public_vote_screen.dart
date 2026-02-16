import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';

/// Screen for managing URL-based public voting.
/// Allows creating a poll with candidate dates, generating a shareable URL
/// with QR code, and viewing live voting results.
class PublicVoteScreen extends ConsumerStatefulWidget {
  const PublicVoteScreen({super.key});

  @override
  ConsumerState<PublicVoteScreen> createState() => _PublicVoteScreenState();
}

class _PublicVoteScreenState extends ConsumerState<PublicVoteScreen> {
  final _titleController = TextEditingController();
  final List<_CandidateDate> _candidates = [];
  String? _generatedUrl;
  bool _isVotingOpen = false;

  // Demo vote results
  final Map<int, _VoteResult> _demoResults = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('公開投票'),
        actions: [
          if (_isVotingOpen)
            TextButton(
              onPressed: _closeVoting,
              child: const Text(
                '投票を締切る',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: _isVotingOpen ? _buildResultsView() : _buildCreateView(),
    );
  }

  // ── Create voting view ──

  Widget _buildCreateView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title input
        _SectionHeader(title: 'イベントタイトル'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: '例: 新年会の日程調整',
            prefixIcon: Icon(Icons.event, color: AppColors.primary),
          ),
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Candidate dates
        _SectionHeader(title: '候補日'),
        const SizedBox(height: 8),
        if (_candidates.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 36,
                        color: AppColors.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    const Text(
                      '候補日を追加してください',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...List.generate(_candidates.length, (i) {
            final candidate = _candidates[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  candidate.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: candidate.timeRange != null
                    ? Text(
                        candidate.timeRange!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      )
                    : null,
                trailing: IconButton(
                  icon:
                      const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: () {
                    setState(() => _candidates.removeAt(i));
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 8),

        // Add candidate button
        OutlinedButton.icon(
          onPressed: _addCandidate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('候補日を追加'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Generate URL button
        ElevatedButton.icon(
          onPressed:
              _titleController.text.trim().isNotEmpty && _candidates.isNotEmpty
                  ? _generateUrl
                  : null,
          icon: const Icon(Icons.link, size: 18),
          label: const Text('URLを生成'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white60,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),

        // Generated URL display
        if (_generatedUrl != null) ...[
          const SizedBox(height: 24),
          _UrlDisplayCard(
            url: _generatedUrl!,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: _generatedUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URLをコピーしました'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            onShare: () {
              // TODO: Use share_plus
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('シェア機能を準備中...')),
              );
            },
          ),
          const SizedBox(height: 16),

          // QR Code placeholder
          _QrCodeCard(url: _generatedUrl!),
          const SizedBox(height: 16),

          // Start voting button
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isVotingOpen = true;
                // Generate demo results
                for (int i = 0; i < _candidates.length; i++) {
                  _demoResults[i] = _VoteResult(
                    okCount: (i + 2) % 5 + 1,
                    maybeCount: (i + 1) % 3,
                    ngCount: i % 2,
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '投票を開始する',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Results view ──

  Widget _buildResultsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.how_to_vote, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '投票受付中',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // URL + share
        if (_generatedUrl != null) ...[
          _UrlDisplayCard(
            url: _generatedUrl!,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: _generatedUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URLをコピーしました'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('シェア機能を準備中...')),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Legend
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _VoteLegend(
                  symbol: '○',
                  label: 'OK',
                  color: AppColors.success,
                ),
                const SizedBox(width: 20),
                _VoteLegend(
                  symbol: '△',
                  label: '微妙',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 20),
                _VoteLegend(
                  symbol: '×',
                  label: 'NG',
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Results list
        _SectionHeader(title: '投票結果'),
        const SizedBox(height: 8),
        ...List.generate(_candidates.length, (i) {
          final candidate = _candidates[i];
          final result = _demoResults[i] ??
              const _VoteResult(okCount: 0, maybeCount: 0, ngCount: 0);

          return _VoteResultRow(
            index: i,
            candidate: candidate,
            result: result,
          );
        }),
        const SizedBox(height: 24),

        // Close voting button
        OutlinedButton(
          onPressed: _closeVoting,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '投票を締切る',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Actions ──

  void _addCandidate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('ja'),
    );

    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );

    if (!mounted) return;

    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[picked.weekday - 1];
    final label = '${picked.month}/${picked.day} ($dayOfWeek)';
    String? timeRange;

    if (time != null) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      timeRange = '$h:$m〜';
    }

    setState(() {
      _candidates.add(_CandidateDate(
        date: picked,
        label: label,
        timeRange: timeRange,
      ));
    });
  }

  void _generateUrl() {
    final slug = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    setState(() {
      _generatedUrl = 'https://himatch.app/vote/$slug';
    });
  }

  void _closeVoting() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('投票を締切りますか？'),
        content: const Text('締め切ると新しい投票はできなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isVotingOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('投票を締め切りました'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('締切る',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── URL display card ──

class _UrlDisplayCard extends StatelessWidget {
  final String url;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _UrlDisplayCard({
    required this.url,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '共有URL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('コピー'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.textHint),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('シェア'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR code placeholder ──

class _QrCodeCard extends StatelessWidget {
  final String url;

  const _QrCodeCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'QRコード',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            // Placeholder QR code (pattern-based representation)
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _QrPlaceholderPainter(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'スキャンして投票',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    const cellSize = 8.0;
    const margin = 16.0;
    final gridSize = ((size.width - margin * 2) / cellSize).floor();

    // Simple deterministic pattern to simulate QR code
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final isFinder = (row < 3 && col < 3) ||
            (row < 3 && col >= gridSize - 3) ||
            (row >= gridSize - 3 && col < 3);
        final isData = ((row * 7 + col * 13 + row * col) % 3 == 0) && !isFinder;
        final isFinderFill = isFinder &&
            !((row == 1 && col == 1) ||
                (row == 1 && col == gridSize - 2) ||
                (row == gridSize - 2 && col == 1));

        if (isFinderFill || isData) {
          canvas.drawRect(
            Rect.fromLTWH(
              margin + col * cellSize,
              margin + row * cellSize,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Vote result row ──

class _VoteResultRow extends StatelessWidget {
  final int index;
  final _CandidateDate candidate;
  final _VoteResult result;

  const _VoteResultRow({
    required this.index,
    required this.candidate,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final total = result.okCount + result.maybeCount + result.ngCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date label
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (candidate.timeRange != null)
                        Text(
                          candidate.timeRange!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$total人回答',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Vote counts
            Row(
              children: [
                _VoteCount(
                  symbol: '○',
                  count: result.okCount,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _VoteCount(
                  symbol: '△',
                  count: result.maybeCount,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                _VoteCount(
                  symbol: '×',
                  count: result.ngCount,
                  color: AppColors.error,
                ),
                const Spacer(),
                // Visual bar
                if (total > 0)
                  SizedBox(
                    width: 100,
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          if (result.okCount > 0)
                            Expanded(
                              flex: result.okCount,
                              child: Container(color: AppColors.success),
                            ),
                          if (result.maybeCount > 0)
                            Expanded(
                              flex: result.maybeCount,
                              child: Container(color: AppColors.warning),
                            ),
                          if (result.ngCount > 0)
                            Expanded(
                              flex: result.ngCount,
                              child: Container(color: AppColors.error),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteCount extends StatelessWidget {
  final String symbol;
  final int count;
  final Color color;

  const _VoteCount({
    required this.symbol,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteLegend extends StatelessWidget {
  final String symbol;
  final String label;
  final Color color;

  const _VoteLegend({
    required this.symbol,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
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

// ── Data models ──

class _CandidateDate {
  final DateTime date;
  final String label;
  final String? timeRange;

  const _CandidateDate({
    required this.date,
    required this.label,
    this.timeRange,
  });
}

class _VoteResult {
  final int okCount;
  final int maybeCount;
  final int ngCount;

  const _VoteResult({
    required this.okCount,
    required this.maybeCount,
    required this.ngCount,
  });
}

// ── Section header ──

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }
}
