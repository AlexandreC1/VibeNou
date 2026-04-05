import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';
import '../utils/geohash.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Maximum number of users to return per discovery query.
  static const int _discoveryLimit = 50;

  // Get all users (for discovery) - kept for backward compatibility
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .limit(_discoveryLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get nearby users using geohash-based Firestore range queries.
  ///
  /// Instead of fetching all users and filtering in memory, this queries
  /// Firestore using geohash prefix ranges to only fetch users in the
  /// approximate area, then applies exact Haversine distance as a post-filter.
  Future<List<UserModel>> getNearbyUsers({
    required String currentUserId,
    required GeoPoint userLocation,
    double radiusInKm = 50,
  }) async {
    try {
      final lat = userLocation.latitude;
      final lng = userLocation.longitude;

      // Get geohash prefixes that cover the search radius
      final queryPrefixes = Geohash.getQueryBounds(lat, lng, radiusInKm);

      // Deduplicate prefixes
      final uniquePrefixes = queryPrefixes.toSet().toList();

      // Query Firestore for each geohash prefix in parallel
      final futures = <Future<QuerySnapshot>>[];
      for (final prefix in uniquePrefixes) {
        final range = Geohash.getQueryRange(prefix);
        futures.add(
          _firestore
              .collection('users')
              .where('geohash', isGreaterThanOrEqualTo: range[0])
              .where('geohash', isLessThan: range[1])
              .limit(_discoveryLimit)
              .get(),
        );
      }

      final snapshots = await Future.wait(futures);

      // Merge and deduplicate results
      final seenUids = <String>{};
      final nearbyUsers = <UserModel>[];

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final uid = doc.id;

          // Skip current user and duplicates
          if (uid == currentUserId || seenUids.contains(uid)) continue;
          seenUids.add(uid);

          final user = UserModel.fromMap(data, uid);

          // Exact distance post-filter using Haversine
          if (user.location != null) {
            final distance = Geohash.distanceKm(
              lat, lng,
              user.location!.latitude, user.location!.longitude,
            );
            if (distance <= radiusInKm) {
              nearbyUsers.add(user);
            }
          }
        }
      }

      if (kDebugMode) {
        AppLogger.info('UserService: Found ${nearbyUsers.length} nearby users within ${radiusInKm}km');
      }

      return nearbyUsers;
    } catch (e) {
      AppLogger.error('UserService: Error getting nearby users: $e');
      // Fallback to legacy query if geohash fields don't exist yet
      return _getNearbyUsersLegacy(
        currentUserId: currentUserId,
        userLocation: userLocation,
        radiusInKm: radiusInKm,
      );
    }
  }

  /// Legacy fallback for users without geohash fields.
  /// Will be removed once all users have geohash data.
  Future<List<UserModel>> _getNearbyUsersLegacy({
    required String currentUserId,
    required GeoPoint userLocation,
    double radiusInKm = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUserId)
          .limit(200)
          .get();

      final nearbyUsers = <UserModel>[];
      for (final doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data(), doc.id);
        if (user.location != null) {
          final distance = Geohash.distanceKm(
            userLocation.latitude, userLocation.longitude,
            user.location!.latitude, user.location!.longitude,
          );
          if (distance <= radiusInKm) {
            nearbyUsers.add(user);
          }
        }
      }
      return nearbyUsers;
    } catch (e) {
      AppLogger.error('UserService: Legacy nearby query failed: $e');
      return [];
    }
  }

  /// Calculate similarity score based on interests (Jaccard similarity).
  double calculateSimilarity(List<String> interests1, List<String> interests2) {
    if (interests1.isEmpty || interests2.isEmpty) return 0.0;

    Set<String> set1 = interests1.map((e) => e.toLowerCase()).toSet();
    Set<String> set2 = interests2.map((e) => e.toLowerCase()).toSet();

    int commonInterests = set1.intersection(set2).length;
    int totalInterests = set1.union(set2).length;

    return totalInterests > 0 ? (commonInterests / totalInterests) * 100 : 0.0;
  }

  /// Get users sorted by similarity, querying only users who share at least
  /// one interest with the current user (instead of fetching ALL users).
  Future<List<Map<String, dynamic>>> getUsersBySimilarity({
    required String currentUserId,
    required List<String> currentUserInterests,
  }) async {
    try {
      if (currentUserInterests.isEmpty) return [];

      // Firestore arrayContainsAny supports up to 30 values.
      // Take the first 10 interests to query users who share at least one.
      final queryInterests = currentUserInterests
          .map((e) => e.toLowerCase())
          .take(10)
          .toList();

      final snapshot = await _firestore
          .collection('users')
          .where('interests', arrayContainsAny: queryInterests)
          .limit(_discoveryLimit)
          .get();

      final usersWithSimilarity = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        final user = UserModel.fromMap(doc.data(), doc.id);
        final similarity = calculateSimilarity(currentUserInterests, user.interests);

        if (similarity > 0) {
          usersWithSimilarity.add({
            'user': user,
            'similarity': similarity,
          });
        }
      }

      usersWithSimilarity.sort((a, b) =>
          (b['similarity'] as double).compareTo(a['similarity'] as double));

      return usersWithSimilarity;
    } catch (e) {
      AppLogger.error('UserService: Error getting users by similarity: $e');
      return [];
    }
  }

  /// Update user location with geohash for efficient discovery queries.
  Future<void> updateUserLocation(String uid, Position position, {String? city, String? country}) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          AppLogger.info('UserService: User document not found for uid: $uid');
        }
        return;
      }

      // Encode location to geohash for range queries
      final geohash = Geohash.encode(
        position.latitude,
        position.longitude,
        precision: 7,
      );

      await _firestore.collection('users').doc(uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'geohash': geohash,
        'city': city,
        'country': country,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('UserService: Error updating location: $e');
    }
  }
}
