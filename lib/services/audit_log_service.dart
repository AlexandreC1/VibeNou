import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// Audit logging service for tracking security-sensitive events
/// Helps with security monitoring, incident response, and compliance
class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log a security event
  /// Stores in both user-specific and global audit logs
  Future<void> log({
    required String eventType,
    required String severity, // 'info', 'warning', 'critical'
    required String description,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      final effectiveUserId = userId ?? user?.uid;

      if (effectiveUserId == null) {
        AppLogger.warning('Audit log without user ID: $eventType');
        return;
      }

      final logData = {
        'userId': effectiveUserId,
        'eventType': eventType,
        'severity': severity,
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user?.email,
      };

      // Store in user's audit log
      await _firestore
          .collection('auditLogs')
          .doc(effectiveUserId)
          .collection('events')
          .add(logData);

      // Store critical events in global audit log
      if (severity == 'critical' || severity == 'warning') {
        await _firestore.collection('globalAuditLogs').add(logData);
      }

      AppLogger.info('Audit log: $eventType ($severity)');
    } catch (e) {
      AppLogger.error('Failed to write audit log', e);
      // Don't throw - audit logging failures shouldn't break app
    }
  }

  /// Log successful login
  Future<void> logLoginSuccess({
    required String userId,
    String? method,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      eventType: 'login_success',
      severity: 'info',
      description: 'User logged in successfully',
      userId: userId,
      metadata: {
        'method': method ?? 'email',
        ...?metadata,
      },
    );
  }

  /// Log failed login attempt
  Future<void> logLoginFailure({
    required String email,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      eventType: 'login_failure',
      severity: 'warning',
      description: 'Failed login attempt',
      metadata: {
        'email': email,
        'reason': reason,
        ...?metadata,
      },
    );
  }

  /// Log logout
  Future<void> logLogout({
    required String userId,
  }) async {
    await log(
      eventType: 'logout',
      severity: 'info',
      description: 'User logged out',
      userId: userId,
    );
  }

  /// Log password change
  Future<void> logPasswordChange({
    required String userId,
  }) async {
    await log(
      eventType: 'password_changed',
      severity: 'warning',
      description: 'User changed their password',
      userId: userId,
    );
  }

  /// Log email change
  Future<void> logEmailChange({
    required String userId,
    required String oldEmail,
    required String newEmail,
  }) async {
    await log(
      eventType: 'email_changed',
      severity: 'critical',
      description: 'User changed their email address',
      userId: userId,
      metadata: {
        'oldEmail': oldEmail,
        'newEmail': newEmail,
      },
    );
  }

  /// Log 2FA enabled
  Future<void> log2FAEnabled({
    required String userId,
  }) async {
    await log(
      eventType: 'two_factor_enabled',
      severity: 'info',
      description: 'User enabled two-factor authentication',
      userId: userId,
    );
  }

  /// Log 2FA disabled
  Future<void> log2FADisabled({
    required String userId,
  }) async {
    await log(
      eventType: 'two_factor_disabled',
      severity: 'warning',
      description: 'User disabled two-factor authentication',
      userId: userId,
    );
  }

  /// Log profile photo change
  Future<void> logProfilePhotoChange({
    required String userId,
  }) async {
    await log(
      eventType: 'profile_photo_changed',
      severity: 'info',
      description: 'User changed their profile photo',
      userId: userId,
    );
  }

  /// Log account deletion
  Future<void> logAccountDeletion({
    required String userId,
    String? reason,
  }) async {
    await log(
      eventType: 'account_deleted',
      severity: 'critical',
      description: 'User deleted their account',
      userId: userId,
      metadata: {
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Log user blocked
  Future<void> logUserBlocked({
    required String userId,
    required String blockedUserId,
    String? reason,
  }) async {
    await log(
      eventType: 'user_blocked',
      severity: 'info',
      description: 'User blocked another user',
      userId: userId,
      metadata: {
        'blockedUserId': blockedUserId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Log user reported
  Future<void> logUserReported({
    required String userId,
    required String reportedUserId,
    required String reason,
    required String category,
  }) async {
    await log(
      eventType: 'user_reported',
      severity: 'warning',
      description: 'User reported another user',
      userId: userId,
      metadata: {
        'reportedUserId': reportedUserId,
        'reason': reason,
        'category': category,
      },
    );
  }

  /// Log rate limit violation
  Future<void> logRateLimitViolation({
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      eventType: 'rate_limit_violated',
      severity: 'warning',
      description: 'User exceeded rate limit',
      userId: userId,
      metadata: {
        'action': action,
        ...?metadata,
      },
    );
  }

  /// Log suspicious activity
  Future<void> logSuspiciousActivity({
    required String userId,
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      eventType: 'suspicious_activity',
      severity: 'critical',
      description: description,
      userId: userId,
      metadata: {
        'activityType': activityType,
        ...?metadata,
      },
    );
  }

  /// Log account lockout
  Future<void> logAccountLockout({
    required String email,
    required int failedAttempts,
    required DateTime lockedUntil,
  }) async {
    await log(
      eventType: 'account_locked',
      severity: 'critical',
      description: 'Account locked due to failed login attempts',
      metadata: {
        'email': email,
        'failedAttempts': failedAttempts,
        'lockedUntil': lockedUntil.toIso8601String(),
      },
    );
  }

  /// Get audit logs for current user
  /// Returns stream of audit log events
  Stream<List<Map<String, dynamic>>> getUserAuditLogs({
    int limit = 50,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('auditLogs')
        .doc(user.uid)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get audit logs by event type
  Future<List<Map<String, dynamic>>> getAuditLogsByType({
    required String userId,
    required String eventType,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('auditLogs')
          .doc(userId)
          .collection('events')
          .where('eventType', isEqualTo: eventType)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get audit logs by type', e);
      return [];
    }
  }

  /// Get audit logs by severity
  Future<List<Map<String, dynamic>>> getAuditLogsBySeverity({
    required String userId,
    required String severity,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('auditLogs')
          .doc(userId)
          .collection('events')
          .where('severity', isEqualTo: severity)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get audit logs by severity', e);
      return [];
    }
  }

  /// Delete old audit logs (for GDPR compliance)
  /// Keeps logs for specified retention period
  Future<int> deleteOldAuditLogs({
    required String userId,
    Duration retentionPeriod = const Duration(days: 90),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(retentionPeriod);
      final snapshot = await _firestore
          .collection('auditLogs')
          .doc(userId)
          .collection('events')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.info('Deleted ${snapshot.docs.length} old audit logs');

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('Failed to delete old audit logs', e);
      return 0;
    }
  }
}
