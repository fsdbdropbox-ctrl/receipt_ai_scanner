class AppConstants {
  // API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.receiptscanner.app',
  );
  
  // Limits
  static const int dailyFreeLimit = 5;
  static const int maxFileSizeMB = 10;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
}

