import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

/// One-time migration script to grandfather existing beta users
/// Marks all users created before the email verification feature
/// as verified so they can continue using the app
class BetaUserMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cutoff date for beta users (today - when email verification was added)
  /// All users created before this date will be marked as verified
  final DateTime cutoffDate = DateTime(2024, 12, 23);

  /// Run migration to mark beta users as verified
  /// This should be run once after deploying email verification feature
  Future<void> migrateBetaUsers() async {
    try {
      AppLogger.info('Starting beta user migration...');

      // Get all users created before cutoff date
      final snapshot = await _firestore
          .collection('users')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('No beta users found to migrate');
        return;
      }

      AppLogger.info('Found ${snapshot.docs.length} beta users to migrate');

      int successCount = 0;
      int errorCount = 0;

      // Batch updates for better performance
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (var doc in snapshot.docs) {
        try {
          // Mark user as verified (grandfathered)
          batch.update(doc.reference, {
            'emailVerified': true,
            'emailVerifiedAt': FieldValue.serverTimestamp(),
            'grandfathered': true, // Flag to indicate this was a beta user
            'migratedAt': FieldValue.serverTimestamp(),
          });

          batchCount++;

          // Firestore batch limit is 500 operations
          if (batchCount >= 500) {
            await batch.commit();
            successCount += batchCount;
            AppLogger.info('Committed batch of $batchCount users');

            // Start new batch
            batch = _firestore.batch();
            batchCount = 0;
          }
        } catch (e) {
          AppLogger.error('Failed to migrate user ${doc.id}', e);
          errorCount++;
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
        successCount += batchCount;
        AppLogger.info('Committed final batch of $batchCount users');
      }

      AppLogger.info(
        'Beta user migration completed: '
        '$successCount successful, $errorCount errors',
      );
    } catch (e) {
      AppLogger.error('Beta user migration failed', e);
      rethrow;
    }
  }

  /// Verify migration results
  /// Returns count of migrated users
  Future<int> verifyMigration() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('grandfathered', isEqualTo: true)
          .get();

      final count = snapshot.docs.length;
      AppLogger.info('Found $count grandfathered beta users');

      return count;
    } catch (e) {
      AppLogger.error('Failed to verify migration', e);
      return 0;
    }
  }

  /// Get migration status for a specific user
  Future<Map<String, dynamic>> getUserMigrationStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return {'exists': false};
      }

      final data = doc.data()!;

      return {
        'exists': true,
        'emailVerified': data['emailVerified'] ?? false,
        'grandfathered': data['grandfathered'] ?? false,
        'createdAt': data['createdAt'],
        'migratedAt': data['migratedAt'],
      };
    } catch (e) {
      AppLogger.error('Failed to get user migration status', e);
      return {'error': e.toString()};
    }
  }

  /// Rollback migration (for testing purposes only)
  /// WARNING: Use with caution!
  Future<void> rollbackMigration() async {
    try {
      AppLogger.warning('Starting migration rollback...');

      final snapshot = await _firestore
          .collection('users')
          .where('grandfathered', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('No migrated users found to rollback');
        return;
      }

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'emailVerified': FieldValue.delete(),
          'emailVerifiedAt': FieldValue.delete(),
          'grandfathered': FieldValue.delete(),
          'migratedAt': FieldValue.delete(),
        });

        count++;

        if (count >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      AppLogger.info('Migration rollback completed');
    } catch (e) {
      AppLogger.error('Rollback failed', e);
      rethrow;
    }
  }
}
