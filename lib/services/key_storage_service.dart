import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// Service for securely storing and retrieving encryption keys on device
/// Uses flutter_secure_storage for platform-specific secure storage
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (AES encryption)
/// - Web: Web Crypto API
class KeyStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Store user's private RSA key securely
  Future<void> storePrivateKey(String userId, String privateKey) async {
    try {
      await _storage.write(
        key: 'private_key_$userId',
        value: privateKey,
      );
      AppLogger.info('Private key stored securely for user $userId');
    } catch (e) {
      AppLogger.error('Error storing private key', e);
      rethrow;
    }
  }

  /// Retrieve user's private RSA key
  Future<String?> getPrivateKey(String userId) async {
    try {
      final privateKey = await _storage.read(key: 'private_key_$userId');
      if (privateKey != null) {
        AppLogger.debug('Private key retrieved for user $userId');
      } else {
        AppLogger.warning('No private key found for user $userId');
      }
      return privateKey;
    } catch (e) {
      AppLogger.error('Error retrieving private key', e);
      return null;
    }
  }

  /// Delete user's private RSA key (e.g., on logout)
  Future<void> deletePrivateKey(String userId) async {
    try {
      await _storage.delete(key: 'private_key_$userId');
      AppLogger.info('Private key deleted for user $userId');
    } catch (e) {
      AppLogger.error('Error deleting private key', e);
      rethrow;
    }
  }

  /// Check if private key exists for user
  Future<bool> hasPrivateKey(String userId) async {
    try {
      final key = await _storage.read(key: 'private_key_$userId');
      return key != null;
    } catch (e) {
      AppLogger.error('Error checking for private key', e);
      return false;
    }
  }

  /// Delete all stored keys (e.g., on app uninstall or reset)
  Future<void> deleteAllKeys() async {
    try {
      await _storage.deleteAll();
      AppLogger.warning('All encryption keys deleted from secure storage');
    } catch (e) {
      AppLogger.error('Error deleting all keys', e);
      rethrow;
    }
  }

  /// Get all stored key identifiers (for debugging)
  Future<Map<String, String>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      AppLogger.debug('Retrieved ${all.length} keys from secure storage');
      return all;
    } catch (e) {
      AppLogger.error('Error reading all keys', e);
      return {};
    }
  }
}
