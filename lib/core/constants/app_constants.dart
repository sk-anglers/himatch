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
}
