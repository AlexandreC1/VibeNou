import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';
import 'enhanced_encryption_service.dart';

/// Service for automatic encryption key rotation
///
/// Security best practice: Rotate encryption keys periodically to minimize
/// the impact of potential key compromise.
///
/// Rotation Schedule:
/// - Identity Keys (X25519): Every 90 days
/// - Signing Keys (Ed25519): Every 180 days
/// - Check frequency: Daily on app startup
///
/// Process:
/// 1. Check if keys are due for rotation
/// 2. Generate new key pairs
/// 3. Update Firestore with new public keys
/// 4. Keep old keys for 7 days to decrypt pending messages
/// 5. Delete old keys after grace period
class KeyRotationService {
  static final KeyRotationService _instance = KeyRotationService._internal();
  factory KeyRotationService() => _instance;
  KeyRotationService._internal();

  final AppLogger _logger = AppLogger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final EnhancedEncryptionService _encryptionService = EnhancedEncryptionService();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rotation intervals (in days)
  static const int identityKeyRotationDays = 90;
  static const int signingKeyRotationDays = 180;
  static const int oldKeyGracePeriodDays = 7;

  // Storage keys
  static const String _lastIdentityRotationKey = 'last_identity_rotation_';
  static const String _lastSigningRotationKey = 'last_signing_rotation_';
  static const String _oldIdentityKeyPrefix = 'old_identity_key_';
  static const String _oldSigningKeyPrefix = 'old_signing_key_';

  /// Check and perform key rotation if needed
  ///
  /// Call this on app startup or periodically
  Future<void> checkAndRotateKeys(String userId) async {
    try {
      _logger.info('Checking if key rotation is needed for user: $userId');

      // Check identity key rotation
      final identityNeedsRotation = await _needsRotation(
        userId: userId,
        lastRotationKey: _lastIdentityRotationKey,
        rotationIntervalDays: identityKeyRotationDays,
      );

      if (identityNeedsRotation) {
        await _rotateIdentityKey(userId);
      }

      // Check signing key rotation
      final signingNeedsRotation = await _needsRotation(
        userId: userId,
        lastRotationKey: _lastSigningRotationKey,
        rotationIntervalDays: signingKeyRotationDays,
      );

      if (signingNeedsRotation) {
        await _rotateSigningKey(userId);
      }

      // Clean up old keys past grace period
      await _cleanupOldKeys(userId);

      _logger.info('Key rotation check completed');
    } catch (e, stackTrace) {
      _logger.error('Failed to check/rotate keys', e, stackTrace);
      // Don't rethrow - key rotation failures shouldn't break the app
    }
  }

  /// Check if rotation is needed based on last rotation date
  Future<bool> _needsRotation({
    required String userId,
    required String lastRotationKey,
    required int rotationIntervalDays,
  }) async {
    try {
      final lastRotationStr = await _secureStorage.read(
        key: '$lastRotationKey$userId',
      );

      if (lastRotationStr == null) {
        // Never rotated, needs rotation
        _logger.info('No previous rotation found, rotation needed');
        return true;
      }

      final lastRotation = DateTime.parse(lastRotationStr);
      final daysSinceRotation = DateTime.now().difference(lastRotation).inDays;

      final needsRotation = daysSinceRotation >= rotationIntervalDays;

      if (needsRotation) {
        _logger.info('Key rotation needed: $daysSinceRotation days since last rotation');
      }

      return needsRotation;
    } catch (e) {
      _logger.error('Failed to check rotation status', e);
      return false;
    }
  }

