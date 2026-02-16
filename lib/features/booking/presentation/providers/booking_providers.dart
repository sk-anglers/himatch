import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/booking_page.dart';
import 'package:uuid/uuid.dart';

/// Local booking page state for offline-first development.
///
/// Manages shareable booking pages where users can publish
/// availability and receive bookings from others.
final bookingPagesProvider =
    NotifierProvider<BookingPagesNotifier, List<BookingPage>>(
  BookingPagesNotifier.new,
);

/// Notifier that manages booking pages and their slots.
class BookingPagesNotifier extends Notifier<List<BookingPage>> {
  static const _uuid = Uuid();

  @override
  List<BookingPage> build() => [];

  /// Create a new booking page.
  ///
  /// [availableDays] is a list of weekday numbers (1=Monday, 7=Sunday).
  /// A URL-friendly [slug] is auto-generated from the title.
  void createPage({
    required String title,
    String? description,
    int durationMinutes = 60,
    int bufferMinutes = 15,
    int maxBookingsPerDay = 5,
    String availableHoursStart = '09:00',
    String availableHoursEnd = '18:00',
    List<int> availableDays = const [1, 2, 3, 4, 5],
  }) {
    final slug = _generateSlug(title);

    final page = BookingPage(
      id: _uuid.v4(),
      userId: 'local-user',
      title: title,
      description: description,
      slug: slug,
      durationMinutes: durationMinutes,
      bufferMinutes: bufferMinutes,
      maxBookingsPerDay: maxBookingsPerDay,
      availableHoursStart: availableHoursStart,
      availableHoursEnd: availableHoursEnd,
      availableDays: availableDays,
      isActive: true,
      bookings: const [],
      createdAt: DateTime.now(),
    );

    state = [...state, page];
  }

  /// Update an existing booking page.
  void updatePage(BookingPage updated) {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
  }

  /// Toggle whether a booking page is active (accepting bookings).
  void toggleActive(String pageId) {
    state = [
      for (final p in state)
        if (p.id == pageId) p.copyWith(isActive: !p.isActive) else p,
    ];
  }

  /// Add a new booking (reservation) to a page.
  ///
  /// Called when someone books a time slot on the user's booking page.
  /// New bookings start as unconfirmed.
  void addBooking({
    required String pageId,
    required String bookedByName,
    String? email,
    required DateTime startTime,
    required DateTime endTime,
    String? message,
  }) {
    final booking = BookingSlot(
      id: _uuid.v4(),
      bookingPageId: pageId,
      bookedByName: bookedByName,
      bookedByEmail: email,
      startTime: startTime,
      endTime: endTime,
      message: message,
      isConfirmed: false,
      createdAt: DateTime.now(),
    );

    state = [
      for (final p in state)
        if (p.id == pageId)
          p.copyWith(bookings: [...p.bookings, booking])
        else
          p,
    ];
  }

  /// Confirm a pending booking.
  void confirmBooking(String pageId, String bookingId) {
    state = [
      for (final p in state)
        if (p.id == pageId)
          p.copyWith(
            bookings: [
              for (final b in p.bookings)
                if (b.id == bookingId)
                  b.copyWith(isConfirmed: true)
                else
                  b,
            ],
          )
        else
          p,
    ];
  }

  /// Generate a URL-friendly slug from a title.
  String _generateSlug(String title) {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    final base = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return '$base-$timestamp';
  }
}
