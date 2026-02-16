import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:himatch/core/constants/app_constants.dart';
import 'package:himatch/models/suggestion.dart';

/// Fetches weather forecasts from Open-Meteo API.
///
/// Returns a map of date → WeatherSummary for the next 14 days.
/// Uses an in-memory cache to avoid redundant API calls within 1 hour.
class WeatherService {
  final http.Client _client;

  Map<DateTime, WeatherSummary>? _cache;
  DateTime? _cacheTime;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch 14-day weather forecast. Returns empty map on failure.
  Future<Map<DateTime, WeatherSummary>> fetchForecast({
    double latitude = AppConstants.defaultLatitude,
    double longitude = AppConstants.defaultLongitude,
  }) async {
    // Return cache if still valid
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) <
            AppConstants.weatherCacheDuration) {
      return _cache!;
    }

    try {
      final uri = Uri.parse(AppConstants.weatherApiUrl).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
          'timezone': AppConstants.defaultTimezone,
          'forecast_days': AppConstants.weatherForecastDays.toString(),
        },
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode >= 400) {
        // 4xx: client error (bad request, rate limited)
        // 5xx: server error (retry later)
        // Either way, return stale cache or empty
        return _cache ?? {};
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>?;

      if (daily == null) return _cache ?? {};

      final dates = (daily['time'] as List).cast<String>();
      final weatherCodes = (daily['weather_code'] as List).cast<num>();
      final tempMaxes = (daily['temperature_2m_max'] as List).cast<num>();
      final tempMins = (daily['temperature_2m_min'] as List).cast<num>();

      final result = <DateTime, WeatherSummary>{};

      for (int i = 0; i < dates.length; i++) {
        final dateParts = dates[i].split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );

        final code = weatherCodes[i].toInt();
        final wmo = AppConstants.wmoWeatherCodes[code] ??
            AppConstants.wmoWeatherCodes[0]!;

        result[date] = WeatherSummary(
          condition: wmo.condition,
          tempHigh: tempMaxes[i].toDouble(),
          tempLow: tempMins[i].toDouble(),
          icon: wmo.icon,
        );
      }

      _cache = result;
      _cacheTime = DateTime.now();
      return result;
    } on TimeoutException {
      // Network timeout: return stale cache if available
      return _cache ?? {};
    } on FormatException {
      // JSON parse error: API response was malformed
      return _cache ?? {};
    } catch (_) {
      // Other errors (network down, etc.): graceful degradation
      return _cache ?? {};
    }
  }

  /// Invalidate cache to force next fetch.
  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
