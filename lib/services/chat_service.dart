import 'package:uuid/uuid.dart';

import 'package:himatch/models/chat_message.dart';

/// Chat service with local state management.
///
/// Provides in-memory message storage, reactions, read receipts,
/// and unread counting. Ready for Supabase Realtime integration —
/// the local methods mirror the expected remote API surface.
class ChatService {
  static const _uuid = Uuid();

  /// Maximum allowed message length.
  static const int maxMessageLength = 5000;

  /// Messages indexed by group ID.
  final Map<String, List<ChatMessage>> _messages = {};

  /// Last read timestamp per group per user: {groupId: {userId: DateTime}}.
  final Map<String, Map<String, DateTime>> _lastRead = {};

  /// Sanitize message content: trim, limit length, strip control chars.
  static String _sanitize(String input) {
    // Strip control characters except newline/tab
    final cleaned = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    final trimmed = cleaned.trim();
    if (trimmed.length > maxMessageLength) {
      return trimmed.substring(0, maxMessageLength);
    }
    return trimmed;
  }

  /// Get all messages for a group, sorted by creation time.
  List<ChatMessage> getMessages(String groupId) {
    return List.unmodifiable(_messages[groupId] ?? []);
  }

  /// Send a message to a group. Returns the created message.
  ChatMessage sendMessage({
    required String groupId,
    required String userId,
    required String displayName,
    required String content,
    String? avatarUrl,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? relatedSuggestionId,
  }) {
    final sanitized = _sanitize(content);
    if (sanitized.isEmpty) {
      throw ArgumentError('Message content must not be empty');
    }
    final now = DateTime.now();

    final message = ChatMessage(
      id: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      content: sanitized,
      messageType: type,
      imageUrl: imageUrl,
      relatedSuggestionId: relatedSuggestionId,
      reactions: const {},
      readBy: [userId], // Sender has read their own message
      createdAt: now,
    );

    _messages.putIfAbsent(groupId, () => []);
    _messages[groupId]!.add(message);

    // Update sender's last read
    _updateLastRead(groupId, userId, now);

    return message;
  }

  /// Send a system message (e.g. member joined, suggestion confirmed).
  ChatMessage sendSystemMessage({
    required String groupId,
    required String content,
  }) {
    return sendMessage(
      groupId: groupId,
      userId: 'system',
      displayName: 'System',
      content: content,
      type: MessageType.system,
    );
  }

  /// Add a reaction emoji from a user to a message.
  void addReaction(
    String groupId,
    String messageId,
    String emoji,
    String userId,
  ) {
    final messages = _messages[groupId];
    if (messages == null) return;

    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = messages[index];
    final reactions = Map<String, List<String>>.from(
      message.reactions.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );

    reactions.putIfAbsent(emoji, () => []);
    if (!reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.add(userId);
    }

    messages[index] = message.copyWith(reactions: reactions);
  }

  /// Remove a reaction emoji from a user on a message.
  void removeReaction(
    String groupId,
    String messageId,
    String emoji,
    String userId,
  ) {
    final messages = _messages[groupId];
    if (messages == null) return;

    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = messages[index];
    final reactions = Map<String, List<String>>.from(
      message.reactions.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );

    if (reactions.containsKey(emoji)) {
      reactions[emoji]!.remove(userId);
      if (reactions[emoji]!.isEmpty) {
        reactions.remove(emoji);
      }
    }

    messages[index] = message.copyWith(reactions: reactions);
  }

  /// Mark all current messages in a group as read by a user.
  void markAsRead(String groupId, String userId) {
    final messages = _messages[groupId];
    if (messages == null || messages.isEmpty) return;

    final now = DateTime.now();
    _updateLastRead(groupId, userId, now);

    // Update readBy on messages
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!message.readBy.contains(userId)) {
        final updatedReadBy = List<String>.from(message.readBy)..add(userId);
        messages[i] = message.copyWith(readBy: updatedReadBy);
      }
    }
  }

  /// Get the unread message count for a user in a group.
  int unreadCount(String groupId, String userId) {
    final messages = _messages[groupId];
    if (messages == null || messages.isEmpty) return 0;

    final lastReadTime = _lastRead[groupId]?[userId];
    if (lastReadTime == null) {
      // User has never read — all messages except system messages are unread
      return messages.where((m) => m.userId != userId).length;
    }

    return messages.where((m) {
      if (m.userId == userId) return false; // Own messages are never unread
      final createdAt = m.createdAt;
      if (createdAt == null) return false;
      return createdAt.isAfter(lastReadTime);
    }).length;
  }

  /// Get messages since a given timestamp.
  List<ChatMessage> getMessagesSince(String groupId, DateTime since) {
    final messages = _messages[groupId];
    if (messages == null) return [];

    return messages.where((m) {
      final createdAt = m.createdAt;
      if (createdAt == null) return false;
      return createdAt.isAfter(since);
    }).toList();
  }

  /// Get the latest message in a group (for preview).
  ChatMessage? getLatestMessage(String groupId) {
    final messages = _messages[groupId];
    if (messages == null || messages.isEmpty) return null;
    return messages.last;
  }

  /// Delete a message by ID.
  bool deleteMessage(String groupId, String messageId) {
    final messages = _messages[groupId];
    if (messages == null) return false;

    final initialLength = messages.length;
    messages.removeWhere((m) => m.id == messageId);
    return messages.length < initialLength;
  }

  /// Clear all messages in a group (for testing or cleanup).
  void clearGroup(String groupId) {
    _messages.remove(groupId);
    _lastRead.remove(groupId);
  }

  /// Clear all data (for testing or logout).
  void clearAll() {
    _messages.clear();
    _lastRead.clear();
  }

  // ── Private helpers ──

  void _updateLastRead(String groupId, String userId, DateTime time) {
    _lastRead.putIfAbsent(groupId, () => {});
    _lastRead[groupId]![userId] = time;
  }
}
