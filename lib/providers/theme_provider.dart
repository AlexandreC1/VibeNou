import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

/// ThemeProvider - Manages app theming including dark mode and gender-based themes
///
/// Features:
/// - Light/Dark/System theme modes
/// - Gender-based color schemes (pink for female, blue for male)
/// - Persistent theme preference storage
/// - Automatic system theme detection
///
/// Last updated: 2026-03-24
class ThemeProvider with ChangeNotifier {
  String? _currentGender;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeData _lightTheme = AppTheme.lightTheme;
  ThemeData _darkTheme = AppTheme.darkTheme;

  static const String _themeModeKey = 'theme_mode';

  ThemeProvider() {
    _loadThemePreference();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  String? get currentGender => _currentGender;

  /// Get current theme based on theme mode
  /// This is what MaterialApp.theme should use
  ThemeData get currentTheme => _lightTheme;

  /// Get dark theme
  /// This is what MaterialApp.darkTheme should use
  ThemeData get currentDarkTheme => _darkTheme;

  /// Check if dark mode is currently active
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // For system mode, we can't determine here - MaterialApp handles it
    return false;
  }

  /// Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        switch (themeModeString) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default (system)
      debugPrint('Failed to load theme preference: $e');
    }
  }

  /// Save theme preference to storage
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;

      switch (_themeMode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        case ThemeMode.system:
          themeModeString = 'system';
          break;
      }

      await prefs.setString(_themeModeKey, themeModeString);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Set theme mode (light, dark, or system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemePreference();
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Update theme based on user gender
  void updateTheme(UserModel? user) {
    final newGender = user?.gender;
    if (_currentGender != newGender) {
      _currentGender = newGender;
      _lightTheme = AppTheme.getTheme(newGender);
      _darkTheme = AppTheme.getDarkTheme(newGender);
      notifyListeners();
    }
  }

  /// Set theme by gender directly
  void setThemeByGender(String? gender) {
    if (_currentGender != gender) {
      _currentGender = gender;
      _lightTheme = AppTheme.getTheme(gender);
      _darkTheme = AppTheme.getDarkTheme(gender);
      notifyListeners();
    }
  }

  /// Reset to default theme
  Future<void> resetTheme() async {
    _currentGender = null;
    _lightTheme = AppTheme.lightTheme;
    _darkTheme = AppTheme.darkTheme;
    _themeMode = ThemeMode.system;
    await _saveThemePreference();
    notifyListeners();
  }

  /// Get current theme mode as string (for UI display)
  String get currentThemeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme mode icon
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
