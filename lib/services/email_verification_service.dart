import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// Service for handling email verification
class EmailVerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send verification email to current user
  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      if (user.emailVerified) {
        AppLogger.info('Email already verified for ${user.email}');
        return;
      }

      // Send verification email using Firebase default template
      await user.sendEmailVerification();

      AppLogger.info('Verification email sent to ${user.email}');
    } catch (e) {
      AppLogger.error('Failed to send verification email', e);
      rethrow;
    }
  }

  /// Check if current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return false;
      }

      // Reload user to get latest verification status
      await user.reload();
      final refreshedUser = _auth.currentUser;

      return refreshedUser?.emailVerified ?? false;
    } catch (e) {
      AppLogger.error('Failed to check email verification status', e);
      return false;
    }
  }

  /// Wait for email verification (polls Firebase every 3 seconds)
  /// Returns true when email is verified, false if timeout
  Stream<bool> waitForVerification({
    Duration timeout = const Duration(minutes: 5),
    Duration checkInterval = const Duration(seconds: 3),
  }) async* {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(checkInterval);

      final isVerified = await isEmailVerified();

      if (isVerified) {
        // Update Firestore to mark email as verified
        await _updateFirestoreVerificationStatus(true);
        yield true;
        return;
      }

      yield false;
    }

    // Timeout reached
    yield false;
  }

  /// Update Firestore user document with email verification status
  Future<void> _updateFirestoreVerificationStatus(bool verified) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': verified,
        'emailVerifiedAt': verified ? FieldValue.serverTimestamp() : null,
      });

      AppLogger.info('Updated Firestore verification status: $verified');
    } catch (e) {
      AppLogger.error('Failed to update Firestore verification status', e);
      // Don't throw - this is not critical
    }
  }

  /// Resend verification email with rate limiting
  /// Prevents spam by allowing resend only after cooldown period
  Future<bool> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check last sent time from user metadata
      final metadata = user.metadata;
      final lastSentTime = metadata.creationTime;

      // Allow resend only after 60 seconds
      if (lastSentTime != null) {
        final timeSinceLastSent = DateTime.now().difference(lastSentTime);
        if (timeSinceLastSent.inSeconds < 60) {
          final waitTime = 60 - timeSinceLastSent.inSeconds;
          AppLogger.warning(
            'Cannot resend email yet. Wait $waitTime seconds.',
          );
          return false;
        }
      }

      await sendVerificationEmail();
      return true;
    } catch (e) {
      AppLogger.error('Failed to resend verification email', e);
      return false;
    }
  }

  /// Get current user's email verification status and info
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {
          'isVerified': false,
          'email': null,
          'canResend': false,
        };
      }

      await user.reload();
      final refreshedUser = _auth.currentUser;

      return {
        'isVerified': refreshedUser?.emailVerified ?? false,
        'email': refreshedUser?.email,
        'canResend': !(refreshedUser?.emailVerified ?? false),
      };
    } catch (e) {
      AppLogger.error('Failed to get verification status', e);
      return {
        'isVerified': false,
        'email': null,
        'canResend': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign out user (useful when they want to use different email)
  Future<void> signOutAndRetry() async {
    try {
      await _auth.signOut();
      AppLogger.info('User signed out to retry with different email');
    } catch (e) {
      AppLogger.error('Failed to sign out', e);
      rethrow;
    }
  }
}
