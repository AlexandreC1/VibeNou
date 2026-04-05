import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// MatchService - Handles like/pass/match logic for user discovery.
///
/// When user A likes user B:
///   - A "like" document is created in user A's likes subcollection
///   - If user B has already liked user A, a mutual match is created
///   - Both users are notified of the match
class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Like a user. Returns true if it's a mutual match.
  Future<bool> likeUser({
    required String currentUserId,
    required String currentUserName,
    required String likedUserId,
    required String likedUserName,
  }) async {
    try {
      // Record the like
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .doc(likedUserId)
          .set({
        'userId': likedUserId,
        'userName': likedUserName,
        'likedAt': FieldValue.serverTimestamp(),
      });

      // Check if the other user has already liked us (mutual match)
      final otherLike = await _firestore
          .collection('users')
          .doc(likedUserId)
          .collection('likes')
          .doc(currentUserId)
          .get();

      if (otherLike.exists) {
        // It's a match! Create match documents for both users
        final matchId = _generateMatchId(currentUserId, likedUserId);

        await _firestore.collection('matches').doc(matchId).set({
          'userId1': currentUserId,
          'userId2': likedUserId,
          'userName1': currentUserName,
          'userName2': likedUserName,
          'matchedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('MatchService: Error liking user: $e');
      rethrow;
    }
  }

  /// Pass on a user (swipe left).
  Future<void> passUser({
    required String currentUserId,
    required String passedUserId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('passes')
          .doc(passedUserId)
          .set({
        'userId': passedUserId,
        'passedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('MatchService: Error passing user: $e');
    }
  }

  /// Check if current user has already liked a specific user.
  Future<bool> hasLiked({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .doc(otherUserId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all matches for a user.
  Stream<List<Map<String, dynamic>>> getMatches(String userId) {
    return _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              return data['userId1'] == userId || data['userId2'] == userId;
            })
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Generate a deterministic match ID from two user IDs.
  String _generateMatchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
