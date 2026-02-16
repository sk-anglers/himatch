import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/expense.dart';
import 'package:himatch/features/expense/presentation/providers/expense_providers.dart';

/// Settlement detail screen.
///
/// Displays all pending and completed settlements for a group,
/// with a button to mark each as settled.
class SettlementScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const SettlementScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recalculate settlements from all expenses
    final settlements = ref
        .read(localExpensesProvider.notifier)
        .calculateSettlements(groupId);

    final pending = settlements.where((s) => !s.isSettled).toList();
    final settled = settlements.where((s) => s.isSettled).toList();

    final totalOutstanding =
        pending.fold<int>(0, (sum, s) => sum + s.amount);
    final totalSettled =
        settled.fold<int>(0, (sum, s) => sum + s.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('$groupName の精算'),
      ),
      body: settlements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '精算するものがありません',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'すべて清算済みです',
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
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: '未精算',
                        amount: totalOutstanding,
                        color: AppColors.error,
                        icon: Icons.pending_actions,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: '精算済み',
                        amount: totalSettled,
                        color: AppColors.success,
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pending settlements
                if (pending.isNotEmpty) ...[
                  const Text(
                    '未精算の送金',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pending.map(
                    (s) => _SettlementCard(
                      settlement: s,
                      groupId: groupId,
                      isPending: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Settled
                if (settled.isNotEmpty) ...[
                  const Text(
                    '精算済み',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...settled.map(
                    (s) => _SettlementCard(
                      settlement: s,
                      groupId: groupId,
                      isPending: false,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\u{00A5}${_formatAmount(amount)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
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

// ---------------------------------------------------------------------------
// Settlement card
// ---------------------------------------------------------------------------

class _SettlementCard extends ConsumerWidget {
  final Settlement settlement;
  final String groupId;
  final bool isPending;

  const _SettlementCard({
    required this.settlement,
    required this.groupId,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // From
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.3),
                    child: Text(
                      settlement.fromName.isNotEmpty
                          ? settlement.fromName[0]
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settlement.fromName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow + amount
            Column(
              children: [
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '\u{00A5}${_formatAmount(settlement.amount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            // To
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.success.withValues(alpha: 0.2),
                    child: Text(
                      settlement.toName.isNotEmpty
                          ? settlement.toName[0]
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settlement.toName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Settle button or check
            const SizedBox(width: 8),
            if (isPending)
              ElevatedButton.icon(
                onPressed: () {
                  // Mark all related splits as paid
                  ref.read(localExpensesProvider.notifier).markAsPaid(
                        groupId: groupId,
                        expenseId: settlement.id,
                        userId: settlement.fromUserId,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${settlement.fromName} \u{2192} ${settlement.toName} を精算済みにしました',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('精算済みにする'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
          ],
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
