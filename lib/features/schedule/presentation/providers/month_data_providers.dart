import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/features/suggestion/presentation/providers/weather_providers.dart';
import 'package:himatch/providers/holiday_providers.dart';

/// Pre-built weather map for an entire month, keyed by date-only DateTime.
/// Calendar cells do a simple Map lookup instead of creating individual
/// .family provider instances per cell.
final monthWeatherProvider =
    Provider.autoDispose.family<Map<DateTime, WeatherSummary>, DateTime>(
  (ref, month) {
    final forecastAsync = ref.watch(weatherForecastProvider);
    return forecastAsync.whenOrNull(data: (forecast) => forecast) ?? {};
  },
);

/// Pre-built holiday map for an entire month, keyed by date-only DateTime.
final monthHolidayProvider =
    Provider.autoDispose.family<Map<DateTime, String>, DateTime>(
  (ref, month) {
    final service = ref.read(holidayServiceProvider);
    final result = <DateTime, String>{};
    // Cover 6 weeks to handle overflow days shown in the calendar
    final start = DateTime(month.year, month.month, 1).subtract(const Duration(days: 7));
    final end = DateTime(month.year, month.month + 1, 0).add(const Duration(days: 14));
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = DateTime(d.year, d.month, d.day);
      final name = service.getHoliday(key);
      if (name != null) {
        result[key] = name;
      }
    }
    return result;
  },
);
