import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/todo_item.dart';
import 'package:uuid/uuid.dart';

/// Local todo state for offline-first development.
///
/// Key: groupId, Value: list of todo items in that group.
/// Will be replaced with Supabase-backed provider when connected.
final localTodosProvider =
    NotifierProvider<TodosNotifier, Map<String, List<TodoItem>>>(
  TodosNotifier.new,
);

/// Notifier that manages todo items for all groups.
class TodosNotifier extends Notifier<Map<String, List<TodoItem>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<TodoItem>> build() => {};

  /// Add a new todo item to a group.
  ///
  /// [suggestionId] optionally links this todo to a confirmed suggestion
  /// (e.g. "buy supplies for Saturday meetup").
  void addTodo({
    required String groupId,
    required String title,
    required String createdBy,
    String? assignedTo,
    String? assignedName,
    DateTime? dueDate,
    String? suggestionId,
  }) {
    final todo = TodoItem(
      id: _uuid.v4(),
      groupId: groupId,
      title: title,
      createdBy: createdBy,
      assignedTo: assignedTo,
      assignedName: assignedName,
      dueDate: dueDate,
      suggestionId: suggestionId,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    final current = List<TodoItem>.from(state[groupId] ?? []);
    current.add(todo);
    state = {...state, groupId: current};
  }

  /// Toggle the completion status of a todo item.
  void toggleTodo(String groupId, String todoId) {
    final todos = List<TodoItem>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final t in todos)
          if (t.id == todoId)
            t.copyWith(isCompleted: !t.isCompleted)
          else
            t,
      ],
    };
  }

  /// Remove a todo item from a group.
  void removeTodo(String groupId, String todoId) {
    final todos = List<TodoItem>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: todos.where((t) => t.id != todoId).toList(),
    };
  }

  /// Get all todo items for a specific group.
  ///
  /// Returns an empty list if no todos exist for the group.
  List<TodoItem> getTodos(String groupId) {
    return state[groupId] ?? [];
  }
}
