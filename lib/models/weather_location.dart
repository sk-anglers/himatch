/// User's preferred weather location setting.
class WeatherLocation {
  /// If true, use GPS current position. If false, use [latitude]/[longitude].
  final bool useCurrentLocation;
  final double latitude;
  final double longitude;

  /// Display name: '現在地' when GPS, or city name like '大阪'.
  final String name;

  const WeatherLocation({
    this.useCurrentLocation = true,
    this.latitude = 35.6762,
    this.longitude = 139.6503,
    this.name = '現在地',
  });

  WeatherLocation copyWith({
    bool? useCurrentLocation,
    double? latitude,
    double? longitude,
    String? name,
  }) {
    return WeatherLocation(
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherLocation &&
          runtimeType == other.runtimeType &&
          useCurrentLocation == other.useCurrentLocation &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          name == other.name;

  @override
  int get hashCode => Object.hash(useCurrentLocation, latitude, longitude, name);
}
