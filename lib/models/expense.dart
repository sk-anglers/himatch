import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
abstract class ExpenseItem with _$ExpenseItem {
  const factory ExpenseItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    required int amount,
    @JsonKey(name: 'is_paid') @Default(false) bool isPaid,
  }) = _ExpenseItem;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) =>
      _$ExpenseItemFromJson(json);
}

@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'suggestion_id') String? suggestionId,
    required String title,
    @JsonKey(name: 'total_amount') required int totalAmount,
    @JsonKey(name: 'paid_by') required String paidBy,
    @JsonKey(name: 'paid_by_name') required String paidByName,
    @JsonKey(name: 'split_type') @Default('equal') String splitType,
    required List<ExpenseItem> splits,
    String? memo,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

@freezed
abstract class Settlement with _$Settlement {
  const factory Settlement({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'from_user_id') required String fromUserId,
    @JsonKey(name: 'from_name') required String fromName,
    @JsonKey(name: 'to_user_id') required String toUserId,
    @JsonKey(name: 'to_name') required String toName,
    required int amount,
    @JsonKey(name: 'is_settled') @Default(false) bool isSettled,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Settlement;

  factory Settlement.fromJson(Map<String, dynamic> json) =>
      _$SettlementFromJson(json);
}
