import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locale with browser detection + manual override
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const List<Locale> supportedLocales = [
    Locale('es'), // Spanish first (ES-first strategy)
    Locale('en'), // English
  ];
  
  Locale? _locale;
  bool _initialized = false;
  
  Locale? get locale => _locale;
  bool get initialized => _initialized;
  
  /// Get the current locale or system default
  Locale get currentLocale {
    if (_locale != null) return _locale!;
    return supportedLocales.first; // Default to Spanish
  }
  
  /// Initialize locale from preferences or system
  Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    
    if (savedLocale != null) {
      // User has manually selected a locale
      _locale = Locale(savedLocale);
    }
    // If no saved preference, _locale stays null and system locale will be used
    
    _initialized = true;
    notifyListeners();
  }
  
  /// Set locale manually (user preference)
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    
    _locale = locale;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    
    notifyListeners();
  }
  
  /// Clear manual preference (use system locale)
  Future<void> clearLocale() async {
    _locale = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    
    notifyListeners();
  }
  
  /// Check if current language is Spanish
  bool isSpanish(BuildContext context) {
    if (_locale != null) {
      return _locale!.languageCode == 'es';
    }
    // Try to get system locale, but handle cases where it's not available yet
    try {
      final systemLocale = Localizations.localeOf(context);
      return systemLocale.languageCode == 'es';
    } catch (_) {
      // Fallback to default (Spanish-first strategy)
      return true;
    }
  }
  
  /// Locale resolution callback for MaterialApp
  static Locale? localeResolutionCallback(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale == null) return supportedLocales.first;
    
    // Check if device locale is supported
    for (final locale in supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode) {
        return locale;
      }
    }
    
    // Default to Spanish (ES-first strategy)
    return supportedLocales.first;
  }
}

