import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/post.dart';
import 'package:uuid/uuid.dart';

/// Local post/timeline state for offline-first development.
///
/// Key: groupId, Value: list of posts in that group.
/// Will be replaced with Supabase-backed provider when connected.
final localPostsProvider =
    NotifierProvider<PostsNotifier, Map<String, List<Post>>>(
  PostsNotifier.new,
);

/// Notifier that manages group posts (timeline/feed) for all groups.
class PostsNotifier extends Notifier<Map<String, List<Post>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<Post>> build() => {};

  /// Create a new post in a group.
  ///
  /// [imageUrls] is an optional list of image URLs attached to the post.
  void createPost({
    required String groupId,
    required String userId,
    required String displayName,
    required String content,
    List<String>? imageUrls,
  }) {
    final post = Post(
      id: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      displayName: displayName,
      content: content,
      imageUrls: imageUrls ?? const [],
      reactions: const {},
      comments: const [],
      isPinned: false,
      createdAt: DateTime.now(),
    );

    final current = List<Post>.from(state[groupId] ?? []);
    current.insert(0, post); // Newest first
    state = {...state, groupId: current};
  }

  /// Add a comment to a post.
  void addComment({
    required String groupId,
    required String postId,
    required String userId,
    required String displayName,
    required String content,
  }) {
    final comment = PostComment(
      id: _uuid.v4(),
      userId: userId,
      displayName: displayName,
      content: content,
      createdAt: DateTime.now(),
    );

    final posts = List<Post>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final p in posts)
          if (p.id == postId)
            p.copyWith(comments: [...p.comments, comment])
          else
            p,
      ],
    };
  }

  /// Add a reaction (emoji) to a post.
  ///
  /// [emoji] is the reaction key (e.g. "thumbs_up").
  /// [userId] is appended to the list of users who reacted.
  void addReaction({
    required String groupId,
    required String postId,
    required String emoji,
    required String userId,
  }) {
    final posts = List<Post>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final p in posts)
          if (p.id == postId)
            p.copyWith(
              reactions: {
                ...p.reactions,
                emoji: [
                  ...p.reactions[emoji]?.where((u) => u != userId) ?? [],
                  userId,
                ],
              },
            )
          else
            p,
      ],
    };
  }

  /// Toggle pin status of a post.
  ///
  /// Pinned posts typically appear at the top of the group feed.
  void togglePin(String groupId, String postId) {
    final posts = List<Post>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final p in posts)
          if (p.id == postId) p.copyWith(isPinned: !p.isPinned) else p,
      ],
    };
  }

  /// Get all posts for a specific group.
  ///
  /// Returns posts with pinned posts first, then by creation date descending.
  List<Post> getPosts(String groupId) {
    final posts = List<Post>.from(state[groupId] ?? []);
    posts.sort((a, b) {
      // Pinned posts first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by date descending
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return posts;
  }
}
