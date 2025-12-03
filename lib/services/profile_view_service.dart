import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_view.dart';

class ProfileViewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Record a profile view
  Future<void> recordProfileView({
    required String viewerId,
    required String viewedUserId,
  }) async {
    // Don't record if user is viewing their own profile
    if (viewerId == viewedUserId) return;

    try {
      // Check if this user has viewed this profile in the last 24 hours
      final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));

      final existingViews = await _firestore
          .collection('profileViews')
          .where('viewerId', isEqualTo: viewerId)
          .where('viewedUserId', isEqualTo: viewedUserId)
          .where('viewedAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .limit(1)
          .get();

      // If no recent view exists, create a new one
      if (existingViews.docs.isEmpty) {
        final profileView = ProfileView(
          id: '',
          viewerId: viewerId,
          viewedUserId: viewedUserId,
          viewedAt: DateTime.now(),
          isRead: false,
        );

        await _firestore.collection('profileViews').add(profileView.toMap());
        print('Profile view recorded: $viewerId viewed $viewedUserId');
      } else {
        print('Recent view already exists, not recording duplicate');
      }
    } catch (e) {
      print('Error recording profile view: $e');
    }
  }

  // Get users who viewed my profile
  Stream<List<ProfileView>> getProfileViews(String userId) {
    return _firestore
        .collection('profileViews')
        .where('viewedUserId', isEqualTo: userId)
        .orderBy('viewedAt', descending: true)
        .limit(50) // Limit to last 50 views
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfileView.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get count of unread profile views
  Stream<int> getUnreadViewsCount(String userId) {
    return _firestore
        .collection('profileViews')
        .where('viewedUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark profile views as read
  Future<void> markViewsAsRead(String userId) async {
    try {
      final unreadViews = await _firestore
          .collection('profileViews')
          .where('viewedUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadViews.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('Marked ${unreadViews.docs.length} profile views as read');
    } catch (e) {
      print('Error marking views as read: $e');
    }
  }

  // Delete old profile views (older than 30 days)
  Future<void> deleteOldViews(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldViews = await _firestore
          .collection('profileViews')
          .where('viewedUserId', isEqualTo: userId)
          .where('viewedAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldViews.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Deleted ${oldViews.docs.length} old profile views');
    } catch (e) {
      print('Error deleting old views: $e');
    }
  }

  // Get total profile views count for a user
  Future<int> getTotalViewsCount(String userId) async {
    try {
      final views = await _firestore
          .collection('profileViews')
          .where('viewedUserId', isEqualTo: userId)
          .get();

      return views.docs.length;
    } catch (e) {
      print('Error getting total views count: $e');
      return 0;
    }
  }
}
