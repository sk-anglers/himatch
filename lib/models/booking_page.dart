import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_page.freezed.dart';
part 'booking_page.g.dart';

@freezed
abstract class BookingSlot with _$BookingSlot {
  const factory BookingSlot({
    required String id,
    @JsonKey(name: 'booking_page_id') required String bookingPageId,
    @JsonKey(name: 'booked_by_name') required String bookedByName,
    @JsonKey(name: 'booked_by_email') String? bookedByEmail,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    String? message,
    @JsonKey(name: 'is_confirmed') @Default(false) bool isConfirmed,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _BookingSlot;

  factory BookingSlot.fromJson(Map<String, dynamic> json) =>
      _$BookingSlotFromJson(json);
}

@freezed
abstract class BookingPage with _$BookingPage {
  const factory BookingPage({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    String? description,
    @JsonKey(name: 'slug') required String slug,
    @JsonKey(name: 'duration_minutes') @Default(60) int durationMinutes,
    @JsonKey(name: 'buffer_minutes') @Default(15) int bufferMinutes,
    @JsonKey(name: 'max_bookings_per_day') @Default(5) int maxBookingsPerDay,
    @JsonKey(name: 'available_hours_start') @Default('09:00') String availableHoursStart,
    @JsonKey(name: 'available_hours_end') @Default('18:00') String availableHoursEnd,
    @JsonKey(name: 'available_days') @Default([1, 2, 3, 4, 5]) List<int> availableDays,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @Default([]) List<BookingSlot> bookings,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _BookingPage;

  factory BookingPage.fromJson(Map<String, dynamic> json) =>
      _$BookingPageFromJson(json);
}
