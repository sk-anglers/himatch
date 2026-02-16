import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/activity.dart';
import 'package:uuid/uuid.dart';

/// Local activity feed state for offline-first development.
///
/// Key: groupId, Value: list of activities in that group.
/// Activities are stored in reverse chronological order (newest first).
final localActivitiesProvider =
    NotifierProvider<ActivitiesNotifier, Map<String, List<Activity>>>(
  ActivitiesNotifier.new,
);

/// Notifier that manages the activity feed for all groups.
class ActivitiesNotifier extends Notifier<Map<String, List<Activity>>> {
  static const _uuid = Uuid();

  @override
  Map<String, List<Activity>> build() => {};

  /// Add a new activity to the group feed.
  ///
  /// [relatedId] can point to a suggestion, schedule, or other entity
  /// that triggered this activity.
  void addActivity({
    required String groupId,
    required String userId,
    required String displayName,
    required ActivityType type,
    required String message,
    String? relatedId,
  }) {
    final activity = Activity(
      id: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      displayName: displayName,
      type: type,
      message: message,
      relatedId: relatedId,
      reactions: const {},
      createdAt: DateTime.now(),
    );

    final current = List<Activity>.from(state[groupId] ?? []);
    current.insert(0, activity); // Newest first
    state = {...state, groupId: current};
  }

  /// Add a reaction (emoji) to an activity.
  ///
  /// [emoji] is the reaction key (e.g. "thumbs_up").
  /// [userId] is appended to the list of users who reacted.
  void addReaction({
    required String groupId,
    required String activityId,
    required String emoji,
    required String userId,
  }) {
    final activities = List<Activity>.from(state[groupId] ?? []);
    state = {
      ...state,
      groupId: [
        for (final a in activities)
          if (a.id == activityId)
            a.copyWith(
              reactions: {
                ...a.reactions,
                emoji: [
                  ...a.reactions[emoji]?.where((u) => u != userId) ?? [],
                  userId,
                ],
              },
            )
          else
            a,
      ],
    };
  }

  /// Get activities for a specific group.
  ///
  /// Returns an empty list if no activities exist for the group.
  List<Activity> getActivities(String groupId) {
    return state[groupId] ?? [];
  }
}
