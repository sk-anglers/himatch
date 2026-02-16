import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/features/chat/presentation/providers/chat_providers.dart';
import 'package:himatch/features/group/presentation/providers/group_providers.dart';
import 'package:himatch/features/group/presentation/providers/poll_providers.dart';
import 'package:himatch/features/group/presentation/providers/todo_providers.dart';

/// Number of active (open) polls the local user has not voted on.
final unvotedPollCountProvider =
    Provider.family<int, String>((ref, groupId) {
  final allPolls = ref.watch(localPollsProvider);
  final polls = allPolls[groupId] ?? [];
  return polls.where((p) {
    if (p.isClosed) return false;
    // Check if local-user has voted on any option
    return !p.options.any((o) => o.voterIds.contains('local-user'));
  }).length;
});

/// Number of incomplete todo items in a group.
final incompleteTodoCountProvider =
    Provider.family<int, String>((ref, groupId) {
  final allTodos = ref.watch(localTodosProvider);
  final todos = allTodos[groupId] ?? [];
  return todos.where((t) => !t.isCompleted).length;
});

/// Aggregate notification count for a single group.
///
/// Sum of: chat unread + unvoted polls + incomplete todos.
final groupNotificationCountProvider =
    Provider.family<int, String>((ref, groupId) {
  final chatUnread = ref.watch(unreadCountProvider(groupId));
  final pollUnvoted = ref.watch(unvotedPollCountProvider(groupId));
  final todoIncomplete = ref.watch(incompleteTodoCountProvider(groupId));
  return chatUnread + pollUnvoted + todoIncomplete;
});

/// Total notification count across all groups (for bottom nav badge).
final totalGroupNotificationsProvider = Provider<int>((ref) {
  final groups = ref.watch(localGroupsProvider);
  var total = 0;
  for (final group in groups) {
    total += ref.watch(groupNotificationCountProvider(group.id));
  }
  return total;
});
