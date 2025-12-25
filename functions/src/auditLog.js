/**
 * Audit Logging Cloud Functions
 * Automatically log critical security events
 */

const admin = require('firebase-admin');

/**
 * Monitor user profile changes and log to audit
 */
async function auditUserProfileChanges(change, context) {
  const before = change.before.data();
  const after = change.after.data();
  const userId = context.params.userId;

  const db = admin.firestore();
  const logBatch = [];

  try {
    // Detect email change
    if (before.email !== after.email) {
      logBatch.push({
        userId: userId,
        eventType: 'email_changed',
        severity: 'critical',
        description: `Email changed from ${before.email} to ${after.email}`,
        metadata: {
          oldEmail: before.email,
          newEmail: after.email,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Detect profile photo change
    if (before.photoUrl !== after.photoUrl) {
      logBatch.push({
        userId: userId,
        eventType: 'profile_photo_changed',
        severity: 'info',
        description: 'User changed their profile photo',
        metadata: {
          oldPhotoUrl: before.photoUrl,
          newPhotoUrl: after.photoUrl,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Detect 2FA changes
    if (before.twoFactorEnabled !== after.twoFactorEnabled) {
      logBatch.push({
        userId: userId,
        eventType: after.twoFactorEnabled ? 'two_factor_enabled' : 'two_factor_disabled',
        severity: after.twoFactorEnabled ? 'info' : 'warning',
        description: after.twoFactorEnabled
          ? 'User enabled two-factor authentication'
          : 'User disabled two-factor authentication',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Write all logs
    for (const log of logBatch) {
      // User-specific log
      await db
        .collection('auditLogs')
        .doc(userId)
        .collection('events')
        .add(log);

      // Global log for critical events
      if (log.severity === 'critical' || log.severity === 'warning') {
        await db.collection('globalAuditLogs').add(log);
      }
    }

    if (logBatch.length > 0) {
      console.log(`Logged ${logBatch.length} audit events for user ${userId}`);
    }
  } catch (error) {
    console.error('Error in audit logging:', error);
  }
}

/**
 * Monitor report submissions
 */
async function auditReportSubmission(snapshot, context) {
  const report = snapshot.data();
  const reportId = context.params.reportId;
  const db = admin.firestore();

  try {
    const logData = {
      userId: report.reporterId,
      eventType: 'user_reported',
      severity: 'warning',
      description: `User reported another user`,
      metadata: {
        reportedUserId: report.reportedUserId,
        category: report.category,
        reason: report.reason,
        reportId: reportId,
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // User-specific log
    await db
      .collection('auditLogs')
      .doc(report.reporterId)
      .collection('events')
      .add(logData);

    // Global log
    await db.collection('globalAuditLogs').add(logData);

    console.log(`Audit log created for report ${reportId}`);
  } catch (error) {
    console.error('Error auditing report submission:', error);
  }
}

/**
 * Cleanup old audit logs (scheduled daily)
 * Keeps logs for 90 days for regular events, 1 year for critical
 */
async function cleanupOldAuditLogs() {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // 90 days for regular logs
  const nineDaysAgo = new admin.firestore.Timestamp(
    now.seconds - 90 * 24 * 60 * 60,
    now.nanoseconds
  );

  // 1 year for critical logs
  const oneYearAgo = new admin.firestore.Timestamp(
    now.seconds - 365 * 24 * 60 * 60,
    now.nanoseconds
  );

  let totalDeleted = 0;

  try {
    // Get all users with audit logs
    const usersSnapshot = await db.collection('auditLogs').listDocuments();

    for (const userDoc of usersSnapshot) {
      // Delete non-critical old logs
      const regularLogsSnapshot = await userDoc
        .collection('events')
        .where('severity', '==', 'info')
        .where('timestamp', '<', nineDaysAgo)
        .limit(500)
        .get();

      const batch = db.batch();
      regularLogsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      if (regularLogsSnapshot.size > 0) {
        await batch.commit();
        totalDeleted += regularLogsSnapshot.size;
      }

      // Delete old critical logs (after 1 year)
      const criticalLogsSnapshot = await userDoc
        .collection('events')
        .where('severity', 'in', ['warning', 'critical'])
        .where('timestamp', '<', oneYearAgo)
        .limit(500)
        .get();

      const criticalBatch = db.batch();
      criticalLogsSnapshot.docs.forEach((doc) => {
        criticalBatch.delete(doc.ref);
      });

      if (criticalLogsSnapshot.size > 0) {
        await criticalBatch.commit();
        totalDeleted += criticalLogsSnapshot.size;
      }
    }

    console.log(`Cleaned up ${totalDeleted} old audit log entries`);
    return { deleted: totalDeleted };
  } catch (error) {
    console.error('Error cleaning up audit logs:', error);
    throw error;
  }
}

module.exports = {
  auditUserProfileChanges,
  auditReportSubmission,
  cleanupOldAuditLogs,
};
