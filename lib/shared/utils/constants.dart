class AppConstants {
  // App Info
  static const String appName = 'ReceiptData';
  static const String appTagline = 'Scan → Extract → Export';
  static const String domain = 'receiptdata.app';
  static const String websiteUrl = 'https://receiptdata.app';
  static const String privacyUrl = 'https://receiptdata.app/privacy';
  static const String termsUrl = 'https://receiptdata.app/terms';
  static const String supportEmail = 'support@receiptdata.app';
  
  // API
  // Using Railway domain directly until custom domain SSL is ready
  // TODO: Change back to https://api.receiptdata.app when DNS fully propagates
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
  static const int monthlyPremiumLimit = 1000;
  static const int maxFileSizeMB = 10;
  
  // Pricing
  static const double premiumPriceUSD = 9.99;
  static const int trialDays = 7;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
}
