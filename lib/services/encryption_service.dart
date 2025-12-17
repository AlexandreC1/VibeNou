import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import '../utils/app_logger.dart';

/// Service for end-to-end encryption of chat messages
/// Uses hybrid encryption: RSA-2048 for key exchange, AES-256-GCM for message encryption
class EncryptionService {
  /// Generate RSA key pair (2048-bit) for asymmetric encryption
  /// Returns a map with 'publicKey' and 'privateKey' in PEM format
  static Future<Map<String, String>> generateUserKeyPair() async {
    try {
      final keyParams = RSAKeyGeneratorParameters(
        BigInt.parse('65537'), // public exponent
        2048, // key size in bits
        64, // certainty for prime generation
      );

      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = <int>[];
      for (int i = 0; i < 32; i++) {
        seeds.add(seedSource.nextInt(256));
      }
      secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

      final keyGenerator = RSAKeyGenerator()
        ..init(ParametersWithRandom(keyParams, secureRandom));

      final keyPair = keyGenerator.generateKeyPair();
      final publicKey = keyPair.publicKey as RSAPublicKey;
      final privateKey = keyPair.privateKey as RSAPrivateKey;

      return {
        'publicKey': _encodePublicKeyToPem(publicKey),
        'privateKey': _encodePrivateKeyToPem(privateKey),
      };
    } catch (e) {
      AppLogger.error('Error generating RSA key pair', e);
      rethrow;
    }
  }

  /// Generate AES-256 symmetric key for message encryption
  /// Returns base64-encoded key
  static String generateSymmetricKey() {
    try {
      final key = encrypt.Key.fromSecureRandom(32); // 256-bit key
      return base64.encode(key.bytes);
    } catch (e) {
      AppLogger.error('Error generating symmetric key', e);
      rethrow;
    }
  }

  /// Encrypt symmetric key with recipient's public RSA key
  /// Used for secure key exchange
  static String encryptSymmetricKey(String symmetricKey, String recipientPublicKeyPem) {
    try {
      final parser = encrypt.RSAKeyParser();
      final publicKey = parser.parse(recipientPublicKeyPem) as RSAPublicKey;
      final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(symmetricKey);
      return encrypted.base64;
    } catch (e) {
      AppLogger.error('Error encrypting symmetric key', e);
      rethrow;
    }
  }

  /// Decrypt symmetric key with user's private RSA key
  static String decryptSymmetricKey(String encryptedKey, String privateKeyPem) {
    try {
      final parser = encrypt.RSAKeyParser();
      final privateKey = parser.parse(privateKeyPem) as RSAPrivateKey;
      final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
      final decrypted = encrypter.decrypt64(encryptedKey);
      return decrypted;
    } catch (e) {
      AppLogger.error('Error decrypting symmetric key', e);
      rethrow;
    }
  }

  /// Encrypt message with AES-256-GCM symmetric encryption
  /// Returns map with 'encryptedMessage' and 'iv' (initialization vector)
  static Map<String, String> encryptMessage(String message, String symmetricKeyBase64) {
    try {
      final key = encrypt.Key(base64.decode(symmetricKeyBase64));
      final iv = encrypt.IV.fromSecureRandom(16); // 128-bit IV for AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      final encrypted = encrypter.encrypt(message, iv: iv);

      return {
        'encryptedMessage': encrypted.base64,
        'iv': iv.base64,
      };
    } catch (e) {
      AppLogger.error('Error encrypting message', e);
      rethrow;
    }
  }

