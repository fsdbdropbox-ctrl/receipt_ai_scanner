import 'package:flutter/material.dart';

/// Safe helper for getting locale that won't crash on startup
class LocaleHelper {
  /// Safely get locale string, defaulting to 'es' if not available
  static String getLocaleString(BuildContext context) {
    try {
      return Localizations.localeOf(context).toString();
    } catch (_) {
      return 'es'; // Default to Spanish
    }
  }

  /// Safely check if current locale is Spanish
  static bool isSpanish(BuildContext context) {
    return getLocaleString(context).startsWith('es');
  }
}

