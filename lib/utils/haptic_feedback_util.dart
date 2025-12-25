import 'package:flutter/services.dart';

/// Haptic Feedback Utility
///
/// Provides consistent haptic feedback throughout the app to enhance user experience.
/// Improves perceived responsiveness and creates satisfying micro-interactions.
///
/// Usage psychology:
/// - Light impact: Subtle acknowledgment (checkbox, toggle)
/// - Medium impact: Standard button tap (navigation, actions)
/// - Heavy impact: Important actions (match, like, send message)
/// - Vibrate: Success/failure notifications
class HapticFeedbackUtil {
  /// Light haptic feedback - for subtle interactions
  /// Use for: checkboxes, toggles, switches
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback - for standard button taps
  /// Use for: navigation buttons, form submissions, menu selections
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback - for important actions
  /// Use for: likes, matches, sending messages, important confirmations
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed feedback - for scrolling through options
  /// Use for: picker wheels, dropdown selections
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibration pattern - for notifications and alerts
  /// Use for: success notifications, error alerts
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Success haptic - double light tap
  /// Use for: successful actions (message sent, profile updated)
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error haptic - heavy vibration
  /// Use for: errors, failed actions
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Match haptic - special celebration pattern
  /// Use for: new matches, achievements
  static Future<void> celebration() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Like haptic - satisfying single heavy tap
  /// Use for: liking profiles, adding to favorites
  static Future<void> like() async {
    await HapticFeedback.heavyImpact();
  }
}
