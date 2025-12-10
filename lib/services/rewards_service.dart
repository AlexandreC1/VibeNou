import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check and award daily login reward
  Future<Map<String, dynamic>?> checkDailyLoginReward(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final lastLogin = (data['lastLoginReward'] as Timestamp?)?.toDate();
      final currentStreak = data['loginStreak'] ?? 0;
      final totalPoints = data['rewardPoints'] ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if reward already claimed today
      if (lastLogin != null) {
        final lastLoginDate = DateTime(
          lastLogin.year,
          lastLogin.month,
          lastLogin.day,
        );

        if (lastLoginDate == today) {
          // Already claimed today
          return {
            'alreadyClaimed': true,
            'streak': currentStreak,
            'points': totalPoints,
          };
        }

        // Check if streak continues (logged in yesterday)
        final yesterday = today.subtract(const Duration(days: 1));
        final isConsecutive = lastLoginDate == yesterday;

        final newStreak = isConsecutive ? currentStreak + 1 : 1;
        final pointsToAward = _calculateRewardPoints(newStreak);

        // Update user data
        await _firestore.collection('users').doc(userId).update({
          'lastLoginReward': FieldValue.serverTimestamp(),
          'loginStreak': newStreak,
          'rewardPoints': FieldValue.increment(pointsToAward),
        });

        // Record reward history
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rewardHistory')
            .add({
          'type': 'daily_login',
          'points': pointsToAward,
          'streak': newStreak,
          'claimedAt': FieldValue.serverTimestamp(),
        });

        return {
          'alreadyClaimed': false,
          'streak': newStreak,
          'points': totalPoints + pointsToAward,
          'earnedPoints': pointsToAward,
          'isNewStreak': !isConsecutive,
        };
      } else {
        // First time login reward
        const pointsToAward = 10;

        await _firestore.collection('users').doc(userId).update({
          'lastLoginReward': FieldValue.serverTimestamp(),
          'loginStreak': 1,
          'rewardPoints': FieldValue.increment(pointsToAward),
        });

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rewardHistory')
            .add({
          'type': 'daily_login',
          'points': pointsToAward,
          'streak': 1,
          'claimedAt': FieldValue.serverTimestamp(),
        });

        return {
          'alreadyClaimed': false,
          'streak': 1,
          'points': pointsToAward,
          'earnedPoints': pointsToAward,
          'isNewStreak': true,
        };
      }
    } catch (e) {
      return null;
    }
  }

  // Calculate reward points based on streak
  int _calculateRewardPoints(int streak) {
    if (streak <= 0) return 10;

    // Base points: 10
    // Bonus: +2 points per streak day (max +20 for 10+ days)
    final bonus = (streak - 1) * 2;
    final cappedBonus = bonus > 20 ? 20 : bonus;

    return 10 + cappedBonus;
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

  // Get user points and streak
  Future<Map<String, int>> getUserRewardStats(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return {'points': 0, 'streak': 0};
      }

      final data = doc.data()!;
      return {
        'points': data['rewardPoints'] ?? 0,
        'streak': data['loginStreak'] ?? 0,
      };
    } catch (e) {
      return {'points': 0, 'streak': 0};
    }
  }
}