  /// Rotate identity key (X25519)
  Future<void> _rotateIdentityKey(String userId) async {
    try {
      _logger.warning('Starting identity key rotation for user: $userId');

      // 1. Get current identity key (to keep as backup)
      final currentPublicKey = await _encryptionService.getIdentityPublicKey(userId);

      if (currentPublicKey != null) {
        // Save old key with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _secureStorage.write(
          key: '$_oldIdentityKeyPrefix${userId}_$timestamp',
          value: currentPublicKey,
        );
        _logger.info('Old identity key backed up');
      }

      // 2. Generate new identity key pair
      final newKeys = await _encryptionService.rotateIdentityKey(userId);

      // 3. Update Firestore with new public key
      await _firestore.collection('users').doc(userId).update({
        'identityPublicKey': newKeys['publicKey'],
        'identityKeyRotatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Record rotation time
      await _secureStorage.write(
        key: '$_lastIdentityRotationKey$userId',
        value: DateTime.now().toIso8601String(),
      );

      _logger.info('Identity key rotated successfully');

      // 5. Notify user (optional)
      await _notifyUserOfKeyRotation(userId, 'identity');
    } catch (e, stackTrace) {
      _logger.error('Failed to rotate identity key', e, stackTrace);
      rethrow;
    }
  }

  /// Rotate signing key (Ed25519)
  Future<void> _rotateSigningKey(String userId) async {
    try {
      _logger.warning('Starting signing key rotation for user: $userId');

      // 1. Get current signing key
      final currentPublicKey = await _encryptionService.getSigningPublicKey(userId);

      if (currentPublicKey != null) {
        // Save old key
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _secureStorage.write(
          key: '$_oldSigningKeyPrefix${userId}_$timestamp',
          value: currentPublicKey,
        );
        _logger.info('Old signing key backed up');
      }

      // 2. Generate new signing key pair
      final newKeys = await _encryptionService.rotateSigningKey(userId);

      // 3. Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'signingPublicKey': newKeys['publicKey'],
        'signingKeyRotatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Record rotation time
      await _secureStorage.write(
        key: '$_lastSigningRotationKey$userId',
        value: DateTime.now().toIso8601String(),
      );

      _logger.info('Signing key rotated successfully');

      // 5. Notify user
      await _notifyUserOfKeyRotation(userId, 'signing');
    } catch (e, stackTrace) {
      _logger.error('Failed to rotate signing key', e, stackTrace);
      rethrow;
    }
  }

  /// Clean up old keys past grace period
  Future<void> _cleanupOldKeys(String userId) async {
    try {
      _logger.debug('Checking for old keys to clean up');

      final allKeys = await _secureStorage.readAll();
      final now = DateTime.now().millisecondsSinceEpoch;
      int deletedCount = 0;

      for (final entry in allKeys.entries) {
        final key = entry.key;

        // Check if it's an old identity or signing key
        if (key.startsWith('$_oldIdentityKeyPrefix$userId') ||
            key.startsWith('$_oldSigningKeyPrefix$userId')) {

          // Extract timestamp from key name
          final parts = key.split('_');
          if (parts.isNotEmpty) {
            final timestampStr = parts.last;
            final timestamp = int.tryParse(timestampStr);

            if (timestamp != null) {
              final ageInDays = (now - timestamp) ~/ (1000 * 60 * 60 * 24);

              if (ageInDays > oldKeyGracePeriodDays) {
                await _secureStorage.delete(key: key);
                deletedCount++;
                _logger.debug('Deleted old key: $key (age: $ageInDays days)');
              }
            }
          }
        }
      }

      if (deletedCount > 0) {
        _logger.info('Cleaned up $deletedCount old keys');
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to clean up old keys', e, stackTrace);
    }
  }

  /// Notify user of key rotation
  Future<void> _notifyUserOfKeyRotation(String userId, String keyType) async {
    try {
      // Create notification in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'security',
        'title': 'Security Enhancement',
        'message': 'Your $keyType encryption keys have been automatically rotated for enhanced security.',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'keyType': keyType,
          'rotationReason': 'scheduled',
        },
      });

      _logger.info('Key rotation notification created');
    } catch (e) {
      _logger.error('Failed to create notification', e);
      // Don't rethrow - notification failure shouldn't break rotation
    }
  }

  /// Force immediate key rotation (for security incidents)
  ///
  /// Call this if:
  /// - Key compromise suspected
  /// - Security breach detected
  /// - User requests manual rotation
  Future<void> forceRotateAllKeys(String userId) async {
    try {
      _logger.warning('FORCING IMMEDIATE KEY ROTATION for user: $userId');

      await _rotateIdentityKey(userId);
      await _rotateSigningKey(userId);

      _logger.warning('Emergency key rotation completed');

      // Create high-priority notification
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'security_alert',
        'title': 'Security Keys Rotated',
        'message': 'All your encryption keys have been rotated for security reasons.',
        'read': false,
        'priority': 'high',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to force rotate keys', e, stackTrace);
      rethrow;
    }
  }

  /// Get key rotation status for user
  Future<Map<String, dynamic>> getRotationStatus(String userId) async {
    try {
      final identityRotationStr = await _secureStorage.read(
        key: '$_lastIdentityRotationKey$userId',
      );
      final signingRotationStr = await _secureStorage.read(
        key: '$_lastSigningRotationKey$userId',
      );

      DateTime? identityLastRotation;
      DateTime? signingLastRotation;

      if (identityRotationStr != null) {
        identityLastRotation = DateTime.parse(identityRotationStr);
      }
      if (signingRotationStr != null) {
        signingLastRotation = DateTime.parse(signingRotationStr);
      }

      // Calculate next rotation dates
      final identityNextRotation = identityLastRotation?.add(
        Duration(days: identityKeyRotationDays),
      );
      final signingNextRotation = signingLastRotation?.add(
        Duration(days: signingKeyRotationDays),
      );

      return {
        'identity': {
          'lastRotation': identityLastRotation?.toIso8601String(),
          'nextRotation': identityNextRotation?.toIso8601String(),
          'daysUntilRotation': identityNextRotation != null
              ? identityNextRotation.difference(DateTime.now()).inDays
              : null,
        },
        'signing': {
          'lastRotation': signingLastRotation?.toIso8601String(),
          'nextRotation': signingNextRotation?.toIso8601String(),
          'daysUntilRotation': signingNextRotation != null
              ? signingNextRotation.difference(DateTime.now()).inDays
              : null,
        },
      };
    } catch (e, stackTrace) {
      _logger.error('Failed to get rotation status', e, stackTrace);
      return {};
    }
  }
}
