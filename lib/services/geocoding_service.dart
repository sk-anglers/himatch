import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:himatch/core/constants/app_constants.dart';

/// A single geocoding search result from Open-Meteo.
class GeocodingResult {
  final String name;
  final String? admin1; // Prefecture / state
  final String? country;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  /// Human-readable label, e.g. "大阪 (大阪府, Japan)".
  String get displayName {
    final parts = <String>[name];
    if (admin1 != null && admin1!.isNotEmpty) parts.add(admin1!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }
}

/// Searches for cities using the Open-Meteo Geocoding API (no API key needed).
class GeocodingService {
  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for cities matching [query]. Returns up to 10 results.
  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(AppConstants.geocodingApiUrl).replace(
        queryParameters: {
          'name': query.trim(),
          'count': '10',
          'language': 'ja',
          'format': 'json',
        },
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode >= 400) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;
      if (results == null) return [];

      return results.map((r) {
        final m = r as Map<String, dynamic>;
        return GeocodingResult(
          name: m['name'] as String? ?? '',
          admin1: m['admin1'] as String?,
          country: m['country'] as String?,
          latitude: (m['latitude'] as num).toDouble(),
          longitude: (m['longitude'] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
