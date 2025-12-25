import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Error telemetry service using Firebase Crashlytics
/// Tracks crashes, errors, and user context for debugging
class ErrorTelemetryService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics and set up error handlers
  static Future<void> initialize() async {
    try {
      // Enable Crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Pass Flutter errors to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
        AppLogger.error('Flutter Error', details.exception, details.stack);
      };

      // Pass Dart errors outside of Flutter to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        AppLogger.error('Platform Error', error, stack);
        return true;
      };

      AppLogger.info('Crashlytics initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize Crashlytics', e);
      // Don't throw - telemetry failures shouldn't break app
    }
  }

  /// Set user identifier for crash reports
  /// Use user ID, not email, to protect privacy
  static Future<void> setUser(String userId, {String? email}) async {
    try {
      await _crashlytics.setUserIdentifier(userId);

      if (email != null) {
        await _crashlytics.setCustomKey('user_email', email);
      }

      AppLogger.info('Crashlytics user set: $userId');
    } catch (e) {
      AppLogger.error('Failed to set Crashlytics user', e);
    }
  }

  /// Clear user identifier on logout
  static Future<void> clearUser() async {
    try {
      await _crashlytics.setUserIdentifier('');
      await _crashlytics.setCustomKey('user_email', '');
      AppLogger.info('Crashlytics user cleared');
    } catch (e) {
      AppLogger.error('Failed to clear Crashlytics user', e);
    }
  }

  /// Log a non-fatal error
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Add context as custom keys
      if (context != null) {
        for (final entry in context.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Add reason if provided
      if (reason != null) {
        await _crashlytics.setCustomKey('error_reason', reason);
      }

      // Record the error
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );

      AppLogger.error('Logged to Crashlytics: $reason', error, stackTrace);
    } catch (e) {
      AppLogger.error('Failed to log error to Crashlytics', e);
    }
  }

  /// Log a message (breadcrumb) for debugging
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      AppLogger.error('Failed to log message to Crashlytics', e);
    }
  }

  /// Set custom key-value pairs for context
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value.toString());
    } catch (e) {
      AppLogger.error('Failed to set custom key', e);
    }
  }

  /// Set multiple custom keys at once
  static Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      for (final entry in keys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
    } catch (e) {
      AppLogger.error('Failed to set custom keys', e);
    }
  }

  /// Log authentication errors
  static Future<void> logAuthError(
    String operation,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKey('error_category', 'authentication');
    await setCustomKey('auth_operation', operation);
    await logError(
      error,
      stackTrace,
      reason: 'Authentication error: $operation',
      context: {
        'category': 'authentication',
        'operation': operation,
      },
    );
  }

  /// Log network errors
  static Future<void> logNetworkError(
    String endpoint,
    int? statusCode,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKeys({
      'error_category': 'network',
      'endpoint': endpoint,
      if (statusCode != null) 'status_code': statusCode,
    });
    await logError(
      error,
      stackTrace,
      reason: 'Network error: $endpoint',
      context: {
        'category': 'network',
        'endpoint': endpoint,
        if (statusCode != null) 'statusCode': statusCode,
      },
    );
  }

  /// Log encryption/decryption errors
  static Future<void> logEncryptionError(
    String operation,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKeys({
      'error_category': 'encryption',
      'encryption_operation': operation,
    });
    await logError(
      error,
      stackTrace,
      fatal: true, // Encryption failures are critical
      reason: 'Encryption error: $operation',
      context: {
        'category': 'encryption',
        'operation': operation,
      },
    );
  }

  /// Log database errors
  static Future<void> logDatabaseError(
    String operation,
    String collection,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKeys({
      'error_category': 'database',
      'db_operation': operation,
      'db_collection': collection,
    });
    await logError(
      error,
      stackTrace,
      reason: 'Database error: $operation on $collection',
      context: {
        'category': 'database',
        'operation': operation,
        'collection': collection,
      },
    );
  }

  /// Log UI errors
  static Future<void> logUIError(
    String screen,
    String widget,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await setCustomKeys({
      'error_category': 'ui',
      'screen': screen,
      'widget': widget,
    });
    await logError(
      error,
      stackTrace,
      reason: 'UI error: $widget on $screen',
      context: {
        'category': 'ui',
        'screen': screen,
        'widget': widget,
      },
    );
  }

  /// Test crash reporting (only use in development)
  static Future<void> testCrash() async {
    if (kDebugMode) {
      _crashlytics.crash();
    } else {
      AppLogger.warning('testCrash() only works in debug mode');
    }
  }

  /// Check if crash reporting is enabled
  static Future<bool> isEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable crash collection
  static Future<void> setEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      AppLogger.info('Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      AppLogger.error('Failed to set Crashlytics enabled state', e);
    }
  }
}
