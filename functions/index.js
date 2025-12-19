const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to send push notifications when a notification is queued
 * Triggered when a document is created in the notifications_queue collection
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
exports.cleanupProcessedNotifications = require("firebase-functions/v2/scheduler")
    .onSchedule("every day 00:00", async (event) => {
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
