import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:himatch/core/constants/app_constants.dart';
import 'package:himatch/features/auth/providers/auth_providers.dart';
import 'package:himatch/models/weather_location.dart';
import 'package:himatch/services/geocoding_service.dart';

/// The user's weather location preference.
final weatherLocationProvider =
    NotifierProvider<WeatherLocationNotifier, WeatherLocation>(
  WeatherLocationNotifier.new,
);

class WeatherLocationNotifier extends Notifier<WeatherLocation> {
  @override
  WeatherLocation build() {
    final authState = ref.watch(authNotifierProvider);
    if (authState.isDemo) {
      return const WeatherLocation(
        useCurrentLocation: false,
        latitude: AppConstants.demoLatitude,
        longitude: AppConstants.demoLongitude,
        name: '福岡市',
      );
    }
    return const WeatherLocation();
  }

  /// Switch to GPS-based location.
  void useCurrentLocation() {
    state = const WeatherLocation(useCurrentLocation: true, name: '現在地');
  }

  /// Set a specific city.
  void setCity(String name, double latitude, double longitude) {
    state = WeatherLocation(
      useCurrentLocation: false,
      latitude: latitude,
      longitude: longitude,
      name: name,
    );
  }
}

/// Resolves the actual coordinates to use for weather fetching.
/// GPS mode → Geolocator; city mode → stored coords; GPS failure → Tokyo.
final resolvedWeatherCoordsProvider =
    FutureProvider<({double latitude, double longitude})>((ref) async {
  final location = ref.watch(weatherLocationProvider);

  if (!location.useCurrentLocation) {
    return (latitude: location.latitude, longitude: location.longitude);
  }

  // GPS mode
  try {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
      );
    }

    // Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return (
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
      );
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
        );
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  } catch (_) {
    // Fallback to Tokyo on any GPS error
    return (
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
    );
  }
});

/// Geocoding service provider.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});