  /// Decrypt message with AES-256-GCM
  static String decryptMessage({
    required String encryptedMessage,
    required String ivBase64,
    required String symmetricKeyBase64,
  }) {
    try {
      final key = encrypt.Key(base64.decode(symmetricKeyBase64));
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);
      return decrypted;
    } catch (e) {
      AppLogger.error('Error decrypting message', e);
      rethrow;
    }
  }

  // ========== Private Helper Methods ==========

  /// Encode RSA public key to PEM format using pointycastle
  static String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    // Simple PEM encoding for public key
    final modulus = _encodeBigInt(publicKey.modulus!);
    final exponent = _encodeBigInt(publicKey.exponent!);

    // Build ASN.1 structure manually
    final publicKeyBytes = _encodeSequence([modulus, exponent]);
    final publicKeyBitString = _encodeBitString(publicKeyBytes);

    // Algorithm identifier for RSA encryption
    final algorithmId = _encodeSequence([
      Uint8List.fromList([0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01]), // RSA OID
      Uint8List.fromList([0x05, 0x00]), // NULL
    ]);

    final publicKeyInfo = _encodeSequence([algorithmId, publicKeyBitString]);
    final base64Str = base64.encode(publicKeyInfo);

    return '-----BEGIN PUBLIC KEY-----\n$base64Str\n-----END PUBLIC KEY-----';
  }

  /// Encode RSA private key to PEM format using pointycastle
  static String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    final iQ = privateKey.q!.modInverse(privateKey.p!);

    final privateKeyBytes = _encodeSequence([
      _encodeInteger(BigInt.zero), // version
      _encodeBigInt(privateKey.n!),
      _encodeBigInt(privateKey.exponent!),
      _encodeBigInt(privateKey.privateExponent!),
      _encodeBigInt(privateKey.p!),
      _encodeBigInt(privateKey.q!),
      _encodeBigInt(dP),
      _encodeBigInt(dQ),
      _encodeBigInt(iQ),
    ]);

    final base64Str = base64.encode(privateKeyBytes);
    return '-----BEGIN RSA PRIVATE KEY-----\n$base64Str\n-----END RSA PRIVATE KEY-----';
  }

  /// Encode BigInt to ASN.1 INTEGER format
  static Uint8List _encodeBigInt(BigInt number) {
    return _encodeInteger(number);
  }

  /// Encode integer to ASN.1 format
  static Uint8List _encodeInteger(BigInt number) {
    var bytes = _bigIntToBytes(number);

    // Add leading zero if high bit is set (to indicate positive number)
    if (bytes[0] & 0x80 != 0) {
      bytes = Uint8List.fromList([0, ...bytes]);
    }

    return _encodeAsn1(0x02, bytes); // 0x02 = INTEGER tag
  }

  /// Encode ASN.1 SEQUENCE
  static Uint8List _encodeSequence(List<Uint8List> elements) {
    final content = Uint8List.fromList(elements.expand((e) => e).toList());
    return _encodeAsn1(0x30, content); // 0x30 = SEQUENCE tag
  }

  /// Encode ASN.1 BIT STRING
  static Uint8List _encodeBitString(Uint8List bytes) {
    final content = Uint8List.fromList([0x00, ...bytes]); // 0x00 = no unused bits
    return _encodeAsn1(0x03, content); // 0x03 = BIT STRING tag
  }

  /// Encode ASN.1 TLV (Tag-Length-Value)
  static Uint8List _encodeAsn1(int tag, Uint8List value) {
    final length = value.length;
    List<int> result = [tag];

    if (length < 128) {
      result.add(length);
    } else {
      final lengthBytes = _intToBytes(length);
      result.add(0x80 | lengthBytes.length);
      result.addAll(lengthBytes);
    }

    result.addAll(value);
    return Uint8List.fromList(result);
  }

  /// Convert BigInt to bytes
  static Uint8List _bigIntToBytes(BigInt number) {
    final bytes = <int>[];
    var n = number;

    if (n == BigInt.zero) return Uint8List.fromList([0]);

    while (n > BigInt.zero) {
      bytes.insert(0, (n & BigInt.from(0xff)).toInt());
      n = n >> 8;
    }

    return Uint8List.fromList(bytes);
  }

  /// Convert int to bytes (for length encoding)
  static List<int> _intToBytes(int number) {
    final bytes = <int>[];
    var n = number;

    while (n > 0) {
      bytes.insert(0, n & 0xff);
      n = n >> 8;
    }

    return bytes;
  }
}
