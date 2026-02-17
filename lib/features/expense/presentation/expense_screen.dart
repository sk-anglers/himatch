import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/expense.dart';
import 'package:himatch/features/expense/presentation/providers/expense_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/expense/presentation/settlement_screen.dart';

/// Expense tracker screen for a group.
///
/// Shows a list of shared expenses with expandable splits,
/// a settlement summary section, and a FAB to add expenses.
class ExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const ExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  static const _currentUserId = AppConstants.localUserId;
  static const _currentUserName = 'あなた';

  @override
  Widget build(BuildContext context) {
    final allExpenses = ref.watch(localExpensesProvider);
    final expenses = allExpenses[widget.groupId] ?? [];

    // Calculate settlements
    final settlements = ref
        .read(localExpensesProvider.notifier)
        .calculateSettlements(widget.groupId);
    final pendingSettlements =
        settlements.where((s) => !s.isSettled).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} の割り勘'),
        actions: [
          if (pendingSettlements.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettlementScreen(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                    ),
                  ),
                );
              },
              child: const Text('精算'),
            ),
        ],
      ),
      body: expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '経費がありません',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '右下の + ボタンで経費を追加しましょう',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Settlement summary
                if (pendingSettlements.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        '精算',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettlementScreen(
                                groupId: widget.groupId,
                                groupName: widget.groupName,
                              ),
                            ),
                          );
                        },
                        child: const Text('詳細'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pendingSettlements.take(3).map(
                        (s) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.swap_horiz,
                                color: AppColors.warning, size: 20),
                            title: Text(
                              '${s.fromName} \u{2192} ${s.toName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              '\u{00A5}${_formatAmount(s.amount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                  if (pendingSettlements.length > 3)
                    Center(
                      child: Text(
                        '他 ${pendingSettlements.length - 3}件...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // Expense list header
                const Text(
                  '経費一覧',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Expense cards
                ...expenses.map(
                  (expense) => _ExpenseCard(
                    expense: expense,
                    groupId: widget.groupId,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final memoController = TextEditingController();
    String paidBy = _currentUserId;
    String paidByName = _currentUserName;
    String splitType = 'equal';

    final membersMap = ref.read(localGroupMembersProvider);
    final members = membersMap[widget.groupId] ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('経費を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: '例: カフェ代',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '金額',
                    prefixText: '\u{00A5} ',
                    hintText: '3000',
                  ),
                ),
                const SizedBox(height: 12),

                // Paid by picker
                DropdownButtonFormField<String>(
                  initialValue: paidBy,
                  decoration: const InputDecoration(labelText: '支払った人'),
                  items: members.map((m) {
                    final name = m.nickname ??
                        (m.userId == AppConstants.localUserId ? 'あなた' : 'メンバー');
                    return DropdownMenuItem(
                      value: m.userId,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      paidBy = value;
                      final member =
                          members.where((m) => m.userId == value);
                      paidByName = member.isNotEmpty
                          ? member.first.nickname ??
                              (member.first.userId == AppConstants.localUserId
                                  ? 'あなた'
                                  : 'メンバー')
                          : 'メンバー';
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Split type
                DropdownButtonFormField<String>(
                  initialValue: splitType,
                  decoration: const InputDecoration(labelText: '割り方'),
                  items: const [
                    DropdownMenuItem(
                        value: 'equal', child: Text('均等割り')),
                    DropdownMenuItem(
                        value: 'custom', child: Text('カスタム')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => splitType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: memoController,
                  decoration: const InputDecoration(
                    labelText: 'メモ（任意）',
                    hintText: '備考があれば',
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
                final title = titleController.text.trim();
                final amountText = amountController.text.trim();
                final amount = int.tryParse(amountText);

                if (title.isEmpty || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('タイトルと正しい金額を入力してください'),
                    ),
                  );
                  return;
                }

                // Build equal splits
                final splitAmount = amount ~/ members.length;
                final splits = members
                    .where((m) => m.userId != paidBy)
                    .map(
                      (m) => ExpenseItem(
                        id: '${m.userId}-${DateTime.now().millisecondsSinceEpoch}',
                        userId: m.userId,
                        displayName: m.nickname ??
                            (m.userId == AppConstants.localUserId ? 'あなた' : 'メンバー'),
                        amount: splitAmount,
                        isPaid: false,
                      ),
                    )
                    .toList();

                ref.read(localExpensesProvider.notifier).addExpense(
                      groupId: widget.groupId,
                      title: title,
                      totalAmount: amount,
                      paidBy: paidBy,
                      paidByName: paidByName,
                      splits: splits,
                      splitType: splitType,
                      memo: memoController.text.trim().isNotEmpty
                          ? memoController.text.trim()
                          : null,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    // Simple thousand separator
    final str = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ---------------------------------------------------------------------------
// Expense card with expandable splits
// ---------------------------------------------------------------------------

class _ExpenseCard extends ConsumerStatefulWidget {
  final Expense expense;
  final String groupId;

  const _ExpenseCard({required this.expense, required this.groupId});

  @override
  ConsumerState<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends ConsumerState<_ExpenseCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + paid by
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${expense.paidByName}が支払い',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\u{00A5}${_formatAmount(expense.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (expense.createdAt != null)
                        Text(
                          '${expense.createdAt!.month}/${expense.createdAt!.day}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Expanded splits
              if (_isExpanded) ...[
                const Divider(height: 20),
                ...expense.splits.map(
                  (split) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          split.isPaid
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: split.isPaid
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            split.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: split.isPaid
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: split.isPaid
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '\u{00A5}${_formatAmount(split.amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: split.isPaid
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (!split.isPaid)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: TextButton(
                              onPressed: () {
                                ref
                                    .read(localExpensesProvider.notifier)
                                    .markAsPaid(
                                      groupId: widget.groupId,
                                      expenseId: expense.id,
                                      userId: split.userId,
                                    );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '精算済み',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (expense.memo != null && expense.memo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.note,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text(
                          expense.memo!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // Expand indicator
              Center(
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
