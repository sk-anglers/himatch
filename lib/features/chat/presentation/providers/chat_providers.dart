import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/constants/demo_data.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';
import 'package:himatch/models/chat_message.dart';
import 'package:uuid/uuid.dart';

/// Chat service for sending and receiving messages.
///
/// Currently a local stub. Will be replaced with Supabase Realtime
/// when the backend is connected.
class ChatService {
  /// Send a message to a group chat.
  ///
  /// In production, this would push to Supabase and trigger Realtime.
  /// Currently returns immediately for offline-first development.
  Future<void> sendMessage(ChatMessage message) async {
    // TODO: Push to Supabase when connected
  }

  /// Mark all messages as read for a user in a group.
  Future<void> markAsRead(String groupId, String userId) async {
    // TODO: Update read receipts in Supabase
  }
}

/// Provides the [ChatService] singleton.
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Local chat messages state for offline-first development.
///
/// Key: groupId, Value: list of messages in that group.
/// Messages are ordered chronologically (oldest first).
final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, Map<String, List<ChatMessage>>>(
  ChatMessagesNotifier.new,
);

/// Notifier that manages chat message state for all groups.
class ChatMessagesNotifier extends Notifier<Map<String, List<ChatMessage>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<ChatMessage>> build() {
    final authState = ref.watch(authNotifierProvider);
    if (authState.isDemo) {
      return _demoMessages();
    }
    return {};
  }

  static Map<String, List<ChatMessage>> _demoMessages() {
    final now = DateTime.now();
    return {
      DemoData.demoGroupId: [
        ChatMessage(
          id: 'demo-msg-1',
          groupId: DemoData.demoGroupId,
          userId: 'demo-user-a',
          displayName: 'あかり',
          content: '今週末ひまな人いる？🙌',
          readBy: const ['demo-user-a'],
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'demo-msg-2',
          groupId: DemoData.demoGroupId,
          userId: 'demo-user-b',
          displayName: 'けんた',
          content: '土曜なら空いてるよ！',
          readBy: const ['demo-user-b'],
          createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        ),
        ChatMessage(
          id: 'demo-msg-3',
          groupId: DemoData.demoGroupId,
          userId: 'demo-user-c',
          displayName: 'みく',
          content: '私も土曜OK！ランチ行こうよ🍔',
          readBy: const ['demo-user-c'],
          createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
      ],
      DemoData.demoGroupId2: [
        ChatMessage(
          id: 'demo-msg-4',
          groupId: DemoData.demoGroupId2,
          userId: 'demo-user-d',
          displayName: 'そうた',
          content: '来週のシフト出した？',
          readBy: const ['demo-user-d'],
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
      ],
    };
  }

  /// Send a new message to a group chat.
  void sendMessage({
    required String groupId,
    required String content,
    String userId = AppConstants.localUserId,
    String displayName = 'You',
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? relatedSuggestionId,
  }) {
    final message = ChatMessage(
      id: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      displayName: displayName,
      content: content,
      messageType: messageType,
      imageUrl: imageUrl,
      relatedSuggestionId: relatedSuggestionId,
      reactions: const {},
      readBy: [userId],
      createdAt: DateTime.now(),
    );

    final current = List<ChatMessage>.from(state[groupId] ?? []);
    current.add(message);
    state = {...state, groupId: current};
  }

  /// Add a reaction (emoji) to a message.
  ///
  /// [emoji] is the emoji string (e.g. "thumbs_up").
  /// [userId] is added to the list of users who reacted with that emoji.
  void addReaction({
    required String groupId,
    required String messageId,
    required String emoji,
    String userId = AppConstants.localUserId,
  }) {
    final messages = List<ChatMessage>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final m in messages)
          if (m.id == messageId)
            m.copyWith(
              reactions: {
                ...m.reactions,
                emoji: [
                  ...m.reactions[emoji]?.where((u) => u != userId) ?? [],
                  userId,
                ],
              },
            )
          else
            m,
      ],
    };
  }

  /// Remove a reaction (emoji) from a message.
  void removeReaction({
    required String groupId,
    required String messageId,
    required String emoji,
    String userId = AppConstants.localUserId,
  }) {
    final messages = List<ChatMessage>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final m in messages)
          if (m.id == messageId)
            m.copyWith(
              reactions: {
                ...m.reactions,
                emoji: (m.reactions[emoji] ?? [])
                    .where((u) => u != userId)
                    .toList(),
              },
            )
          else
            m,
      ],
    };
  }

  /// Mark all messages in a group as read by the current user.
  void markAsRead(String groupId, {String userId = AppConstants.localUserId}) {
    final messages = List<ChatMessage>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final m in messages)
          if (!m.readBy.contains(userId))
            m.copyWith(readBy: [...m.readBy, userId])
          else
            m,
      ],
    };
  }
}

/// Unread message count for a specific group.
///
/// Returns the number of messages in the group that have not been read
/// by the local user.
final unreadCountProvider = Provider.family<int, String>((ref, groupId) {
  final allMessages = ref.watch(chatMessagesProvider);
  final messages = allMessages[groupId] ?? [];
  return messages.where((m) => !m.readBy.contains(AppConstants.localUserId)).length;
});
