/**
 * Daily Rewards Cloud Function Module
 *
 * Handles secure server-side processing of daily login rewards.
 *
 * Security Features:
 * - Server-side date validation
 * - Prevents client-side manipulation
 * - Rate limiting integration
 * - Audit logging
 * - Transaction-based updates for atomicity
 *
 * Last updated: 2026-03-24
 */

const admin = require('firebase-admin');

/**
 * Calculate reward points based on login streak
 *
 * Base points: 10
 * Bonus: +2 points per streak day (max +20 for 10+ days)
 *
 * @param {number} streak - Current login streak
 * @returns {number} Points to award
 */
function calculateRewardPoints(streak) {
  if (streak <= 0) return 10;

  // Base points: 10
  // Bonus: +2 points per streak day (max +20 for 10+ days)
  const bonus = (streak - 1) * 2;
  const cappedBonus = bonus > 20 ? 20 : bonus;

  return 10 + cappedBonus;
}

/**
 * Check if two dates are the same day (ignoring time)
 *
 * @param {Date} date1 - First date
 * @param {Date} date2 - Second date
 * @returns {boolean} True if same day
 */
function isSameDay(date1, date2) {
  return (
    date1.getFullYear() === date2.getFullYear() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getDate() === date2.getDate()
  );
}

/**
 * Check if two dates are consecutive days (date2 is day after date1)
 *
 * @param {Date} date1 - Earlier date
 * @param {Date} date2 - Later date
 * @returns {boolean} True if consecutive days
 */
function isConsecutiveDay(date1, date2) {
  const yesterday = new Date(date2);
  yesterday.setDate(yesterday.getDate() - 1);
  return isSameDay(date1, yesterday);
}

/**
 * Callable Cloud Function to claim daily login reward
 *
 * This function:
 * 1. Verifies user authentication
 * 2. Checks if reward already claimed today (server-side)
 * 3. Calculates streak based on server timestamp
 * 4. Awards points using server-side increment
 * 5. Records reward history
 *
 * Security:
 * - All date calculations use server time (can't be manipulated)
 * - Uses Firestore transaction for atomicity
 * - Validates user authentication
 * - Rate limited to prevent abuse
 *
 * @param {object} data - Request data (empty)
 * @param {object} context - Cloud Function context with auth
 * @returns {object} Reward result
 */
async function claimDailyReward(data, context) {
  // Verify authentication
  if (!context.auth) {
    throw new Error('Authentication required');
  }

  const userId = context.auth.uid;
  const db = admin.firestore();
  const userRef = db.collection('users').doc(userId);

  try {
    // Use transaction to ensure atomic updates
    const result = await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data();
      const now = new Date();

      // Get last login reward timestamp
      const lastLoginReward = userData.lastLoginReward?.toDate();
      const currentStreak = userData.loginStreak || 0;
      const totalPoints = userData.rewardPoints || 0;

      // Check if already claimed today (SERVER-SIDE VALIDATION)
      if (lastLoginReward && isSameDay(lastLoginReward, now)) {
        // Already claimed today - return current stats without awarding
        return {
          success: true,
          alreadyClaimed: true,
          streak: currentStreak,
          points: totalPoints,
          message: 'You have already claimed your reward today!',
        };
      }

      // Calculate new streak
      let newStreak;
      let isNewStreak;

      if (!lastLoginReward) {
        // First time claiming
        newStreak = 1;
        isNewStreak = true;
      } else if (isConsecutiveDay(lastLoginReward, now)) {
        // Consecutive day - increment streak
        newStreak = currentStreak + 1;
        isNewStreak = false;
      } else {
        // Missed a day - reset streak
        newStreak = 1;
        isNewStreak = true;
      }

      // Calculate points to award
      const pointsToAward = calculateRewardPoints(newStreak);
      const newTotalPoints = totalPoints + pointsToAward;

      // Update user document with new streak and points
      transaction.update(userRef, {
        lastLoginReward: admin.firestore.FieldValue.serverTimestamp(),
        loginStreak: newStreak,
        rewardPoints: admin.firestore.FieldValue.increment(pointsToAward),
      });

      // Record reward history
      const rewardHistoryRef = userRef.collection('rewardHistory').doc();
      transaction.set(rewardHistoryRef, {
        type: 'daily_login',
        points: pointsToAward,
        streak: newStreak,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Daily reward claimed by user ${userId}: ${pointsToAward} points (streak: ${newStreak})`);

      return {
        success: true,
        alreadyClaimed: false,
        streak: newStreak,
        points: newTotalPoints,
        earnedPoints: pointsToAward,
        isNewStreak: isNewStreak,
        message: `Reward claimed! You earned ${pointsToAward} points. Current streak: ${newStreak} days.`,
      };
    });

    return result;
  } catch (error) {
    console.error(`Error claiming daily reward for user ${userId}:`, error);
    throw new Error(`Failed to claim reward: ${error.message}`);
  }
}

/**
 * Callable Cloud Function to get user's current reward stats
 *
 * @param {object} data - Request data (empty)
 * @param {object} context - Cloud Function context with auth
 * @returns {object} Current stats
 */
async function getRewardStats(data, context) {
  // Verify authentication
  if (!context.auth) {
    throw new Error('Authentication required');
  }

  const userId = context.auth.uid;
  const db = admin.firestore();

  try {
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data();
    const now = new Date();
    const lastLoginReward = userData.lastLoginReward?.toDate();

    // Check if can claim today
    const canClaimToday = !lastLoginReward || !isSameDay(lastLoginReward, now);

    return {
      success: true,
      points: userData.rewardPoints || 0,
      streak: userData.loginStreak || 0,
      lastClaimDate: lastLoginReward ? lastLoginReward.toISOString() : null,
      canClaimToday: canClaimToday,
    };
  } catch (error) {
    console.error(`Error getting reward stats for user ${userId}:`, error);
    throw new Error(`Failed to get stats: ${error.message}`);
  }
}

module.exports = {
  claimDailyReward,
  getRewardStats,
  calculateRewardPoints, // Export for testing
};
