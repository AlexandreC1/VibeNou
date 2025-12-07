import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (for discovery)
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get nearby users based on location
  Future<List<UserModel>> getNearbyUsers({
    required String currentUserId,
    required GeoPoint userLocation,
    double radiusInKm = 50,
  }) async {
    try {
      print('DEBUG UserService: Querying users (excluding $currentUserId)');
      print('DEBUG UserService: User location: ${userLocation.latitude}, ${userLocation.longitude}');
      print('DEBUG UserService: Search radius: ${radiusInKm}km');

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUserId)
          .get();

      print('DEBUG UserService: Found ${snapshot.docs.length} total users in database');

      List<UserModel> allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by distance
      List<UserModel> nearbyUsers = [];
      int usersWithoutLocation = 0;

      for (var user in allUsers) {
        if (user.location != null) {
          double distance = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            user.location!.latitude,
            user.location!.longitude,
          );
          print('DEBUG UserService: User ${user.name} is ${distance.toStringAsFixed(2)}km away');
          if (distance <= radiusInKm) {
            nearbyUsers.add(user);
            print('DEBUG UserService: -> Added ${user.name} to nearby users');
          }
        } else {
          usersWithoutLocation++;
        }
      }

      print('DEBUG UserService: $usersWithoutLocation users without location data');
      print('DEBUG UserService: Returning ${nearbyUsers.length} nearby users');

      return nearbyUsers;
    } catch (e) {
      print('ERROR UserService: Error getting nearby users: $e');
      return [];
    }
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Calculate similarity score based on interests
  double calculateSimilarity(List<String> interests1, List<String> interests2) {
    if (interests1.isEmpty || interests2.isEmpty) return 0.0;

    Set<String> set1 = interests1.map((e) => e.toLowerCase()).toSet();
    Set<String> set2 = interests2.map((e) => e.toLowerCase()).toSet();

    int commonInterests = set1.intersection(set2).length;
    int totalInterests = set1.union(set2).length;

    return totalInterests > 0 ? (commonInterests / totalInterests) * 100 : 0.0;
  }

  // Get users sorted by similarity
  Future<List<Map<String, dynamic>>> getUsersBySimilarity({
    required String currentUserId,
    required List<String> currentUserInterests,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUserId)
          .get();

      List<Map<String, dynamic>> usersWithSimilarity = [];

      for (var doc in snapshot.docs) {
        UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        double similarity = calculateSimilarity(currentUserInterests, user.interests);

        usersWithSimilarity.add({
          'user': user,
          'similarity': similarity,
        });
      }

      // Sort by similarity score
      usersWithSimilarity.sort((a, b) =>
          (b['similarity'] as double).compareTo(a['similarity'] as double));

      return usersWithSimilarity;
    } catch (e) {
      print('Error getting users by similarity: $e');
      return [];
    }
  }

  // Update user location
  Future<void> updateUserLocation(String uid, Position position, {String? city, String? country}) async {
    try {
      // Check if user document exists first
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (!docSnapshot.exists) {
        print('User document not found for uid: $uid. Skipping location update.');
        return;
      }

      await _firestore.collection('users').doc(uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'city': city,
        'country': country,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating location: $e');
      // Don't rethrow - just log the error
    }
  }
}
