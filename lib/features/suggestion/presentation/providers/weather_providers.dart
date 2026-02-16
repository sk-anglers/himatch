import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Fetches 14-day weather forecast. Auto-disposes after listeners detach.
final weatherForecastProvider =
    FutureProvider.autoDispose<Map<DateTime, WeatherSummary>>((ref) async {
  final service = ref.read(weatherServiceProvider);
  return service.fetchForecast();
});

/// Look up weather for a specific date.
final weatherForDateProvider =
    Provider.family<WeatherSummary?, DateTime>((ref, date) {
  final forecastAsync = ref.watch(weatherForecastProvider);
  return forecastAsync.whenOrNull(
    data: (forecast) {
      final key = DateTime(date.year, date.month, date.day);
      return forecast[key];
    },
  );
});
