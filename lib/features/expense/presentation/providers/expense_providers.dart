import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/expense.dart';
import 'package:uuid/uuid.dart';

/// Local expense/割り勘 state for offline-first development.
///
/// Key: groupId, Value: list of expenses in that group.
/// Will be replaced with Supabase-backed provider when connected.
final localExpensesProvider =
    NotifierProvider<ExpensesNotifier, Map<String, List<Expense>>>(
  ExpensesNotifier.new,
);

/// Notifier that manages expense splitting for all groups.
class ExpensesNotifier extends Notifier<Map<String, List<Expense>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<Expense>> build() => {};

  /// Add a new shared expense to a group.
  ///
  /// [splits] defines how the expense is divided among members.
  /// [splitType] can be "equal", "custom", or "percentage".
  /// [suggestionId] optionally links to a confirmed meetup suggestion.
  void addExpense({
    required String groupId,
    required String title,
    required int totalAmount,
    required String paidBy,
    required String paidByName,
    required List<ExpenseItem> splits,
    String splitType = 'equal',
    String? memo,
    String? suggestionId,
  }) {
    final expense = Expense(
      id: _uuid.v4(),
      groupId: groupId,
      title: title,
      totalAmount: totalAmount,
      paidBy: paidBy,
      paidByName: paidByName,
      splits: splits,
      splitType: splitType,
      memo: memo,
      suggestionId: suggestionId,
      createdAt: DateTime.now(),
    );

    final current = List<Expense>.from(state[groupId] ?? []);
    current.insert(0, expense); // Newest first
    state = {...state, groupId: current};
  }

  /// Mark a split as paid by a specific user.
  ///
  /// This is used when a member reimburses the payer.
  void markAsPaid({
    required String groupId,
    required String expenseId,
    required String userId,
  }) {
    final expenses = List<Expense>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final e in expenses)
          if (e.id == expenseId)
            e.copyWith(
              splits: [
                for (final s in e.splits)
                  if (s.userId == userId)
                    s.copyWith(isPaid: true)
                  else
                    s,
              ],
            )
          else
            e,
      ],
    };
  }

  /// Get all expenses for a specific group.
  ///
  /// Returns an empty list if no expenses exist for the group.
  List<Expense> getExpenses(String groupId) {
    return state[groupId] ?? [];
  }

  /// Calculate net settlements for a group.
  ///
  /// Aggregates all unpaid splits into a simplified list of who owes whom.
  /// Uses the "minimum cash flow" approach: calculates net balance per person,
  /// then generates optimal transfers.
  List<Settlement> calculateSettlements(String groupId) {
    final expenses = state[groupId] ?? [];
    if (expenses.isEmpty) return [];

    // Calculate net balance: positive = is owed, negative = owes
    final balances = <String, int>{};
    final names = <String, String>{};

    for (final expense in expenses) {
      // Payer is owed the total
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.totalAmount;
      names[expense.paidBy] = expense.paidByName;

      // Each split person owes their share
      for (final split in expense.splits) {
        if (!split.isPaid) {
          balances[split.userId] =
              (balances[split.userId] ?? 0) - split.amount;
          names[split.userId] = split.displayName;
        }
      }
    }

    // Generate settlements from net balances
    final creditors = <MapEntry<String, int>>[]; // positive balance
    final debtors = <MapEntry<String, int>>[]; // negative balance

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        creditors.add(entry);
      } else if (entry.value < 0) {
        debtors.add(entry);
      }
    }

    final settlements = <Settlement>[];
    var ci = 0;
    var di = 0;
    final creditAmounts = creditors.map((e) => e.value).toList();
    final debtAmounts = debtors.map((e) => -e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final amount =
          creditAmounts[ci] < debtAmounts[di]
              ? creditAmounts[ci]
              : debtAmounts[di];

      if (amount > 0) {
        settlements.add(Settlement(
          id: _uuid.v4(),
          groupId: groupId,
          fromUserId: debtors[di].key,
          fromName: names[debtors[di].key] ?? '',
          toUserId: creditors[ci].key,
          toName: names[creditors[ci].key] ?? '',
          amount: amount,
          createdAt: DateTime.now(),
        ));
      }

      creditAmounts[ci] -= amount;
      debtAmounts[di] -= amount;

      if (creditAmounts[ci] == 0) ci++;
      if (debtAmounts[di] == 0) di++;
    }

    return settlements;
  }
}
