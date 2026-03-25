const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onCall} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");

admin.initializeApp();

// Import persistent rate limiter
const rateLimiter = require("./src/rateLimiter");

// Import audit logging
const auditLog = require("./src/auditLog");

// Import CAPTCHA verification
const captcha = require("./src/captcha");

// Import daily rewards
const dailyRewards = require("./src/dailyRewards");

/**
 * Cloud Function to send push notifications when a notification is queued
 * Triggered when a document is created in the notifications_queue collection
 * Includes rate limiting to prevent spam
 */
exports.sendPushNotification = onDocumentCreated(
    "notifications_queue/{notificationId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("No data associated with the event");
        return;
      }

      const notification = snapshot.data();
      const notificationId = event.params.notificationId;

      // Check if already processed
      if (notification.processed) {
        console.log(`Notification ${notificationId} already processed`);
        return;
      }

      // Rate limit: Max 60 notifications per minute per recipient (persistent)
      const recipientId = notification.recipientId;
      const rateLimitCheck = await rateLimiter.checkRateLimit(recipientId, "notifications");

      if (!rateLimitCheck.allowed) {
        console.warn(`Rate limit exceeded for recipient ${recipientId}`);
        await snapshot.ref.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          error: "Rate limit exceeded",
          resetAt: rateLimitCheck.resetAt,
        });
        return;
      }

      try {
        // Extract notification data
        const {
          recipientId,
          recipientToken,
          title,
          body,
          data,
          type,
        } = notification;

        if (!recipientToken) {
          console.log(`No FCM token for recipient ${recipientId}`);
          await snapshot.ref.update({processed: true});
          return;
        }

        // Prepare FCM message
        const message = {
          token: recipientToken,
          notification: {
            title: title || "New Notification",
            body: body || "",
          },
          data: {
            ...data,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            notification: {
              channelId: "vibenou_messages",
              priority: "high",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send the notification
        const response = await admin.messaging().send(message);
        console.log(`Successfully sent notification ${notificationId}:`, response);

        // Mark as processed
        await snapshot.ref.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          fcmResponse: response,
        });
      } catch (error) {
        console.error(`Error sending notification ${notificationId}:`, error);

        // Mark as processed with error
        await snapshot.ref.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          error: error.message,
        });
      }
    }
);

/**
 * Cloud Function to clean up old processed notifications
 * Runs every day at midnight
 */
exports.cleanupProcessedNotifications = onSchedule("every day 00:00", async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const sevenDaysAgo = new admin.firestore.Timestamp(
      now.seconds - 7 * 24 * 60 * 60,
      now.nanoseconds
  );

  try {
    // Delete notifications processed more than 7 days ago
    const snapshot = await db
        .collection("notifications_queue")
        .where("processed", "==", true)
        .where("processedAt", "<", sevenDaysAgo)
        .get();

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${snapshot.size} old notifications`);
  } catch (error) {
    console.error("Error cleaning up notifications:", error);
  }
});

/**
 * Callable function to check rate limit from client
 * Allows apps to check rate limits before attempting actions
 */
exports.checkRateLimit = onCall(async (request) => {
  return await rateLimiter.checkRateLimitCallable(request.data, request.auth);
});

/**
 * Callable function to get rate limit status
 * Shows users their current rate limit usage
 */
exports.getRateLimitStatus = onCall(async (request) => {
  return await rateLimiter.getRateLimitStatusCallable(request.data, request.auth);
});

/**
 * Scheduled function to cleanup expired rate limit records
 * Runs daily at 3 AM to remove old rate limit data
 */
exports.cleanupRateLimits = onSchedule("every day 03:00", async (event) => {
  try {
    const result = await rateLimiter.cleanupExpiredRateLimits();
    console.log(`Rate limit cleanup completed:`, result);
    return result;
  } catch (error) {
    console.error("Error in rate limit cleanup:", error);
    throw error;
  }
});

/**
 * Audit user profile changes
 * Triggers on any user document update
 */
exports.auditUserProfileChanges = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    return await auditLog.auditUserProfileChanges(event.data, event);
  }
);

/**
 * Audit report submissions
 * Triggers when a new report is created
 */
exports.auditReportSubmission = onDocumentCreated(
  "reports/{reportId}",
  async (event) => {
    return await auditLog.auditReportSubmission(event.data, event);
  }
);

/**
 * Cleanup old audit logs
 * Runs daily at 4 AM
 */
exports.cleanupAuditLogs = onSchedule("every day 04:00", async (event) => {
  try {
    const result = await auditLog.cleanupOldAuditLogs();
    console.log(`Audit log cleanup completed:`, result);
    return result;
  } catch (error) {
    console.error("Error in audit log cleanup:", error);
    throw error;
  }
});

/**
 * Callable function to verify reCAPTCHA token
 * Allows client apps to verify CAPTCHA with appropriate thresholds
 */
exports.verifyRecaptcha = onCall(async (request) => {
  return await captcha.verifyRecaptchaCallable(request.data, request);
});

/**
 * Callable function to claim daily login reward
 * Secure server-side reward processing with streak tracking
 */
exports.claimDailyReward = onCall(async (request) => {
  return await dailyRewards.claimDailyReward(request.data, request);
});

/**
 * Callable function to get user's reward stats
 * Returns current points, streak, and claim eligibility
 */
exports.getRewardStats = onCall(async (request) => {
  return await dailyRewards.getRewardStats(request.data, request);
});

/**
 * Storage trigger to enforce upload rate limiting
 * Monitors file uploads and deletes files that exceed rate limits
 * Prevents storage abuse and cost overruns
 */
exports.enforceUploadRateLimit = onObjectFinalized(async (event) => {
  const filePath = event.data.name;
  const contentType = event.data.contentType;

  // Only monitor profile picture uploads
  if (!filePath.startsWith('profile_pictures/')) {
    return;
  }

  // Extract userId from file path
  // Expected formats: profile_pictures/profile_userId.jpg or profile_pictures/userId_timestamp.jpg
  let userId;
  const fileName = filePath.split('/').pop();

  if (fileName.startsWith('profile_')) {
    // Format: profile_userId.jpg
    userId = fileName.replace('profile_', '').replace('.jpg', '').replace('.png', '').replace('.webp', '');
  } else {
    // Format: userId_timestamp.jpg
    userId = fileName.split('_')[0];
  }

  if (!userId) {
    console.warn(`Could not extract userId from file path: ${filePath}`);
    return;
  }

  try {
    // Check rate limit (10 uploads per hour)
    const rateLimitResult = await rateLimiter.checkRateLimit(userId, 'uploads');

    if (!rateLimitResult.allowed) {
      console.warn(`Upload rate limit exceeded for user ${userId}. Deleting file: ${filePath}`);

      // Delete the uploaded file
      const bucket = admin.storage().bucket(event.data.bucket);
      await bucket.file(filePath).delete();

      // Log security event
      await admin.firestore().collection('security_events').add({
        userId: userId,
        eventType: 'upload_rate_limit_exceeded',
        severity: 'medium',
        description: `User exceeded upload rate limit (10 per hour). File deleted: ${filePath}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          filePath: filePath,
          contentType: contentType,
          resetAt: new Date(rateLimitResult.resetAt).toISOString(),
        },
      });

      console.log(`File deleted and security event logged for user ${userId}`);
    } else {
      console.log(`Upload allowed for user ${userId}. Remaining: ${rateLimitResult.remaining}/10`);
    }
  } catch (error) {
    console.error(`Error enforcing upload rate limit for ${userId}:`, error);
    // Don't throw - allow upload to succeed if rate limiting fails (fail open)
  }
});
