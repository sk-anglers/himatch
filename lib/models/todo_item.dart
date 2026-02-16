import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_item.freezed.dart';
part 'todo_item.g.dart';

@freezed
abstract class TodoItem with _$TodoItem {
  const factory TodoItem({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'suggestion_id') String? suggestionId,
    required String title,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'assigned_name') String? assignedName,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TodoItem;

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);
}
