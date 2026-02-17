import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:himatch/models/suggestion.dart';
import 'package:himatch/services/weather_service.dart';
import 'package:himatch/features/profile/presentation/providers/location_providers.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Fetches 14-day weather forecast using the user's configured location.
final weatherForecastProvider =
    FutureProvider.autoDispose<Map<DateTime, WeatherSummary>>((ref) async {
  final service = ref.read(weatherServiceProvider);
  final coords = await ref.watch(resolvedWeatherCoordsProvider.future);
  return service.fetchForecast(
    latitude: coords.latitude,
    longitude: coords.longitude,
  );
});

/// Look up weather for a specific date.
final weatherForDateProvider =
    Provider.autoDispose.family<WeatherSummary?, DateTime>((ref, date) {
  final forecastAsync = ref.watch(weatherForecastProvider);
  return forecastAsync.whenOrNull(
    data: (forecast) {
      final key = DateTime(date.year, date.month, date.day);
      return forecast[key];
    },
  );
});
