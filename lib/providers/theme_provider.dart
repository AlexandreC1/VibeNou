import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  String? _currentGender;
  ThemeData _currentTheme = AppTheme.lightTheme;

  ThemeData get currentTheme => _currentTheme;
  String? get currentGender => _currentGender;

  // Update theme based on user gender
  void updateTheme(UserModel? user) {
    final newGender = user?.gender;
    if (_currentGender != newGender) {
      _currentGender = newGender;
      _currentTheme = AppTheme.getTheme(newGender);
      notifyListeners();
    }
  }

  // Set theme by gender directly
  void setThemeByGender(String? gender) {
    if (_currentGender != gender) {
      _currentGender = gender;
      _currentTheme = AppTheme.getTheme(gender);
      notifyListeners();
    }
  }

  // Reset to default theme
  void resetTheme() {
    _currentGender = null;
    _currentTheme = AppTheme.lightTheme;
    notifyListeners();
  }
}
