import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/app_logger.dart';

/// RewardsService - Secure reward system using Cloud Functions
///
/// SECURITY UPDATE (2026-03-24):
/// This service now uses Cloud Functions for all reward operations to prevent
/// client-side manipulation. All date calculations and validation happen
/// server-side where they cannot be tampered with.
///
/// Migration from client-side to server-side:
/// - Reward claims now go through claimDailyReward Cloud Function
/// - All date/time validation is server-side
/// - Firestore rules prevent direct writes to reward fields
/// - Prevents cheating and manipulation
class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Claim daily login reward (SECURE - Server-side)
  ///
  /// This method calls the Cloud Function which:
  /// - Validates using server timestamp (can't be manipulated)
  /// - Calculates streak server-side
  /// - Awards points atomically
  /// - Records history
  ///
  /// Returns reward result or null on error
  Future<Map<String, dynamic>?> checkDailyLoginReward(String userId) async {
    try {
      AppLogger.info('Claiming daily reward for user $userId via Cloud Function');

      // Call Cloud Function to claim reward
      final callable = _functions.httpsCallable('claimDailyReward');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        AppLogger.info('Daily reward claim successful: ${data['message']}');
        return {
          'alreadyClaimed': data['alreadyClaimed'] ?? false,
          'streak': data['streak'] ?? 0,
          'points': data['points'] ?? 0,
          'earnedPoints': data['earnedPoints'] ?? 0,
          'isNewStreak': data['isNewStreak'] ?? false,
        };
      } else {
        AppLogger.warning('Daily reward claim failed: ${data['message']}');
        return null;
      }
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('Cloud Function error claiming daily reward', e);
      AppLogger.error('Code: ${e.code}, Message: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('Error claiming daily reward', e);
      return null;
    }
  }

  // Get reward history
  Future<List<Map<String, dynamic>>> getRewardHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rewardHistory')
          .orderBy('claimedAt', descending: true)
          .limit(30)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': data['type'],
          'points': data['points'],
          'streak': data['streak'],
          'claimedAt': (data['claimedAt'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user reward stats (SECURE - Server-side)
  ///
  /// Fetches current points, streak, and whether reward can be claimed today.
  /// Uses Cloud Function to ensure accurate server-side date checking.
  Future<Map<String, dynamic>> getUserRewardStats(String userId) async {
    try {
      AppLogger.debug('Fetching reward stats for user $userId via Cloud Function');

      // Call Cloud Function to get stats
      final callable = _functions.httpsCallable('getRewardStats');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return {
          'points': data['points'] ?? 0,
          'streak': data['streak'] ?? 0,
          'canClaimToday': data['canClaimToday'] ?? false,
          'lastClaimDate': data['lastClaimDate'],
        };
      } else {
        return {
          'points': 0,
          'streak': 0,
          'canClaimToday': true,
          'lastClaimDate': null,
        };
      }
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('Cloud Function error getting reward stats', e);
      return {
        'points': 0,
        'streak': 0,
        'canClaimToday': true,
        'lastClaimDate': null,
      };
    } catch (e) {
      AppLogger.error('Error getting reward stats', e);
      return {
        'points': 0,
        'streak': 0,
        'canClaimToday': true,
        'lastClaimDate': null,
      };
    }
  }
}
