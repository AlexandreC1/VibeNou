import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Custom notification sound service for VibeNou
///
/// Provides unique, sexy notification sounds:
/// - 'meow': Cute cat-like meow sound
/// - 'purr': Sultry purring sound
/// - 'kiss': Kissing sound effect
/// - 'whisper': Soft whisper notification
/// - 'chime': Elegant romantic chime
/// - 'default': Standard notification
class CustomNotificationSoundService {
  static final CustomNotificationSoundService _instance = CustomNotificationSoundService._internal();
  factory CustomNotificationSoundService() => _instance;
  CustomNotificationSoundService._internal();

  static const MethodChannel _platform = MethodChannel('com.vibenou/notification_sounds');

  // Available notification sounds
  static const Map<String, String> availableSounds = {
    'meow': 'Cute Meow',
    'purr': 'Sultry Purr',
    'kiss': 'Kiss',
    'whisper': 'Whisper',
    'chime': 'Romantic Chime',
    'heartbeat': 'Heartbeat',
    'default': 'Default',
  };

  // Sound descriptions for UI
  static const Map<String, String> soundDescriptions = {
    'meow': 'Playful cat meow - cute and attention-grabbing',
    'purr': 'Sultry purring - smooth and seductive',
    'kiss': 'Sweet kiss sound - romantic and intimate',
    'whisper': 'Soft whisper - mysterious and alluring',
    'chime': 'Elegant chime - sophisticated and romantic',
    'heartbeat': 'Heart beating - passionate and exciting',
    'default': 'Standard notification sound',
  };

  // Storage key for user preference
  static const String _prefsKey = 'notification_sound_preference';

  /// Get current notification sound preference
  Future<String> getCurrentSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey) ?? 'purr'; // Default to sultry purr
    } catch (e) {
      AppLogger.error('Failed to get current sound', e);
      return 'purr';
    }
  }

  /// Set notification sound preference
  Future<void> setNotificationSound(String soundName) async {
    try {
      if (!availableSounds.containsKey(soundName)) {
        throw Exception('Invalid sound name: $soundName');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, soundName);

      // Update native notification channels
      await _updateNativeSound(soundName);

      AppLogger.info('Notification sound set to: $soundName');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set notification sound', e, stackTrace);
      rethrow;
    }
  }

  /// Update native platform notification sound
  Future<void> _updateNativeSound(String soundName) async {
    try {
      await _platform.invokeMethod('updateNotificationSound', {
        'soundName': soundName,
      });
      AppLogger.info('Native notification sound updated');
    } on PlatformException catch (e) {
      AppLogger.error('Failed to update native sound: ${e.message}', e);
      // Don't rethrow - preference is still saved
    }
  }

  /// Play sound preview
  Future<void> previewSound(String soundName) async {
    try {
      if (!availableSounds.containsKey(soundName)) {
        throw Exception('Invalid sound name: $soundName');
      }

      await _platform.invokeMethod('playSound', {
        'soundName': soundName,
      });

      AppLogger.info('Playing sound preview: $soundName');
    } on PlatformException catch (e) {
      AppLogger.error('Failed to play sound preview: ${e.message}', e);
      rethrow;
    }
  }

  /// Initialize notification sound on app startup
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing custom notification sounds');

      final currentSound = await getCurrentSound();
      await _updateNativeSound(currentSound);

      AppLogger.info('Notification sounds initialized with: $currentSound');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize notification sounds', e, stackTrace);
    }
  }

  /// Get sound file name for native code
  static String getSoundFileName(String soundName) {
    // Maps to actual file names (without extension)
    return soundName;
  }

  /// Create notification with custom sound
  Future<Map<String, dynamic>> createNotificationPayload({
    required String title,
    required String body,
    String? soundOverride,
    Map<String, dynamic>? data,
  }) async {
    final soundName = soundOverride ?? await getCurrentSound();

    return {
      'title': title,
      'body': body,
      'sound': getSoundFileName(soundName),
      'data': data ?? {},
    };
  }

  /// Get all available sounds for UI picker
  static List<Map<String, String>> getAllSounds() {
    return availableSounds.entries.map((entry) {
      return {
        'id': entry.key,
        'name': entry.value,
        'description': soundDescriptions[entry.key] ?? '',
      };
    }).toList();
  }

  /// Reset to default sound
  Future<void> resetToDefault() async {
    await setNotificationSound('purr');
  }
}
