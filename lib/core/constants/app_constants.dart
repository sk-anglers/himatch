abstract class AppConstants {
  static const String appName = 'Himatch';
  static const String appNameJa = 'ヒマッチ';

  // Supabase (values loaded from environment)
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  // Suggestion engine
  static const int minGroupMembers = 2;
  static const int maxSuggestionDays = 30;
  static const int defaultSearchRangeDays = 14;

  // Context classification thresholds (hours)
  static const double allDayThreshold = 8.0;
  static const double halfDayThreshold = 4.0;
  static const double eveningStartHour = 18.0;
  static const double lunchStartHour = 11.0;
  static const double lunchEndHour = 14.0;

  // Weather (Open-Meteo)
  static const String weatherApiUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const String geocodingApiUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const double defaultLatitude = 35.6762; // Tokyo
  static const double defaultLongitude = 139.6503;
  static const String defaultTimezone = 'Asia/Tokyo';
  static const int weatherForecastDays = 14;
  static const Duration weatherCacheDuration = Duration(hours: 1);

  /// WMO weather code → (condition, icon) mapping.
  static const Map<int, ({String condition, String icon})> wmoWeatherCodes = {
    0: (condition: '快晴', icon: '☀️'),
    1: (condition: '晴れ', icon: '🌤️'),
    2: (condition: '曇りがち', icon: '⛅'),
    3: (condition: 'くもり', icon: '☁️'),
    45: (condition: '霧', icon: '🌫️'),
    48: (condition: '霧氷', icon: '🌫️'),
    51: (condition: '弱い霧雨', icon: '🌧️'),
    53: (condition: '霧雨', icon: '🌧️'),
    55: (condition: '強い霧雨', icon: '🌧️'),
    56: (condition: '着氷性霧雨', icon: '🌧️'),
    57: (condition: '強い着氷性霧雨', icon: '🌧️'),
    61: (condition: '弱い雨', icon: '🌧️'),
    63: (condition: '雨', icon: '🌧️'),
    65: (condition: '強い雨', icon: '🌧️'),
    66: (condition: '着氷性の雨', icon: '🌧️'),
    67: (condition: '強い着氷性の雨', icon: '🌧️'),
    71: (condition: '弱い雪', icon: '❄️'),
    73: (condition: '雪', icon: '❄️'),
    75: (condition: '強い雪', icon: '❄️'),
    77: (condition: '霧雪', icon: '❄️'),
    80: (condition: 'にわか雨', icon: '🌦️'),
    81: (condition: '強いにわか雨', icon: '🌦️'),
    82: (condition: '激しいにわか雨', icon: '🌦️'),
    85: (condition: 'にわか雪', icon: '❄️'),
    86: (condition: '強いにわか雪', icon: '❄️'),
    95: (condition: '雷雨', icon: '⛈️'),
    96: (condition: '雹を伴う雷雨', icon: '⛈️'),
    99: (condition: '強い雹雷雨', icon: '⛈️'),
  };
}
