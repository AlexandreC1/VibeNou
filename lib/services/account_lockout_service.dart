import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import 'audit_log_service.dart';

/// Account lockout service for brute force protection
/// Tracks failed login attempts and locks accounts after threshold
class AccountLockoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuditLogService _auditLog = AuditLogService();

  // Configuration
  static const int MAX_FAILED_ATTEMPTS = 5;
  static const Duration LOCKOUT_DURATION = Duration(minutes: 15);
  static const bool ENABLED = true; // Kill switch for rollback

  /// Check if an email is currently locked out
  Future<LockoutStatus> checkLockout(String email) async {
    if (!ENABLED) {
      return LockoutStatus(isLocked: false, attemptsRemaining: MAX_FAILED_ATTEMPTS);
    }

    try {
      final lockoutDoc = await _firestore
          .collection('accountLockouts')
          .doc(_sanitizeEmail(email))
          .get();

      if (!lockoutDoc.exists) {
        return LockoutStatus(
          isLocked: false,
          attemptsRemaining: MAX_FAILED_ATTEMPTS,
        );
      }

      final data = lockoutDoc.data()!;
      final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();
      final failedAttempts = data['failedAttempts'] as int? ?? 0;

      // Check if lockout has expired
      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        return LockoutStatus(
          isLocked: true,
          lockedUntil: lockedUntil,
          failedAttempts: failedAttempts,
          attemptsRemaining: 0,
        );
      }

      // Lockout expired, return attempts remaining
      return LockoutStatus(
        isLocked: false,
        failedAttempts: failedAttempts,
        attemptsRemaining: MAX_FAILED_ATTEMPTS - failedAttempts,
      );
    } catch (e) {
      AppLogger.error('Error checking lockout status', e);
      // Fail open - don't lock users out if service fails
      return LockoutStatus(isLocked: false, attemptsRemaining: MAX_FAILED_ATTEMPTS);
    }
  }

  /// Record a failed login attempt
  Future<LockoutStatus> recordFailedAttempt(String email) async {
    if (!ENABLED) {
      return LockoutStatus(isLocked: false, attemptsRemaining: MAX_FAILED_ATTEMPTS);
    }

    try {
      final docRef = _firestore
          .collection('accountLockouts')
          .doc(_sanitizeEmail(email));

      // Use transaction to ensure atomic increment
      final lockoutStatus = await _firestore.runTransaction<LockoutStatus>((transaction) async {
        final snapshot = await transaction.get(docRef);

        int failedAttempts = 1;
        DateTime? lockedUntil;

        if (snapshot.exists) {
          final data = snapshot.data()!;
          failedAttempts = (data['failedAttempts'] as int? ?? 0) + 1;

          // Check if already locked
          final existingLockout = (data['lockedUntil'] as Timestamp?)?.toDate();
          if (existingLockout != null && DateTime.now().isBefore(existingLockout)) {
            return LockoutStatus(
              isLocked: true,
              lockedUntil: existingLockout,
              failedAttempts: failedAttempts - 1, // Don't count this attempt
              attemptsRemaining: 0,
            );
          }
        }

        // Lock account if threshold reached
        if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
          lockedUntil = DateTime.now().add(LOCKOUT_DURATION);

          transaction.set(docRef, {
            'email': email,
            'failedAttempts': failedAttempts,
            'lockedUntil': Timestamp.fromDate(lockedUntil),
            'lockedAt': FieldValue.serverTimestamp(),
            'lastAttempt': FieldValue.serverTimestamp(),
          });

          // Log lockout to audit
          _auditLog.logAccountLockout(
            email: email,
            failedAttempts: failedAttempts,
            lockedUntil: lockedUntil,
          );

          AppLogger.warning('Account locked: $email (${failedAttempts} failed attempts)');

          return LockoutStatus(
            isLocked: true,
            lockedUntil: lockedUntil,
            failedAttempts: failedAttempts,
            attemptsRemaining: 0,
          );
        }

        // Update failed attempts
        transaction.set(docRef, {
          'email': email,
          'failedAttempts': failedAttempts,
          'lastAttempt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        AppLogger.warning('Failed login attempt for $email (${failedAttempts}/${MAX_FAILED_ATTEMPTS})');

        return LockoutStatus(
          isLocked: false,
          failedAttempts: failedAttempts,
          attemptsRemaining: MAX_FAILED_ATTEMPTS - failedAttempts,
        );
      });

      return lockoutStatus;
    } catch (e) {
      AppLogger.error('Error recording failed login attempt', e);
      // Fail open
      return LockoutStatus(isLocked: false, attemptsRemaining: MAX_FAILED_ATTEMPTS);
    }
  }

  /// Reset lockout after successful login
  Future<void> resetLockout(String email) async {
    if (!ENABLED) return;

    try {
      await _firestore
          .collection('accountLockouts')
          .doc(_sanitizeEmail(email))
          .delete();

      AppLogger.info('Lockout reset for $email');
    } catch (e) {
      AppLogger.error('Error resetting lockout', e);
      // Don't throw - non-critical
    }
  }

  /// Manually unlock an account (admin function)
  Future<void> unlockAccount(String email) async {
    try {
      await _firestore
          .collection('accountLockouts')
          .doc(_sanitizeEmail(email))
          .delete();

      AppLogger.info('Account manually unlocked: $email');
    } catch (e) {
      AppLogger.error('Error unlocking account', e);
      throw Exception('Failed to unlock account');
    }
  }

  /// Get lockout history for an email
  Future<List<Map<String, dynamic>>> getLockoutHistory(String email) async {
    try {
      final doc = await _firestore
          .collection('accountLockouts')
          .doc(_sanitizeEmail(email))
          .get();

      if (!doc.exists) return [];

      final data = doc.data()!;
      return [
        {
          'failedAttempts': data['failedAttempts'],
          'lockedUntil': (data['lockedUntil'] as Timestamp?)?.toDate(),
          'lockedAt': (data['lockedAt'] as Timestamp?)?.toDate(),
          'lastAttempt': (data['lastAttempt'] as Timestamp?)?.toDate(),
        }
      ];
    } catch (e) {
      AppLogger.error('Error getting lockout history', e);
      return [];
    }
  }

  /// Clean up expired lockouts (called by scheduled job)
  Future<int> cleanupExpiredLockouts() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('accountLockouts')
          .where('lockedUntil', isLessThan: now)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info('Cleaned up ${snapshot.docs.length} expired lockouts');
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('Error cleaning up expired lockouts', e);
      return 0;
    }
  }

  /// Sanitize email for use as document ID (lowercase, trim)
  String _sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}

/// Lockout status result
class LockoutStatus {
  final bool isLocked;
  final DateTime? lockedUntil;
  final int failedAttempts;
  final int attemptsRemaining;

  LockoutStatus({
    required this.isLocked,
    this.lockedUntil,
    this.failedAttempts = 0,
    required this.attemptsRemaining,
  });

  /// Get human-readable lockout message
  String getMessage() {
    if (isLocked && lockedUntil != null) {
      final duration = lockedUntil!.difference(DateTime.now());
      final minutes = duration.inMinutes;

      if (minutes > 0) {
        return 'Account locked. Try again in $minutes minute${minutes != 1 ? 's' : ''}.';
      } else {
        return 'Account locked. Please try again shortly.';
      }
    }

    if (attemptsRemaining <= 2 && attemptsRemaining > 0) {
      return '$attemptsRemaining attempt${attemptsRemaining != 1 ? 's' : ''} remaining before lockout.';
    }

    return '';
  }

  @override
  String toString() {
    return 'LockoutStatus(isLocked: $isLocked, lockedUntil: $lockedUntil, '
        'failedAttempts: $failedAttempts, attemptsRemaining: $attemptsRemaining)';
  }
}
