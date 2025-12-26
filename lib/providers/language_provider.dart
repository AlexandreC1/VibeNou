import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('preferred_language') ??
                        prefs.getString('language_code') ??
                        'en';
    AppLogger.debug('LanguageProvider: Loading locale from SharedPreferences: $languageCode');
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    AppLogger.debug('LanguageProvider: Setting locale to: $languageCode');
    if (languageCode == _locale.languageCode) {
      AppLogger.debug('LanguageProvider: Locale already set to $languageCode, skipping');
      return;
    }

    _locale = Locale(languageCode);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', languageCode);
    await prefs.setString('language_code', languageCode);
    AppLogger.debug('LanguageProvider: Saved locale to SharedPreferences: $languageCode');

    notifyListeners();
    AppLogger.debug('LanguageProvider: Notified listeners. Current locale: ${_locale.languageCode}');
  }
}
