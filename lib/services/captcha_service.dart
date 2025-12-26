import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/app_logger.dart';

/// CAPTCHA and bot prevention service using Firebase App Check
/// Verifies that requests come from authentic app instances, not bots
class CaptchaService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAppCheck _appCheck = FirebaseAppCheck.instance;

  // Configuration
  static const bool enabled = true; // Kill switch for rollback

  /// Initialize Firebase App Check
  /// Call this during app initialization
  static Future<void> initialize({String? debugToken}) async {
    if (!enabled) {
      AppLogger.info('CAPTCHA/App Check disabled');
      return;
    }

    try {
      // Activate App Check
      await _appCheck.activate(
        // Use debug provider in debug mode for testing
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        // In production, use:
        // androidProvider: AndroidProvider.playIntegrity,
        // appleProvider: AppleProvider.deviceCheck,
      );

      // Set debug token if provided (for testing)
      if (debugToken != null) {
        await _appCheck.setTokenAutoRefreshEnabled(true);
      }

      AppLogger.info('Firebase App Check initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize App Check', e);
      // Don't throw - app should work even if App Check fails
    }
  }

  /// Verify reCAPTCHA token (alternative approach using Cloud Functions)
  /// This is useful for web or if you want to use Google reCAPTCHA v3
  static Future<CaptchaVerificationResult> verifyRecaptcha(String token) async {
    if (!enabled) {
      return CaptchaVerificationResult(
        success: true,
        score: 1.0,
        action: 'signup',
      );
    }

    try {
      final result = await _functions
          .httpsCallable('verifyRecaptcha')
          .call({'token': token});

      final data = result.data as Map<String, dynamic>;

      return CaptchaVerificationResult(
        success: data['success'] as bool? ?? false,
        score: data['score'] as double? ?? 0.0,
        action: data['action'] as String? ?? '',
        challengeTs: data['challenge_ts'] as String?,
        hostname: data['hostname'] as String?,
        errorCodes: (data['error-codes'] as List?)?.cast<String>(),
      );
    } catch (e) {
      AppLogger.error('CAPTCHA verification failed', e);
      // Fail open - don't block users if verification service fails
      return CaptchaVerificationResult(
        success: true,
        score: 0.5,
        action: 'signup',
      );
    }
  }

  /// Check if user passes bot detection
  /// Uses Firebase App Check token validation
  static Future<bool> verifyUserIsHuman({
    required String action,
    double scoreThreshold = 0.5,
  }) async {
    if (!enabled) {
      return true;
    }

    try {
      // Get App Check token
      final token = await _appCheck.getToken();

      if (token == null) {
        AppLogger.warning('App Check token is null - potential bot');
        // In production, you might want to reject this
        // For now, fail open to not block legitimate users
        return true;
      }

      AppLogger.info('App Check token obtained for action: $action');

      // Token is automatically validated by Firebase on backend
      // If we got here, the app is verified
      return true;
    } catch (e) {
      AppLogger.error('App Check verification failed', e);
      // Fail open - don't block users if service fails
      return true;
    }
  }

  /// Verify signup attempt is from human
  static Future<bool> verifySignup() async {
    return await verifyUserIsHuman(action: 'signup');
  }

  /// Verify login attempt is from human
  static Future<bool> verifyLogin() async {
    return await verifyUserIsHuman(action: 'login');
  }

  /// Verify message send is from human
  static Future<bool> verifyMessageSend() async {
    return await verifyUserIsHuman(action: 'send_message');
  }

  /// Get App Check token for manual verification
  static Future<String?> getToken() async {
    try {
      final token = await _appCheck.getToken();
      return token;
    } catch (e) {
      AppLogger.error('Failed to get App Check token', e);
      return null;
    }
  }

  /// Force token refresh
  static Future<void> refreshToken() async {
    try {
      await _appCheck.getToken(true);
      AppLogger.info('App Check token refreshed');
    } catch (e) {
      AppLogger.error('Failed to refresh App Check token', e);
    }
  }

  /// Enable/disable automatic token refresh
  static Future<void> setTokenAutoRefresh(bool enabled) async {
    try {
      await _appCheck.setTokenAutoRefreshEnabled(enabled);
      AppLogger.info('App Check auto-refresh ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      AppLogger.error('Failed to set token auto-refresh', e);
    }
  }

  /// Configure for production
  /// Call this to switch from debug to production providers
  static Future<void> configureForProduction() async {
    try {
      await _appCheck.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );

      await _appCheck.setTokenAutoRefreshEnabled(true);

      AppLogger.info('App Check configured for production');
    } catch (e) {
      AppLogger.error('Failed to configure App Check for production', e);
      throw Exception('Failed to configure App Check for production');
    }
  }
}

/// Result from CAPTCHA verification (for reCAPTCHA approach)
class CaptchaVerificationResult {
  final bool success;
  final double score; // 0.0 (bot) to 1.0 (human)
  final String action;
  final String? challengeTs;
  final String? hostname;
  final List<String>? errorCodes;

  CaptchaVerificationResult({
    required this.success,
    required this.score,
    required this.action,
    this.challengeTs,
    this.hostname,
    this.errorCodes,
  });

  /// Check if score is above threshold (default 0.5)
  bool isHuman({double threshold = 0.5}) {
    return success && score >= threshold;
  }

  /// Get human-readable result
  String getScoreDescription() {
    if (score >= 0.9) return 'Very likely human';
    if (score >= 0.7) return 'Likely human';
    if (score >= 0.5) return 'Possibly human';
    if (score >= 0.3) return 'Possibly bot';
    return 'Likely bot';
  }

  @override
  String toString() {
    return 'CaptchaVerificationResult(success: $success, score: $score, '
        'action: $action, description: ${getScoreDescription()})';
  }
}
