import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// User service for managing user profiles and discovery features
/// Handles user CRUD operations, nearby user queries, and interest-based matching
class UserService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Get user profile by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Get multiple user profiles by IDs
  Future<List<UserModel>> getUserProfiles(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final response = await _supabase
          .from('users')
          .select()
          .inFilter('id', userIds);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user profiles: $e');
      }
      return [];
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    String? bio,
    List<String>? interests,
    String? photoUrl,
    String? city,
    String? country,
    String? preferredLanguage,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 Updating user profile: $userId');
      }

      final Map<String, dynamic> updates = {
        'last_active': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (age != null) updates['age'] = age;
      if (bio != null) updates['bio'] = bio;
      if (interests != null) updates['interests'] = interests;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (city != null) updates['city'] = city;
      if (country != null) updates['country'] = country;
      if (preferredLanguage != null) {
        updates['preferred_language'] = preferredLanguage;
      }

      await _supabase.from('users').update(updates).eq('id', userId);

      if (kDebugMode) {
        print('✅ User profile updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      rethrow;
    }
  }

  /// Update user location using PostGIS POINT format
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    String? city,
    String? country,
  }) async {
    try {
      if (kDebugMode) {
        print('📍 Updating user location: $userId');
      }

      // Use PostGIS POINT format: POINT(longitude latitude)
      // Note: PostGIS uses (lon, lat) order, not (lat, lon)
      final Map<String, dynamic> updates = {
        'location': 'POINT($longitude $latitude)',
        'last_active': DateTime.now().toIso8601String(),
      };

      if (city != null) updates['city'] = city;
      if (country != null) updates['country'] = country;

      await _supabase.from('users').update(updates).eq('id', userId);

      if (kDebugMode) {
        print('✅ User location updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user location: $e');
      }
      rethrow;
    }
  }

  /// Get nearby users using PostGIS distance queries
  /// Uses the get_nearby_users database function
  Future<List<NearbyUser>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int maxResults = 50,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Searching for nearby users within ${radiusKm}km');
      }

      final response = await _supabase.rpc(
        'get_nearby_users',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_km': radiusKm,
          'max_results': maxResults,
        },
      );

      if (response == null) return [];

      final users = (response as List)
          .map((json) => NearbyUser.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Found ${users.length} nearby users');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching nearby users: $e');
      }
      return [];
    }
  }

  /// Get users with similar interests
  /// Uses the get_users_by_interests database function
  Future<List<SimilarInterestUser>> getUsersBySimilarInterests({
    required List<String> interests,
    int maxResults = 50,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 Searching for users with similar interests');
      }

      if (interests.isEmpty) {
        if (kDebugMode) {
          print('⚠️  No interests provided, returning empty list');
        }
        return [];
      }

      final response = await _supabase.rpc(
        'get_users_by_interests',
        params: {
          'user_interests': interests,
          'max_results': maxResults,
        },
      );

      if (response == null) return [];

      final users = (response as List)
          .map((json) => SimilarInterestUser.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Found ${users.length} users with similar interests');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching users by interests: $e');
      }
      return [];
    }
  }

  /// Upload profile photo to Supabase Storage
  /// Returns the public URL of the uploaded photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Uploading profile photo for user: $userId');
      }

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/profile.$fileExt';

      // Upload to Supabase Storage
      await _supabase.storage.from('profile-photos').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true, // Overwrite if exists
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('profile-photos')
          .getPublicUrl(fileName);

      if (kDebugMode) {
        print('✅ Profile photo uploaded successfully');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading profile photo: $e');
      }
      return null;
    }
  }

  /// Delete profile photo from Supabase Storage
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      if (kDebugMode) {
        print('🗑️  Deleting profile photo for user: $userId');
      }

      // List all files in user's folder
      final files = await _supabase.storage
          .from('profile-photos')
          .list(path: userId);

      // Delete all files
      final filePaths = files.map((file) => '$userId/${file.name}').toList();
      if (filePaths.isNotEmpty) {
        await _supabase.storage.from('profile-photos').remove(filePaths);
      }

      if (kDebugMode) {
        print('✅ Profile photo deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting profile photo: $e');
      }
      rethrow;
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      await _supabase.from('users').update({
        'last_active': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating last active: $e');
      }
      // Don't rethrow as this is a non-critical operation
    }
  }

  /// Delete user profile and all associated data
  Future<void> deleteUserProfile(String userId) async {
    try {
      if (kDebugMode) {
        print('🗑️  Deleting user profile: $userId');
      }

      // Delete profile photo first
      try {
        await deleteProfilePhoto(userId);
      } catch (e) {
        // Continue even if photo deletion fails
        if (kDebugMode) {
          print('⚠️  Failed to delete profile photo: $e');
        }
      }

      // Delete user record (cascade will delete related data)
      await _supabase.from('users').delete().eq('id', userId);

      if (kDebugMode) {
        print('✅ User profile deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting user profile: $e');
      }
      rethrow;
    }
  }

  /// Search users by name
  Future<List<UserModel>> searchUsersByName(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      if (kDebugMode) {
        print('🔍 Searching users by name: $query');
      }

      final response = await _supabase
          .from('users')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      final users = (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Found ${users.length} users matching "$query"');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching users: $e');
      }
      return [];
    }
  }

  /// Get all users (paginated)
  Future<List<UserModel>> getAllUsers({
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('users')
          .select()
          .order('last_active', ascending: false)
          .range(from, to);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching all users: $e');
      }
      return [];
    }
  }
}
