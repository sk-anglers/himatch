import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/core/theme/app_theme.dart';
import 'package:himatch/models/post.dart';
import 'package:himatch/features/group/presentation/providers/post_providers.dart';

/// Community board screen for a group (BAND-style).
///
/// Shows a list of posts with pinned posts at top, reactions,
/// expandable comments, and a compose FAB.
class BoardScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const BoardScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  static const _currentUserId = 'local-user';
  static const _currentUserName = 'あなた';
  static const _reactionEmojis = [
    '\u{1F44D}',
    '\u{2764}\u{FE0F}',
    '\u{1F602}',
    '\u{1F389}',
    '\u{1F64C}',
  ];

  @override
  Widget build(BuildContext context) {
    final allPosts = ref.watch(localPostsProvider);
    final rawPosts = allPosts[widget.groupId] ?? [];

    // Sort: pinned first, then newest
    final posts = List<Post>.from(rawPosts);
    posts.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} の掲示板'),
      ),
      body: posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '投稿がありません',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '右下の + ボタンで投稿しましょう',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _PostCard(
                  post: posts[index],
                  groupId: widget.groupId,
                  reactionEmojis: _reactionEmojis,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新規投稿'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                maxLines: 6,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'グループに共有したいことを書きましょう...',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Integrate image_picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('画像選択は今後実装予定です')),
                      );
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('画像を追加'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
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
              final content = contentController.text.trim();
              if (content.isEmpty) return;

              ref.read(localPostsProvider.notifier).createPost(
                    groupId: widget.groupId,
                    userId: _currentUserId,
                    displayName: _currentUserName,
                    content: content,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('投稿'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post card
// ---------------------------------------------------------------------------

class _PostCard extends ConsumerStatefulWidget {
  final Post post;
  final String groupId;
  final List<String> reactionEmojis;

  const _PostCard({
    required this.post,
    required this.groupId,
    required this.reactionEmojis,
  });

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool _isExpanded = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned badge
              if (post.isPinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text('\u{1F4CC}', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '固定された投稿',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

              // Author row
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.3),
                    child: Text(
                      post.displayName.isNotEmpty
                          ? post.displayName[0]
                          : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Content
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),

              // Images (horizontal scroll)
              if (post.imageUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.imageUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrls[i],
                          height: 160,
                          width: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 160,
                            width: 160,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.broken_image,
                                color: AppColors.textHint),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // Reactions bar + comment count
              Row(
                children: [
                  // Reactions
                  if (post.reactions.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: post.reactions.entries
                            .where((e) => e.value.isNotEmpty)
                            .map(
                              (entry) => GestureDetector(
                                onTap: () {
                                  ref
                                      .read(localPostsProvider.notifier)
                                      .addReaction(
                                        groupId: widget.groupId,
                                        postId: post.id,
                                        emoji: entry.key,
                                        userId: 'local-user',
                                      );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.key} ${entry.value.length}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  else
                    const Spacer(),

                  // Reaction add button
                  IconButton(
                    icon: const Icon(Icons.add_reaction_outlined, size: 20),
                    color: AppColors.textHint,
                    onPressed: () => _showReactionPicker(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),

                  // Comment count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 16, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${post.comments.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded comment section
              if (_isExpanded) ...[
                const Divider(height: 20),
                // Comments
                ...post.comments.map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              AppColors.surfaceVariant,
                          child: Text(
                            comment.displayName.isNotEmpty
                                ? comment.displayName[0]
                                : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(comment.createdAt),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment.content,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'コメントを書く...',
                          hintStyle: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, size: 20),
                      color: AppColors.primary,
                      onPressed: () {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) return;
                        ref.read(localPostsProvider.notifier).addComment(
                              groupId: widget.groupId,
                              postId: post.id,
                              userId: 'local-user',
                              displayName: 'あなた',
                              content: text,
                            );
                        _commentController.clear();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.reactionEmojis
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      ref.read(localPostsProvider.notifier).addReaction(
                            groupId: widget.groupId,
                            postId: widget.post.id,
                            emoji: emoji,
                            userId: 'local-user',
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

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';

    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
