/**
 * Persistent Rate Limiter using Firestore
 * Implements sliding window algorithm to prevent bot attacks and DoS
 *
 * Unlike in-memory rate limiting, this persists across Cloud Function cold starts
 */

const admin = require('firebase-admin');

// Rate limiting configuration
const RATE_LIMITS = {
  messages: { limit: 60, windowSeconds: 60 },           // 60 messages per minute
  profileUpdates: { limit: 10, windowSeconds: 3600 },   // 10 updates per hour
  likes: { limit: 100, windowSeconds: 3600 },           // 100 likes per hour
  apiCalls: { limit: 1000, windowSeconds: 3600 },       // 1000 API calls per hour
  notifications: { limit: 60, windowSeconds: 60 },      // 60 notifications per minute
  reports: { limit: 10, windowSeconds: 3600 },          // 10 reports per hour
  blocks: { limit: 20, windowSeconds: 3600 },           // 20 blocks per hour
};

/**
 * Check if user has exceeded rate limit
 * Uses sliding window algorithm with Firestore for persistence
 *
 * @param {string} userId - User identifier
 * @param {string} action - Action type (messages, likes, etc.)
 * @returns {Promise<{allowed: boolean, remaining: number, resetAt: number}>}
 */
async function checkRateLimit(userId, action) {
  const config = RATE_LIMITS[action];

  if (!config) {
    throw new Error(`Unknown action type: ${action}`);
  }

  const { limit, windowSeconds } = config;
  const now = Date.now();
  const windowStart = now - (windowSeconds * 1000);

  const db = admin.firestore();
  const rateLimitRef = db.collection('rateLimits').doc(`${userId}_${action}`);

  try {
    // Use transaction to ensure atomic read-modify-write
    const result = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(rateLimitRef);

      let requests = [];
      let metadata = {
        firstRequestAt: now,
        lastRequestAt: now,
      };

      if (doc.exists) {
        const data = doc.data();
        requests = (data.requests || []).filter(timestamp => timestamp > windowStart);
        metadata = {
          firstRequestAt: data.firstRequestAt || now,
          lastRequestAt: now,
        };
      }

      // Check if rate limit exceeded
      if (requests.length >= limit) {
        // Calculate when the oldest request will expire
        const oldestRequest = Math.min(...requests);
        const resetAt = oldestRequest + (windowSeconds * 1000);

        return {
          allowed: false,
          remaining: 0,
          resetAt: resetAt,
          limitExceeded: true,
        };
      }

      // Add current request timestamp
      requests.push(now);

      // Store updated request list
      transaction.set(rateLimitRef, {
        requests: requests,
        lastUpdate: now,
        ...metadata,
      }, { merge: true });

      return {
        allowed: true,
        remaining: limit - requests.length,
        resetAt: now + (windowSeconds * 1000),
        limitExceeded: false,
      };
    });

    return result;
  } catch (error) {
    console.error(`Rate limit check failed for ${userId}_${action}:`, error);

    // Fail open - allow request if rate limiting fails
    // This prevents legitimate users from being blocked by system errors
    return {
      allowed: true,
      remaining: limit,
      resetAt: now + (windowSeconds * 1000),
      error: error.message,
    };
  }
}

/**
 * Reset rate limit for a user/action
 * Useful for admin overrides or testing
 *
 * @param {string} userId - User identifier
 * @param {string} action - Action type
 */
async function resetRateLimit(userId, action) {
  const db = admin.firestore();
  const rateLimitRef = db.collection('rateLimits').doc(`${userId}_${action}`);

  await rateLimitRef.delete();
  console.log(`Rate limit reset for ${userId}_${action}`);
}

/**
 * Get current rate limit status for a user/action
 * Useful for displaying rate limit info to users
 *
 * @param {string} userId - User identifier
 * @param {string} action - Action type
 * @returns {Promise<{used: number, limit: number, remaining: number, resetAt: number}>}
 */
async function getRateLimitStatus(userId, action) {
  const config = RATE_LIMITS[action];

  if (!config) {
    throw new Error(`Unknown action type: ${action}`);
  }

  const { limit, windowSeconds } = config;
  const now = Date.now();
  const windowStart = now - (windowSeconds * 1000);

  const db = admin.firestore();
  const rateLimitRef = db.collection('rateLimits').doc(`${userId}_${action}`);

  try {
    const doc = await rateLimitRef.get();

    if (!doc.exists) {
      return {
        used: 0,
        limit: limit,
        remaining: limit,
        resetAt: now + (windowSeconds * 1000),
      };
    }

    const data = doc.data();
    const requests = (data.requests || []).filter(timestamp => timestamp > windowStart);

    const oldestRequest = requests.length > 0 ? Math.min(...requests) : now;
    const resetAt = oldestRequest + (windowSeconds * 1000);

    return {
      used: requests.length,
      limit: limit,
      remaining: Math.max(0, limit - requests.length),
      resetAt: resetAt,
    };
  } catch (error) {
    console.error(`Failed to get rate limit status for ${userId}_${action}:`, error);
    return {
      used: 0,
      limit: limit,
      remaining: limit,
      resetAt: now + (windowSeconds * 1000),
      error: error.message,
    };
  }
}

/**
 * Cleanup old rate limit records
 * Should be run periodically via scheduled Cloud Function
 * Removes rate limit documents where all requests are outside the window
 */
async function cleanupExpiredRateLimits() {
  const db = admin.firestore();
  const now = Date.now();
  let deletedCount = 0;

  try {
    // Get all rate limit documents
    const snapshot = await db.collection('rateLimits').limit(500).get();

    const batch = db.batch();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const lastUpdate = data.lastUpdate || 0;

      // Delete if no activity in 24 hours
      if (now - lastUpdate > 24 * 60 * 60 * 1000) {
        batch.delete(doc.ref);
        deletedCount++;
      }
    }

    if (deletedCount > 0) {
      await batch.commit();
      console.log(`Cleaned up ${deletedCount} expired rate limit records`);
    }

    return { deleted: deletedCount };
  } catch (error) {
    console.error('Error cleaning up rate limits:', error);
    throw error;
  }
}

/**
 * Callable Cloud Function to check rate limit from client
 * Allows client apps to check rate limits before attempting actions
 */
async function checkRateLimitCallable(data, context) {
  // Verify user is authenticated
  if (!context.auth) {
    throw new Error('Unauthenticated');
  }

  const userId = context.auth.uid;
  const action = data.action;

  if (!action) {
    throw new Error('Action parameter required');
  }

  const result = await checkRateLimit(userId, action);
  return result;
}

/**
 * Get rate limit status callable function
 */
async function getRateLimitStatusCallable(data, context) {
  if (!context.auth) {
    throw new Error('Unauthenticated');
  }

  const userId = context.auth.uid;
  const action = data.action;

  if (!action) {
    throw new Error('Action parameter required');
  }

  const status = await getRateLimitStatus(userId, action);
  return status;
}

module.exports = {
  checkRateLimit,
  resetRateLimit,
  getRateLimitStatus,
  cleanupExpiredRateLimits,
  checkRateLimitCallable,
  getRateLimitStatusCallable,
  RATE_LIMITS,
};
