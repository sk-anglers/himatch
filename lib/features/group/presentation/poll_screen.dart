import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/poll.dart';
import 'package:himatch/features/group/presentation/providers/poll_providers.dart';

/// Poll creation and voting screen for a group.
///
/// Displays a list of polls (active first, closed at bottom).
/// Each poll card shows options with animated vote-count bars.
/// FAB opens a create-poll dialog.
class PollScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const PollScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends ConsumerState<PollScreen> {
  static const _currentUserId = AppConstants.localUserId;
  static const _currentUserName = 'あなた';

  @override
  Widget build(BuildContext context) {
    final allPolls = ref.watch(localPollsProvider);
    final polls = allPolls[widget.groupId] ?? [];

    // Active first, closed at bottom
    final active = polls.where((p) => !p.isClosed).toList();
    final closed = polls.where((p) => p.isClosed).toList();
    final ordered = [...active, ...closed];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} の投票'),
      ),
      body: ordered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.poll_outlined,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '投票がありません',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '右下の + ボタンで投票を作成しましょう',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ordered.length,
              itemBuilder: (context, index) {
                return _PollCard(
                  poll: ordered[index],
                  groupId: widget.groupId,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePollDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    final questionController = TextEditingController();
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    bool isMultiSelect = false;
    bool isAnonymous = false;
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('投票を作成'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: '質問',
                    hintText: '例: 次の集合場所はどこにする？',
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                ...List.generate(optionControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionControllers[i],
                            decoration: InputDecoration(
                              labelText: '選択肢 ${i + 1}',
                              hintText: '選択肢を入力',
                            ),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                optionControllers.removeAt(i);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }),

                // Add option button
                if (optionControllers.length < 10)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('選択肢を追加'),
                  ),

                const Divider(height: 24),

                // Multi-select toggle
                SwitchListTile(
                  title: const Text('複数選択', style: TextStyle(fontSize: 14)),
                  value: isMultiSelect,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setDialogState(() => isMultiSelect = v),
                ),

                // Anonymous toggle
                SwitchListTile(
                  title: const Text('匿名投票', style: TextStyle(fontSize: 14)),
                  value: isAnonymous,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setDialogState(() => isAnonymous = v),
                ),

                // Deadline picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setDialogState(() => deadline = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '締切日',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      deadline != null
                          ? '${deadline!.year}/${deadline!.month}/${deadline!.day}'
                          : '未設定',
                      style: TextStyle(
                        color: deadline != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final question = questionController.text.trim();
                final options = optionControllers
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                if (question.isEmpty || options.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('質問と2つ以上の選択肢が必要です'),
                    ),
                  );
                  return;
                }

                ref.read(localPollsProvider.notifier).createPoll(
                      groupId: widget.groupId,
                      createdBy: _currentUserId,
                      creatorName: _currentUserName,
                      question: question,
                      options: options,
                      isMultiSelect: isMultiSelect,
                      isAnonymous: isAnonymous,
                      deadline: deadline,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Poll card
// ---------------------------------------------------------------------------

class _PollCard extends ConsumerWidget {
  final Poll poll;
  final String groupId;

  const _PollCard({required this.poll, required this.groupId});

  static const _currentUserId = AppConstants.localUserId;
  static const _currentUserName = 'あなた';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalVotes = poll.options.fold<int>(
      0,
      (sum, opt) => sum + opt.voterIds.length,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: question + closed badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    poll.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (poll.isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '終了',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Options
            ...poll.options.map((option) {
              final hasVoted = option.voterIds.contains(_currentUserId);
              final voteCount = option.voterIds.length;
              final fraction =
                  totalVotes > 0 ? voteCount / totalVotes : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: poll.isClosed
                      ? null
                      : () {
                          ref.read(localPollsProvider.notifier).vote(
                                groupId: groupId,
                                pollId: poll.id,
                                optionId: option.id,
                                userId: _currentUserId,
                                userName: _currentUserName,
                              );
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasVoted
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        width: hasVoted ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Checkbox / Radio indicator
                            if (poll.isMultiSelect)
                              Icon(
                                hasVoted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: hasVoted
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              )
                            else
                              Icon(
                                hasVoted
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: hasVoted
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: hasVoted
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '$voteCount票',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Animated vote bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            builder: (_, value, _) =>
                                LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                hasVoted
                                    ? AppColors.primary
                                    : AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ),
                        // Voter names (unless anonymous)
                        if (!poll.isAnonymous &&
                            option.voterNames.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              option.voterNames.join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Footer: creator + deadline + close button
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  poll.creatorName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (poll.deadline != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.schedule,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${poll.deadline!.month}/${poll.deadline!.day}まで',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                if (!poll.isClosed && poll.createdBy == _currentUserId)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(localPollsProvider.notifier)
                          .closePoll(groupId, poll.id);
                    },
                    child: const Text(
                      '投票を閉じる',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
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
