import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_logger.dart';

/// Enhanced security monitoring and threat detection service
///
/// Monitors for:
/// - Suspicious login attempts
/// - Unusual encryption/decryption failures
/// - Potential MITM attacks
/// - Rooted/jailbroken devices
/// - App tampering
/// - Unusual access patterns
/// - Rate limit violations
///
/// All security events are logged to Firestore for analysis
class SecurityMonitoringService {
  static final SecurityMonitoringService _instance = SecurityMonitoringService._internal();
  factory SecurityMonitoringService() => _instance;
  SecurityMonitoringService._internal();

  final AppLogger _logger = AppLogger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Thresholds for alerts
  static const int maxFailedDecryptionsPerHour = 10;
  static const int maxFailedLoginsPerDay = 5;
  static const int maxRateLimitViolationsPerDay = 10;

  // Security event types
  static const String eventTypeLogin = 'login';
  static const String eventTypeLogout = 'logout';
  static const String eventTypeEncryptionFailure = 'encryption_failure';
  static const String eventTypeDecryptionFailure = 'decryption_failure';
  static const String eventTypeSignatureFailure = 'signature_failure';
  static const String eventTypeCertificatePinningFailure = 'cert_pinning_failure';
  static const String eventTypeRateLimitViolation = 'rate_limit_violation';
  static const String eventTypeRootDetected = 'root_detected';
  static const String eventTypeTamperingDetected = 'tampering_detected';
  static const String eventTypeUnusualAccess = 'unusual_access';
  static const String eventTypeKeyRotation = 'key_rotation';

  /// Log a security event
  Future<void> logSecurityEvent({
    required String eventType,
    required String severity, // 'low', 'medium', 'high', 'critical'
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      // Create event document
      final event = {
        'userId': userId,
        'eventType': eventType,
        'severity': severity,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
        'metadata': metadata ?? {},
      };

      // Log to Firestore
      await _firestore.collection('security_events').add(event);

      // Log locally
      _logger.warning('Security Event [$severity]: $eventType - $description');

      // Check if alert needed
      await _checkForAlerts(userId, eventType, severity);

    } catch (e, stackTrace) {
      _logger.error('Failed to log security event', e, stackTrace);
      // Don't rethrow - logging failures shouldn't break the app
    }
  }

  /// Check if security alerts should be triggered
  Future<void> _checkForAlerts(String? userId, String eventType, String severity) async {
    if (userId == null) return;

    try {
      // Critical events always trigger alerts
      if (severity == 'critical') {
        await _createSecurityAlert(
          userId: userId,
          title: 'Critical Security Event',
          message: 'A critical security event was detected. Please review your account security.',
          eventType: eventType,
        );
        return;
      }

      // Check for patterns that indicate attacks
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Query recent events
      final recentEvents = await _firestore
          .collection('security_events')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      // Count specific event types
      int failedDecryptions = 0;
      int failedLogins = 0;
      int rateLimitViolations = 0;

      for (final doc in recentEvents.docs) {
        final data = doc.data();
        final eventTimestamp = (data['timestamp'] as Timestamp).toDate();
        final type = data['eventType'] as String;

        // Count events in last hour
        if (eventTimestamp.isAfter(oneHourAgo)) {
          if (type == eventTypeDecryptionFailure) failedDecryptions++;
        }

        // Count events in last day
        if (type == eventTypeLogin && data['metadata']?['success'] == false) {
          failedLogins++;
        }
        if (type == eventTypeRateLimitViolation) {
          rateLimitViolations++;
        }
      }

      // Trigger alerts if thresholds exceeded
      if (failedDecryptions >= maxFailedDecryptionsPerHour) {
        await _createSecurityAlert(
          userId: userId,
          title: 'Unusual Decryption Failures',
          message: 'Multiple message decryption failures detected. Your keys may be compromised.',
          eventType: eventTypeDecryptionFailure,
        );
      }

      if (failedLogins >= maxFailedLoginsPerDay) {
        await _createSecurityAlert(
          userId: userId,
          title: 'Multiple Failed Login Attempts',
          message: 'Someone may be trying to access your account.',
          eventType: eventTypeLogin,
        );
      }

      if (rateLimitViolations >= maxRateLimitViolationsPerDay) {
        await _createSecurityAlert(
          userId: userId,
          title: 'Unusual Activity Detected',
          message: 'Unusual usage patterns detected on your account.',
          eventType: eventTypeRateLimitViolation,
        );
      }

    } catch (e, stackTrace) {
      _logger.error('Failed to check for alerts', e, stackTrace);
    }
  }

  /// Create a security alert for the user
  Future<void> _createSecurityAlert({
    required String userId,
    required String title,
    required String message,
    required String eventType,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'security_alert',
        'title': title,
        'message': message,
        'eventType': eventType,
        'read': false,
        'priority': 'high',
        'timestamp': FieldValue.serverTimestamp(),
        'actionRequired': true,
      });

