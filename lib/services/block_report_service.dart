import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// Service for blocking and reporting users
class BlockReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Block a user
  /// @param currentUserId - ID of the user doing the blocking
  /// @param blockedUserId - ID of the user being blocked
  /// @param reason - Reason for blocking (optional)
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
    String reason = 'Blocked by user',
  }) async {
    try {
      if (currentUserId == blockedUserId) {
        throw ArgumentError('Cannot block yourself');
      }

      // Add to blockedUsers subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .set({
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
        'reason': reason,
      });

      AppLogger.info('User $blockedUserId blocked by $currentUserId');
    } catch (e) {
      AppLogger.error('Error blocking user', e);
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();

      AppLogger.info('User $blockedUserId unblocked by $currentUserId');
    } catch (e) {
      AppLogger.error('Error unblocking user', e);
      rethrow;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked({
    required String currentUserId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      AppLogger.error('Error checking if user is blocked', e);
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      AppLogger.error('Error getting blocked users', e);
      return [];
    }
  }

  /// Report a user
  /// @param reporterId - ID of the user making the report
  /// @param reportedUserId - ID of the user being reported
  /// @param category - Category of the report
  /// @param reason - Detailed reason for the report
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String category,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      if (reporterId == reportedUserId) {
        throw ArgumentError('Cannot report yourself');
      }

      // Validate category
      final validCategories = ['spam', 'harassment', 'inappropriate', 'fake', 'other'];
      if (!validCategories.contains(category)) {
        throw ArgumentError('Invalid report category: $category');
      }

      // Validate reason length
      if (reason.trim().isEmpty || reason.length > 500) {
        throw ArgumentError('Reason must be between 1 and 500 characters');
      }

      // Create report document
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'category': category,
        'reason': reason.trim(),
        'additionalInfo': additionalInfo?.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved, dismissed
        'reviewed': false,
      });

      AppLogger.info('User $reportedUserId reported by $reporterId for $category');
    } catch (e) {
      AppLogger.error('Error reporting user', e);
      rethrow;
    }
  }

  /// Get reports made by a user
  Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'reportedUserId': data['reportedUserId'],
          'category': data['category'],
          'reason': data['reason'],
          'status': data['status'] ?? 'pending',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting user reports', e);
      return [];
    }
  }

  /// Check if user has already reported another user
  Future<bool> hasUserReportedUser({
    required String reporterId,
    required String reportedUserId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking if user has reported', e);
      return false;
    }
  }

  /// Block and report a user (common action)
  Future<void> blockAndReportUser({
    required String currentUserId,
    required String userId,
    required String category,
    required String reason,
  }) async {
    try {
      // Block the user first
      await blockUser(
        currentUserId: currentUserId,
        blockedUserId: userId,
        reason: reason,
      );

      // Then report them
      await reportUser(
        reporterId: currentUserId,
        reportedUserId: userId,
        category: category,
        reason: reason,
      );

      AppLogger.info('User $userId blocked and reported by $currentUserId');
    } catch (e) {
      AppLogger.error('Error blocking and reporting user', e);
      rethrow;
    }
  }
}
