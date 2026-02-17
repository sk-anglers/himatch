import 'package:himatch/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/event_template.dart';
import 'package:uuid/uuid.dart';

/// Local event template state for offline-first development.
///
/// Templates allow users to quickly create events with pre-filled fields
/// (e.g. "Weekly meeting" with a default time, location, and memo).
final eventTemplatesProvider =
    NotifierProvider<EventTemplatesNotifier, List<EventTemplate>>(
  EventTemplatesNotifier.new,
);

/// Notifier that manages event templates.
class EventTemplatesNotifier extends Notifier<List<EventTemplate>> {
  static const _uuid = Uuid();

  @override
  List<EventTemplate> build() => [];

  /// Add a new event template.
  ///
  /// [defaultStartTime] and [defaultEndTime] are time-of-day strings
  /// (e.g. "09:00", "17:00") used to pre-fill the event creation form.
  void addTemplate({
    required String name,
    required String title,
    String? defaultStartTime,
    String? defaultEndTime,
    String? location,
    String? memo,
    String? iconEmoji,
    String? colorHex,
  }) {
    final template = EventTemplate(
      id: _uuid.v4(),
      userId: AppConstants.localUserId,
      name: name,
      title: title,
      defaultStartTime: defaultStartTime,
      defaultEndTime: defaultEndTime,
      location: location,
      memo: memo,
      iconEmoji: iconEmoji,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );
    state = [...state, template];
  }

  /// Update an existing template.
  void updateTemplate(EventTemplate updated) {
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
  }

  /// Remove a template by ID.
  void removeTemplate(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}
