import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// Enhanced encryption service with Perfect Forward Secrecy and message signatures
///
/// Security Features:
/// - Perfect Forward Secrecy (PFS): Each message uses ephemeral keys
/// - Ed25519 Digital Signatures: Verify message authenticity
/// - X25519 Key Exchange: Secure ephemeral key generation
/// - ChaCha20-Poly1305: Modern authenticated encryption
///
/// This replaces the previous RSA+AES system with more secure, modern cryptography
class EnhancedEncryptionService {
  static final EnhancedEncryptionService _instance = EnhancedEncryptionService._internal();
  factory EnhancedEncryptionService() => _instance;
  EnhancedEncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Cryptography algorithms
  final _keyExchange = X25519();
  final _signature = Ed25519();
  final _cipher = Chacha20.poly1305Aead();

  // Storage keys
  static const String _identityKeyPrefix = 'identity_key_';
  static const String _signingKeyPrefix = 'signing_key_';

  /// Generate identity key pair for user (X25519 for key exchange)
  ///
  /// Call this once during user signup
  Future<Map<String, String>> generateIdentityKeyPair(String userId) async {
    try {
      AppLogger.info('Generating identity key pair for user: $userId');

      // Generate X25519 key pair for key exchange
      final keyPair = await _keyExchange.newKeyPair();

      // Extract public and private keys
      final publicKey = await keyPair.extractPublicKey();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

      // Convert to base64 for storage
      final publicKeyBase64 = base64Encode(publicKey.bytes);
      final privateKeyBase64 = base64Encode(privateKeyBytes);

      // Store private key securely on device
      await _secureStorage.write(
        key: '$_identityKeyPrefix$userId',
        value: privateKeyBase64,
      );

      AppLogger.info('Identity key pair generated successfully');

      return {
        'publicKey': publicKeyBase64,
        'privateKey': privateKeyBase64, // Return but don't send to server!
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate identity key pair', e, stackTrace);
      rethrow;
    }
  }

  /// Generate signing key pair for message authentication (Ed25519)
  ///
  /// Call this once during user signup
  Future<Map<String, String>> generateSigningKeyPair(String userId) async {
    try {
      AppLogger.info('Generating signing key pair for user: $userId');

      // Generate Ed25519 key pair for signatures
      final keyPair = await _signature.newKeyPair();

      // Extract keys
      final publicKey = await keyPair.extractPublicKey();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

      // Convert to base64
      final publicKeyBase64 = base64Encode(publicKey.bytes);
      final privateKeyBase64 = base64Encode(privateKeyBytes);

      // Store private key securely
      await _secureStorage.write(
        key: '$_signingKeyPrefix$userId',
        value: privateKeyBase64,
      );

      AppLogger.info('Signing key pair generated successfully');

      return {
        'publicKey': publicKeyBase64,
        'privateKey': privateKeyBase64,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate signing key pair', e, stackTrace);
      rethrow;
    }
  }

  /// Encrypt message with Perfect Forward Secrecy
  ///
  /// Process:
  /// 1. Generate ephemeral X25519 key pair
  /// 2. Perform key exchange with recipient's identity public key
  /// 3. Derive shared secret using HKDF
  /// 4. Encrypt message with ChaCha20-Poly1305
  /// 5. Sign the encrypted message with sender's Ed25519 key
  ///
  /// Returns: {
  ///   'encryptedMessage': base64,
  ///   'ephemeralPublicKey': base64,
  ///   'nonce': base64,
  ///   'signature': base64
  /// }
  Future<Map<String, String>> encryptMessage({
    required String message,
    required String recipientPublicKey,
    required String senderId,
  }) async {
    try {
      AppLogger.debug('Encrypting message with PFS');

      // 1. Generate ephemeral key pair for this message only
      final ephemeralKeyPair = await _keyExchange.newKeyPair();
      final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

      // 2. Decode recipient's public key
      final recipientKey = SimplePublicKey(
        base64Decode(recipientPublicKey),
        type: KeyPairType.x25519,
      );

      // 3. Perform X25519 key exchange to get shared secret
      final sharedSecret = await _keyExchange.sharedSecretKey(
        keyPair: ephemeralKeyPair,
        remotePublicKey: recipientKey,
      );

      // 4. Derive encryption key from shared secret using HKDF
      final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
      final derivedKey = await hkdf.deriveKey(
        secretKey: sharedSecret,
        nonce: ephemeralPublicKey.bytes,
        info: utf8.encode('VibeNou-Message-Encryption-v1'),
      );

      // 5. Generate random nonce
      final nonce = _cipher.newNonce();

      // 6. Encrypt message with ChaCha20-Poly1305
      final secretBox = await _cipher.encrypt(
        utf8.encode(message),
        secretKey: derivedKey,
        nonce: nonce,
      );

      // 7. Sign the encrypted message for authenticity
      final signature = await _signMessage(
        data: secretBox.cipherText,
        userId: senderId,
      );

      // 8. Return all components
      return {
        'encryptedMessage': base64Encode(secretBox.cipherText),
        'ephemeralPublicKey': base64Encode(ephemeralPublicKey.bytes),
        'nonce': base64Encode(nonce),
        'signature': signature,
        'mac': base64Encode(secretBox.mac.bytes), // Poly1305 authentication tag
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to encrypt message', e, stackTrace);
      rethrow;
    }
  }

  /// Decrypt message with Perfect Forward Secrecy
  ///
  /// Process:
  /// 1. Verify message signature
  /// 2. Perform key exchange with ephemeral public key
  /// 3. Derive shared secret
  /// 4. Decrypt message with ChaCha20-Poly1305
  Future<String> decryptMessage({
    required String encryptedMessage,
    required String ephemeralPublicKey,
    required String nonce,
    required String signature,
    required String mac,
    required String receiverId,
    required String senderPublicKey,
  }) async {
    try {
      AppLogger.debug('Decrypting message with PFS');

      // 1. Verify signature first (fail fast if tampered)
      final encryptedBytes = base64Decode(encryptedMessage);
      final isValid = await _verifySignature(
        data: encryptedBytes,
        signature: signature,
        senderPublicKey: senderPublicKey,
      );

      if (!isValid) {
        throw Exception('Message signature verification failed - message may be tampered');
      }

      // 2. Load receiver's identity private key
      final privateKeyBase64 = await _secureStorage.read(
        key: '$_identityKeyPrefix$receiverId',
      );
      if (privateKeyBase64 == null) {
        throw Exception('Identity private key not found for user: $receiverId');
      }

      final privateKeyBytes = base64Decode(privateKeyBase64);
      final receiverKeyPair = SimpleKeyPairData(
        privateKeyBytes,
        publicKey: SimplePublicKey([], type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );

      // 3. Decode sender's ephemeral public key
      final senderEphemeralKey = SimplePublicKey(
        base64Decode(ephemeralPublicKey),
        type: KeyPairType.x25519,
      );

      // 4. Perform key exchange
      final sharedSecret = await _keyExchange.sharedSecretKey(
        keyPair: receiverKeyPair,
        remotePublicKey: senderEphemeralKey,
      );

      // 5. Derive decryption key (same as encryption)
      final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
      final derivedKey = await hkdf.deriveKey(
        secretKey: sharedSecret,
        nonce: base64Decode(ephemeralPublicKey),
        info: utf8.encode('VibeNou-Message-Encryption-v1'),
      );

      // 6. Decrypt message
      final secretBox = SecretBox(
        encryptedBytes,
        nonce: base64Decode(nonce),
        mac: Mac(base64Decode(mac)),
      );

      final decryptedBytes = await _cipher.decrypt(
        secretBox,
        secretKey: derivedKey,
      );

      final plaintext = utf8.decode(decryptedBytes);
      AppLogger.debug('Message decrypted successfully');

      return plaintext;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to decrypt message', e, stackTrace);
      rethrow;
    }
  }

  /// Sign data with user's Ed25519 private key
  Future<String> _signMessage({
    required List<int> data,
    required String userId,
  }) async {
    try {
      // Load signing private key
      final privateKeyBase64 = await _secureStorage.read(
        key: '$_signingKeyPrefix$userId',
      );
      if (privateKeyBase64 == null) {
        throw Exception('Signing private key not found for user: $userId');
      }

      final privateKeyBytes = base64Decode(privateKeyBase64);
      final keyPair = SimpleKeyPairData(
        privateKeyBytes,
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );

      // Sign the data
      final signature = await _signature.sign(
        data,
        keyPair: keyPair,
      );

      return base64Encode(signature.bytes);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign message', e, stackTrace);
      rethrow;
    }
  }

  /// Verify message signature
  Future<bool> _verifySignature({
    required List<int> data,
    required String signature,
    required String senderPublicKey,
  }) async {
    try {
      // Decode public key and signature
      final publicKey = SimplePublicKey(
        base64Decode(senderPublicKey),
        type: KeyPairType.ed25519,
      );

      final sig = Signature(
        base64Decode(signature),
        publicKey: publicKey,
      );

      // Verify signature
      final isValid = await _signature.verify(
        data,
        signature: sig,
      );

      AppLogger.debug('Signature verification: ${isValid ? 'VALID' : 'INVALID'}');
      return isValid;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to verify signature', e, stackTrace);
      return false;
    }
  }

  /// Get user's identity public key from secure storage
  Future<String?> getIdentityPublicKey(String userId) async {
    // In production, this should be fetched from Firestore
    // For now, we'll reconstruct from private key
    try {
      final privateKeyBase64 = await _secureStorage.read(
        key: '$_identityKeyPrefix$userId',
      );
      if (privateKeyBase64 == null) return null;

      // Reconstruct key pair to get public key
      final privateKeyBytes = base64Decode(privateKeyBase64);
      final keyPair = SimpleKeyPairData(
        privateKeyBytes,
        publicKey: SimplePublicKey([], type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );

      final publicKey = await keyPair.extractPublicKey();
      return base64Encode(publicKey.bytes);
    } catch (e) {
      AppLogger.error('Failed to get identity public key', e);
      return null;
    }
  }

  /// Get user's signing public key from secure storage
  Future<String?> getSigningPublicKey(String userId) async {
    try {
      final privateKeyBase64 = await _secureStorage.read(
        key: '$_signingKeyPrefix$userId',
      );
      if (privateKeyBase64 == null) return null;

      final privateKeyBytes = base64Decode(privateKeyBase64);
      final keyPair = SimpleKeyPairData(
        privateKeyBytes,
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );

      final publicKey = await keyPair.extractPublicKey();
      return base64Encode(publicKey.bytes);
    } catch (e) {
      AppLogger.error('Failed to get signing public key', e);
      return null;
    }
  }

  /// Delete all keys for a user (on logout/account deletion)
  Future<void> deleteKeys(String userId) async {
    try {
      await _secureStorage.delete(key: '$_identityKeyPrefix$userId');
      await _secureStorage.delete(key: '$_signingKeyPrefix$userId');
      AppLogger.info('All keys deleted for user: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete keys', e, stackTrace);
    }
  }

  /// Rotate identity key (for enhanced security)
  ///
  /// This should be done periodically (e.g., every 90 days)
  Future<Map<String, String>> rotateIdentityKey(String userId) async {
    AppLogger.warning('Rotating identity key for user: $userId');

    // Generate new key pair
    final newKeys = await generateIdentityKeyPair(userId);

    // Old key is automatically overwritten in secure storage

    return newKeys;
  }

  /// Rotate signing key
  Future<Map<String, String>> rotateSigningKey(String userId) async {
    AppLogger.warning('Rotating signing key for user: $userId');
    return await generateSigningKeyPair(userId);
  }
}
