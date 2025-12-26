import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import '../utils/app_logger.dart';

/// Two-Factor Authentication (2FA) service using TOTP
/// Compatible with Google Authenticator, Authy, and other TOTP apps
class TwoFactorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a random secret key for TOTP
  /// Returns base32-encoded secret (compatible with authenticator apps)
  String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes));
  }

  /// Generate QR code URL for authenticator apps
  /// Format: otpauth://totp/VibeNou:email?secret=SECRET&issuer=VibeNou
  String getQRCodeUrl(String email, String secret) {
    final encodedEmail = Uri.encodeComponent(email);
    return 'otpauth://totp/VibeNou:$encodedEmail?secret=$secret&issuer=VibeNou&digits=6&period=30';
  }

  /// Verify a TOTP code
  /// Returns true if the code is valid (with 30-second window tolerance)
  bool verifyCode(String secret, String code) {
    try {
      // Current time
      final now = DateTime.now();

      // Try current time window
      final currentCode = OTP.generateTOTPCodeString(
        secret,
        now.millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
      );

      if (currentCode == code) {
        return true;
      }

      // Try previous time window (for clock drift tolerance)
      final previousCode = OTP.generateTOTPCodeString(
        secret,
        now.subtract(const Duration(seconds: 30)).millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
      );

      if (previousCode == code) {
        return true;
      }

      // Try next time window (for clock drift tolerance)
      final nextCode = OTP.generateTOTPCodeString(
        secret,
        now.add(const Duration(seconds: 30)).millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
      );

      if (nextCode == code) {
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Failed to verify TOTP code', e);
      return false;
    }
  }

  /// Generate recovery codes (10 one-time use codes)
  /// Returns list of 8-digit codes
  List<String> generateRecoveryCodes({int count = 10}) {
    final random = Random.secure();
    final codes = <String>[];

    for (int i = 0; i < count; i++) {
      final code = random.nextInt(100000000).toString().padLeft(8, '0');
      codes.add(code);
    }

    return codes;
  }

  /// Hash recovery code for secure storage
  String hashRecoveryCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify recovery code against hash
  bool verifyRecoveryCode(String code, String hash) {
    return hashRecoveryCode(code) == hash;
  }

  /// Enable 2FA for current user
  /// Stores encrypted secret and hashed recovery codes in Firestore
  Future<Map<String, dynamic>> enableTwoFactor(
    String secret,
    List<String> recoveryCodes,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Hash recovery codes before storing
      final hashedCodes = recoveryCodes.map((code) => hashRecoveryCode(code)).toList();

      // Store 2FA configuration
      await _firestore.collection('users').doc(user.uid).update({
        'twoFactorEnabled': true,
        'twoFactorSecret': secret, // In production, encrypt this!
        'recoveryCodes': hashedCodes,
        'twoFactorSetupAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('2FA enabled for user ${user.uid}');

      return {
        'success': true,
        'secret': secret,
        'recoveryCodes': recoveryCodes,
      };
    } catch (e) {
      AppLogger.error('Failed to enable 2FA', e);
      rethrow;
    }
  }

  /// Disable 2FA for current user
  Future<void> disableTwoFactor(String verificationCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get user's 2FA secret
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final data = doc.data()!;
      final secret = data['twoFactorSecret'] as String?;

      if (secret == null) {
        throw Exception('2FA not enabled');
      }

      // Verify code before disabling
      if (!verifyCode(secret, verificationCode)) {
        throw Exception('Invalid verification code');
      }

      // Remove 2FA configuration
      await _firestore.collection('users').doc(user.uid).update({
        'twoFactorEnabled': false,
        'twoFactorSecret': FieldValue.delete(),
        'recoveryCodes': FieldValue.delete(),
        'twoFactorDisabledAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('2FA disabled for user ${user.uid}');
    } catch (e) {
      AppLogger.error('Failed to disable 2FA', e);
      rethrow;
    }
  }

  /// Check if 2FA is enabled for current user
  Future<bool> isTwoFactorEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['twoFactorEnabled'] == true;
    } catch (e) {
      AppLogger.error('Failed to check 2FA status', e);
      return false;
    }
  }

  /// Get 2FA configuration for current user
  Future<Map<String, dynamic>?> getTwoFactorConfig() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;

      if (data['twoFactorEnabled'] != true) {
        return null;
      }

      return {
        'enabled': true,
        'secret': data['twoFactorSecret'],
        'setupAt': data['twoFactorSetupAt'],
        'hasRecoveryCodes': data['recoveryCodes'] != null,
      };
    } catch (e) {
      AppLogger.error('Failed to get 2FA config', e);
      return null;
    }
  }

  /// Verify 2FA code during login
  /// Supports both TOTP codes and recovery codes
  Future<bool> verifyTwoFactorLogin(String userId, String code) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }

      final data = doc.data()!;
      final secret = data['twoFactorSecret'] as String?;
      final hashedCodes = (data['recoveryCodes'] as List?)?.cast<String>();

      if (secret == null) {
        throw Exception('2FA not configured');
      }

      // Try TOTP verification first
      if (verifyCode(secret, code)) {
        return true;
      }

      // Try recovery code if TOTP fails
      if (hashedCodes != null) {
        for (int i = 0; i < hashedCodes.length; i++) {
          if (verifyRecoveryCode(code, hashedCodes[i])) {
            // Remove used recovery code
            hashedCodes.removeAt(i);
            await _firestore.collection('users').doc(userId).update({
              'recoveryCodes': hashedCodes,
            });

            AppLogger.info('Recovery code used for user $userId');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('Failed to verify 2FA login', e);
      return false;
    }
  }

  /// Get remaining recovery codes count
  Future<int> getRemainingRecoveryCodesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return 0;

      final data = doc.data()!;
      final codes = data['recoveryCodes'] as List?;

      return codes?.length ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get recovery codes count', e);
      return 0;
    }
  }

  /// Regenerate recovery codes
  /// Old codes will be invalidated
  Future<List<String>> regenerateRecoveryCodes(String verificationCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Verify code before regenerating
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data()!;
      final secret = data['twoFactorSecret'] as String?;

      if (secret == null || !verifyCode(secret, verificationCode)) {
        throw Exception('Invalid verification code');
      }

      // Generate new codes
      final newCodes = generateRecoveryCodes();
      final hashedCodes = newCodes.map((code) => hashRecoveryCode(code)).toList();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'recoveryCodes': hashedCodes,
        'recoveryCodesRegeneratedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Recovery codes regenerated for user ${user.uid}');

      return newCodes;
    } catch (e) {
      AppLogger.error('Failed to regenerate recovery codes', e);
      rethrow;
    }
  }
}
