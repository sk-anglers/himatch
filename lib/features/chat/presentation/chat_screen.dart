import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/chat_message.dart';
import 'package:himatch/features/chat/presentation/providers/chat_providers.dart';

/// Group chat screen with bubble-based messaging layout.
///
/// Displays a real-time message list with bubbles, reactions, and
/// a compose bar at the bottom.
class ChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final int memberCount;

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  static const _currentUserId = 'local-user';
  static const _reactionEmojis = [
    '\u{1F44D}', // thumbs up
    '\u{2764}\u{FE0F}', // heart
    '\u{1F602}', // joy
    '\u{1F389}', // party
    '\u{1F64C}', // raising hands
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatMessagesProvider.notifier).sendMessage(
          groupId: widget.groupId,
          content: text,
        );
    _textController.clear();

    // Scroll to bottom after send
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReactionPicker(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      ref.read(chatMessagesProvider.notifier).addReaction(
                            groupId: widget.groupId,
                            messageId: message.id,
                            emoji: emoji,
                          );
                      Navigator.pop(ctx);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMessages = ref.watch(chatMessagesProvider);
    final messages = allMessages[widget.groupId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${widget.memberCount}人のメンバー',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'メッセージがありません\n最初のメッセージを送りましょう',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        message: message,
                        isOwn: message.userId == _currentUserId,
                        onTap: () => _showReactionPicker(message),
                      );
                    },
                  ),
          ),

          // Compose bar
          _ComposeBar(
            controller: _textController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;
  final VoidCallback onTap;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // System messages
    if (message.messageType == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Text(
                message.displayName.isNotEmpty ? message.displayName[0] : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment:
                    isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        message.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isOwn
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isOwn ? 16 : 4),
                        bottomRight: Radius.circular(isOwn ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image message
                        if (message.messageType == MessageType.image &&
                            message.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              message.imageUrl!,
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 200,
                                height: 150,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.broken_image,
                                    color: AppColors.textHint),
                              ),
                            ),
                          ),

                        // Text content
                        if (message.content.isNotEmpty)
                          Text(
                            message.content,
                            style: TextStyle(
                              color: isOwn ? Colors.white : AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),

                        // Related suggestion badge
                        if (message.relatedSuggestionId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOwn
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 12,
                                    color: isOwn
                                        ? Colors.white70
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '提案に関連',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isOwn
                                          ? Colors.white70
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Text(
                      _formatTime(message.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),

                  // Reactions row
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 4,
                        children: message.reactions.entries
                            .where((e) => e.value.isNotEmpty)
                            .map(
                              (entry) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${entry.key} ${entry.value.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isOwn) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Compose bar
// ---------------------------------------------------------------------------

class _ComposeBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ComposeBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onSend,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
