import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add user to favorites
  Future<void> addFavorite({
    required String userId,
    required String favoriteUserId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(favoriteUserId)
          .set({
        'userId': favoriteUserId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  // Remove user from favorites
  Future<void> removeFavorite({
    required String userId,
    required String favoriteUserId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(favoriteUserId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  // Check if user is favorited
  Future<bool> isFavorite({
    required String userId,
    required String favoriteUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(favoriteUserId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all favorites for a user
  Stream<List<String>> getFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Get favorite count
  Future<int> getFavoriteCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
