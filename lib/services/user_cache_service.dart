import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

/// Service for batch fetching and caching user data to avoid N+1 query problems
class UserCacheService {
  final Map<String, UserModel> _cache = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Batch fetch users by their IDs with caching
  /// Firestore 'in' query is limited to 10 items, so we batch in groups
  Future<Map<String, UserModel>> batchGetUsers(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    // Filter out cached users
    final uncachedIds = userIds.where((id) => !_cache.containsKey(id)).toList();

    // If all users are cached, return from cache
    if (uncachedIds.isEmpty) {
      return Map.fromEntries(
        userIds.map((id) => MapEntry(id, _cache[id]!)),
      );
    }

    try {
      final results = <String, UserModel>{};

      // Firestore 'in' query limited to 10 items, batch in groups
      for (var i = 0; i < uncachedIds.length; i += 10) {
        final batch = uncachedIds.sublist(
          i,
          min(i + 10, uncachedIds.length),
        );

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          final user = UserModel.fromMap(doc.data(), doc.id);
          _cache[doc.id] = user;
          results[doc.id] = user;
        }
      }

      // Add cached users to results
      for (var id in userIds) {
        if (_cache.containsKey(id) && !results.containsKey(id)) {
          results[id] = _cache[id]!;
        }
      }

      AppLogger.info('Batch fetched ${results.length} users (${uncachedIds.length} from Firestore, ${userIds.length - uncachedIds.length} from cache)');

      return results;
    } catch (e) {
      AppLogger.error('Error batch fetching users', e);
      rethrow;
    }
  }

  /// Get a single user from cache or fetch if not cached
  Future<UserModel?> getUser(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId];
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _cache[userId] = user;
        return user;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching user $userId', e);
      return null;
    }
  }

  /// Update cache for a specific user (call this when user data changes)
  void updateCache(String userId, UserModel user) {
    _cache[userId] = user;
  }

  /// Invalidate (remove) a user from cache
  void invalidate(String userId) {
    _cache.remove(userId);
  }

  /// Clear entire cache
  void clearCache() {
    _cache.clear();
    AppLogger.info('User cache cleared');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'userIds': _cache.keys.toList(),
    };
  }
}