      _logger.warning('Security alert created: $title');

      // TODO: Send push notification

    } catch (e, stackTrace) {
      _logger.error('Failed to create security alert', e, stackTrace);
    }
  }

  /// Get device information for security logging
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'osVersion': androidInfo.version.release,
          'device': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'appVersion': packageInfo.version,
          'appBuildNumber': packageInfo.buildNumber,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'osVersion': iosInfo.systemVersion,
          'device': iosInfo.model,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'appVersion': packageInfo.version,
          'appBuildNumber': packageInfo.buildNumber,
        };
      }
    } catch (e) {
      _logger.error('Failed to get device info', e);
    }

    return {
      'platform': 'Unknown',
      'appVersion': packageInfo.version,
    };
  }

  /// Detect if device is rooted/jailbroken
  ///
  /// WARNING: Root detection can be bypassed by sophisticated attackers
  /// This is just a basic check, not foolproof
  Future<bool> detectRootedDevice() async {
    try {
      if (Platform.isAndroid) {
        return await _detectAndroidRoot();
      } else if (Platform.isIOS) {
        return await _detectIOSJailbreak();
      }
    } catch (e) {
      _logger.error('Failed to detect rooted device', e);
    }

    return false;
  }

  /// Detect Android root
  Future<bool> _detectAndroidRoot() async {
    // Check for common root indicators
    final rootIndicators = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
    ];

    for (final path in rootIndicators) {
      if (await File(path).exists()) {
        _logger.warning('Root indicator found: $path');
        await logSecurityEvent(
          eventType: eventTypeRootDetected,
          severity: 'high',
          description: 'Rooted Android device detected',
          metadata: {'indicator': path},
        );
        return true;
      }
    }

    return false;
  }

  /// Detect iOS jailbreak
  Future<bool> _detectIOSJailbreak() async {
    // Check for common jailbreak indicators
    final jailbreakIndicators = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
    ];

    for (final path in jailbreakIndicators) {
      if (await File(path).exists()) {
        _logger.warning('Jailbreak indicator found: $path');
        await logSecurityEvent(
          eventType: eventTypeRootDetected,
          severity: 'high',
          description: 'Jailbroken iOS device detected',
          metadata: {'indicator': path},
        );
        return true;
      }
    }

    return false;
  }

  /// Monitor encryption operation
  Future<void> monitorEncryption({
    required bool success,
    required String operation, // 'encrypt', 'decrypt', 'sign', 'verify'
    String? errorMessage,
  }) async {
    if (!success) {
      final eventType = operation == 'encrypt'
          ? eventTypeEncryptionFailure
          : operation == 'decrypt'
              ? eventTypeDecryptionFailure
              : eventTypeSignatureFailure;

      await logSecurityEvent(
        eventType: eventType,
        severity: 'medium',
        description: '$operation operation failed: ${errorMessage ?? "Unknown error"}',
        metadata: {
          'operation': operation,
          'error': errorMessage,
        },
      );
    }
  }

  /// Monitor login attempts
  Future<void> monitorLogin({
    required bool success,
    required String method, // 'email', 'google', '2fa'
    String? errorMessage,
  }) async {
    await logSecurityEvent(
      eventType: eventTypeLogin,
      severity: success ? 'low' : 'medium',
      description: 'Login attempt via $method: ${success ? "Success" : "Failed"}',
      metadata: {
        'method': method,
        'success': success,
        'error': errorMessage,
      },
    );
  }

  /// Monitor certificate pinning failures
  Future<void> monitorCertificatePinning({
    required String host,
    required String expectedFingerprint,
    required String actualFingerprint,
  }) async {
    await logSecurityEvent(
      eventType: eventTypeCertificatePinningFailure,
      severity: 'critical',
      description: 'Certificate pinning failed for $host - Possible MITM attack',
      metadata: {
        'host': host,
        'expectedFingerprint': expectedFingerprint,
        'actualFingerprint': actualFingerprint,
      },
    );
  }

  /// Get security dashboard data for user
  Future<Map<String, dynamic>> getSecurityDashboard(String userId) async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));

      final events = await _firestore
          .collection('security_events')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(last30Days))
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      // Analyze events
      final eventCounts = <String, int>{};
      final severityCounts = <String, int>{};
      final recentCritical = <Map<String, dynamic>>[];

      for (final doc in events.docs) {
        final data = doc.data();
        final eventType = data['eventType'] as String;
        final severity = data['severity'] as String;

        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;

        if (severity == 'critical') {
          recentCritical.add(data);
        }
      }

      return {
        'totalEvents': events.size,
        'eventCounts': eventCounts,
        'severityCounts': severityCounts,
        'recentCriticalEvents': recentCritical.take(5).toList(),
        'periodDays': 30,
      };

    } catch (e, stackTrace) {
      _logger.error('Failed to get security dashboard', e, stackTrace);
      return {};
    }
  }
}
