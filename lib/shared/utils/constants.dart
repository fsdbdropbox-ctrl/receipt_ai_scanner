class AppConstants {
  // API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://receiptaiscanner-production.up.railway.app',
  );
  
  // Monitoring
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
  
  // Limits
  static const int dailyFreeLimit = 5;
  static const int maxFileSizeMB = 10;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
}

