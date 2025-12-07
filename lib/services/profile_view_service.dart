import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_view_model.dart';

class ProfileViewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Record a profile view
  Future<void> recordProfileView({
    required String viewerId,
    required String viewedUserId,
  }) async {
    // Don't record if viewing own profile
    if (viewerId == viewedUserId) return;

    try {
      // Check if this user already viewed this profile recently (within last hour)
      final recentViews = await _firestore
          .collection('profileViews')
          .where('viewerId', isEqualTo: viewerId)
          .where('viewedUserId', isEqualTo: viewedUserId)
          .orderBy('viewedAt', descending: true)
          .limit(1)
          .get();

      if (recentViews.docs.isNotEmpty) {
        final lastView = recentViews.docs.first.data();
        final lastViewTime = (lastView['viewedAt'] as Timestamp).toDate();
        final timeDifference = DateTime.now().difference(lastViewTime);

        // Only record if last view was more than 1 hour ago
        if (timeDifference.inHours < 1) {
          return;
        }
      }

      // Create new profile view record
      final profileView = ProfileView(
        id: '',
        viewerId: viewerId,
        viewedUserId: viewedUserId,
        viewedAt: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('profileViews').add(profileView.toMap());

      // Update viewed user's profile view count
      await _firestore.collection('users').doc(viewedUserId).update({
        'profileViewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error recording profile view: $e');
    }
  }

  // Get profile views for a user
  Stream<List<ProfileView>> getProfileViews(String userId) {
    return _firestore
        .collection('profileViews')
        .where('viewedUserId', isEqualTo: userId)
        .orderBy('viewedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProfileView.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get unread profile view count
  Future<int> getUnreadViewCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('profileViews')
          .where('viewedUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread view count: $e');
      return 0;
    }
  }

  // Mark profile views as read
  Future<void> markViewsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection('profileViews')
          .where('viewedUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking views as read: $e');
    }
  }

  // Delete old profile views (older than 30 days)
  Future<void> cleanupOldViews() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('profileViews')
          .where('viewedAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up old views: $e');
    }
  }
}
