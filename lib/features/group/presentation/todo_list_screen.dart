import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/todo_item.dart';
import 'package:himatch/features/group/presentation/providers/todo_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';

/// Shared todo list screen for a group.
///
/// Items are grouped by linked suggestion (or "一般").
/// Completed items sink to the bottom. FAB opens an add-todo dialog.
class TodoListScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const TodoListScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  @override
  Widget build(BuildContext context) {
    final allTodos = ref.watch(localTodosProvider);
    final todos = allTodos[widget.groupId] ?? [];

    final completedCount = todos.where((t) => t.isCompleted).length;
    final totalCount = todos.length;

    // Group by suggestionId
    final grouped = <String?, List<TodoItem>>{};
    for (final todo in todos) {
      grouped.putIfAbsent(todo.suggestionId, () => []).add(todo);
    }

    // Sort each group: incomplete first, then completed
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return 0;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} のToDoリスト'),
      ),
      body: Column(
        children: [
          // Progress bar
          if (totalCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '進捗: $completedCount / $totalCount 完了',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        totalCount > 0
                            ? '${(completedCount / totalCount * 100).round()}%'
                            : '0%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? completedCount / totalCount : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Todo groups
          Expanded(
            child: todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ToDoがありません',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '右下の + ボタンで追加しましょう',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: grouped.entries.map((entry) {
                      final sectionTitle =
                          entry.key == null ? '一般' : '提案: ${entry.key}';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 6),
                            child: Text(
                              sectionTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ...entry.value.map(
                            (todo) => _TodoTile(
                              todo: todo,
                              groupId: widget.groupId,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final titleController = TextEditingController();
    String? selectedMemberId;
    String? selectedMemberName;
    DateTime? dueDate;

    final membersMap = ref.read(localGroupMembersProvider);
    final members = membersMap[widget.groupId] ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('新しいToDo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: '例: 材料を買う',
                  ),
                ),
                const SizedBox(height: 16),

                // Assignee picker
                DropdownButtonFormField<String>(
                  initialValue: selectedMemberId,
                  decoration: const InputDecoration(
                    labelText: '担当者',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('未割り当て'),
                    ),
                    ...members.map(
                      (m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(
                          m.nickname ??
                              (m.userId == 'local-user' ? 'あなた' : 'メンバー'),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMemberId = value;
                      final member = members.where(
                        (m) => m.userId == value,
                      );
                      selectedMemberName = member.isNotEmpty
                          ? member.first.nickname ??
                              (member.first.userId == 'local-user'
                                  ? 'あなた'
                                  : 'メンバー')
                          : null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Due date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '期限日',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      dueDate != null
                          ? '${dueDate!.year}/${dueDate!.month}/${dueDate!.day}'
                          : '未設定',
                      style: TextStyle(
                        color: dueDate != null
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
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                ref.read(localTodosProvider.notifier).addTodo(
                      groupId: widget.groupId,
                      title: title,
                      createdBy: 'local-user',
                      assignedTo: selectedMemberId,
                      assignedName: selectedMemberName,
                      dueDate: dueDate,
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
}

// ---------------------------------------------------------------------------
// Todo tile with swipe-to-delete
// ---------------------------------------------------------------------------

class _TodoTile extends ConsumerWidget {
  final TodoItem todo;
  final String groupId;

  const _TodoTile({required this.todo, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(localTodosProvider.notifier).removeTodo(groupId, todo.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${todo.title}」を削除しました')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: Checkbox(
            value: todo.isCompleted,
            activeColor: AppColors.success,
            onChanged: (_) {
              ref
                  .read(localTodosProvider.notifier)
                  .toggleTodo(groupId, todo.id);
            },
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration:
                  todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted
                  ? AppColors.textHint
                  : AppColors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              // Assigned person chip
              if (todo.assignedName != null)
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    todo.assignedName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Due date
              if (todo.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: _isDueOverdue(todo.dueDate!)
                            ? AppColors.error
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${todo.dueDate!.month}/${todo.dueDate!.day}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isDueOverdue(todo.dueDate!)
                              ? AppColors.error
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDueOverdue(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }
}
