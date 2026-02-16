import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/services/holiday_service.dart';

final holidayServiceProvider = Provider<JapaneseHolidayService>((ref) {
  return JapaneseHolidayService();
});

/// Look up holiday name for a specific date. Returns null if not a holiday.
final holidayForDateProvider =
    Provider.family<String?, DateTime>((ref, date) {
  final service = ref.read(holidayServiceProvider);
  return service.getHoliday(date);
});
