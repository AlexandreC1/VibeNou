import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/app_logger.dart';

/// Client-side rate limiting service
/// Works in conjunction with server-side Firestore rate limiting
class RateLimitService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for rate limit status to reduce Cloud Function calls
  final Map<String, _RateLimitCache> _cache = {};
  static const Duration _cacheValidityDuration = Duration(seconds: 10);

  /// Check if an action is rate limited
  /// Returns true if action is allowed, false if rate limited
  Future<bool> checkRateLimit(String action) async {
    try {
      // Check cache first
      final cached = _cache[action];
      if (cached != null && cached.isValid) {
        return cached.allowed;
      }

      // Call Cloud Function to check rate limit
      final callable = _functions.httpsCallable('checkRateLimit');
      final result = await callable.call({'action': action});

      final data = result.data as Map<String, dynamic>;
      final allowed = data['allowed'] as bool? ?? false;
      final remaining = data['remaining'] as int? ?? 0;
      final resetAt = data['resetAt'] as int? ?? 0;

      // Cache the result
      _cache[action] = _RateLimitCache(
        allowed: allowed,
        remaining: remaining,
        resetAt: resetAt,
        timestamp: DateTime.now(),
      );

      if (!allowed) {
        final resetTime = DateTime.fromMillisecondsSinceEpoch(resetAt);
        final waitTime = resetTime.difference(DateTime.now());
        AppLogger.warning(
          'Rate limit exceeded for $action. Reset in ${waitTime.inSeconds}s',
        );
      }

      return allowed;
    } catch (e) {
      AppLogger.error('Failed to check rate limit', e);
      // Fail open - allow action if rate limit check fails
      // This prevents legitimate users from being blocked by errors
      return true;
    }
  }

  /// Get current rate limit status for an action
  /// Returns usage information (used, limit, remaining, resetAt)
  Future<Map<String, dynamic>?> getRateLimitStatus(String action) async {
    try {
      final callable = _functions.httpsCallable('getRateLimitStatus');
      final result = await callable.call({'action': action});

      return result.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to get rate limit status', e);
      return null;
    }
  }

  /// Execute action with rate limit check
  /// Returns true if action was executed, false if rate limited
  Future<bool> executeWithRateLimit(
    String action,
    Future<void> Function() callback,
  ) async {
    final allowed = await checkRateLimit(action);

    if (!allowed) {
      return false;
    }

    try {
      await callback();
      return true;
    } catch (e) {
      AppLogger.error('Failed to execute rate-limited action', e);
      rethrow;
    }
  }

  /// Show rate limit error to user
  String getRateLimitMessage(String action) {
    final cached = _cache[action];

    if (cached == null || cached.allowed) {
      return '';
    }

    final resetTime = DateTime.fromMillisecondsSinceEpoch(cached.resetAt);
    final waitTime = resetTime.difference(DateTime.now());

    if (waitTime.inMinutes > 0) {
      return 'You\'re sending too many requests. Please wait ${waitTime.inMinutes} minutes.';
    } else {
      return 'You\'re sending too many requests. Please wait ${waitTime.inSeconds} seconds.';
    }
  }

  /// Clear cache (useful for testing or when user changes)
  void clearCache() {
    _cache.clear();
  }

  /// Get human-readable time until rate limit resets
  String? getResetTimeString(String action) {
    final cached = _cache[action];
    if (cached == null) return null;

    final resetTime = DateTime.fromMillisecondsSinceEpoch(cached.resetAt);
    final waitTime = resetTime.difference(DateTime.now());

    if (waitTime.inHours > 0) {
      return '${waitTime.inHours}h ${waitTime.inMinutes % 60}m';
    } else if (waitTime.inMinutes > 0) {
      return '${waitTime.inMinutes}m ${waitTime.inSeconds % 60}s';
    } else {
      return '${waitTime.inSeconds}s';
    }
  }

  /// Display-friendly remaining count
  int getRemainingCount(String action) {
    final cached = _cache[action];
    return cached?.remaining ?? 0;
  }
}

/// Internal cache class for rate limit data
class _RateLimitCache {
  final bool allowed;
  final int remaining;
  final int resetAt;
  final DateTime timestamp;

  _RateLimitCache({
    required this.allowed,
    required this.remaining,
    required this.resetAt,
    required this.timestamp,
  });

  /// Check if cache is still valid
  bool get isValid {
    final age = DateTime.now().difference(timestamp);
    return age < RateLimitService._cacheValidityDuration;
  }
}
