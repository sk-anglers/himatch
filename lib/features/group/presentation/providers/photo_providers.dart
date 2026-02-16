import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/photo.dart';
import 'package:uuid/uuid.dart';

/// Local photo state for offline-first development.
///
/// Key: groupId, Value: list of photos in that group.
/// Will be replaced with Supabase Storage-backed provider when connected.
final localPhotosProvider =
    NotifierProvider<PhotosNotifier, Map<String, List<Photo>>>(
  PhotosNotifier.new,
);

/// Notifier that manages shared photos for all groups.
class PhotosNotifier extends Notifier<Map<String, List<Photo>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<Photo>> build() => {};

  /// Add a new photo to a group.
  ///
  /// [suggestionId] optionally links this photo to a confirmed suggestion
  /// (e.g. photos taken during a meetup).
  void addPhoto({
    required String groupId,
    required String uploadedBy,
    required String uploaderName,
    required String imageUrl,
    String? suggestionId,
    String? caption,
  }) {
    final photo = Photo(
      id: _uuid.v4(),
      groupId: groupId,
      uploadedBy: uploadedBy,
      uploaderName: uploaderName,
      imageUrl: imageUrl,
      suggestionId: suggestionId,
      caption: caption,
      reactions: const {},
      createdAt: DateTime.now(),
    );

    final current = List<Photo>.from(state[groupId] ?? []);
    current.insert(0, photo); // Newest first
    state = {...state, groupId: current};
  }

  /// Add a reaction (emoji) to a photo.
  ///
  /// [emoji] is the reaction key (e.g. "heart").
  /// [userId] is appended to the list of users who reacted.
  void addReaction({
    required String groupId,
    required String photoId,
    required String emoji,
    required String userId,
  }) {
    final photos = List<Photo>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final p in photos)
          if (p.id == photoId)
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

  /// Remove a photo from a group.
  void removePhoto(String groupId, String photoId) {
    final photos = List<Photo>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: photos.where((p) => p.id != photoId).toList(),
    };
  }

  /// Get all photos for a specific group.
  ///
  /// Returns an empty list if no photos exist for the group.
  List<Photo> getPhotos(String groupId) {
    return state[groupId] ?? [];
  }

  /// Get photos linked to a specific suggestion (meetup).
  ///
  /// Useful for displaying a photo album per confirmed suggestion.
  List<Photo> getPhotosBySuggestion(String groupId, String suggestionId) {
    final photos = state[groupId] ?? [];
    return photos.where((p) => p.suggestionId == suggestionId).toList();
  }
}
