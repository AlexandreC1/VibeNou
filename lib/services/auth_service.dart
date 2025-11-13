import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// Authentication service for managing user sign up, sign in, and OAuth
/// Handles all authentication-related operations using Supabase Auth
class AuthService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Get current user email
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  /// Creates a new user in Supabase Auth and user profile in the database
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    String? bio,
    List<String> interests = const [],
    String preferredLanguage = 'en',
  }) async {
    try {
      if (kDebugMode) {
        print('📝 Signing up user: $email');
      }

      // Validate age requirement
      if (age < 13) {
        throw Exception('You must be at least 13 years old to sign up');
      }

      // Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }

      final user = authResponse.user!;

      if (kDebugMode) {
        print('✅ Auth user created: ${user.id}');
      }

      // Create user profile in database
      final userModel = UserModel(
        id: user.id,
        email: email,
        name: name,
        age: age,
        bio: bio,
        interests: interests,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        preferredLanguage: preferredLanguage,
      );

      // Insert user profile into users table
      await _supabase.from('users').insert({
        'id': user.id,
        'email': email,
        'name': name,
        'age': age,
        'bio': bio,
        'interests': interests,
        'preferred_language': preferredLanguage,
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ User profile created in database');
      }

      return userModel;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Auth error during sign up: ${e.message}');
      }
      throw Exception(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during sign up: $e');
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 Signing in user: $email');
      }

      // Sign in with Supabase Auth
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in');
      }

      final user = authResponse.user!;

      if (kDebugMode) {
        print('✅ User signed in: ${user.id}');
      }

      // Update last active timestamp
      await _supabase.from('users').update({
        'last_active': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Fetch user profile from database
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Auth error during sign in: ${e.message}');
      }
      throw Exception(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during sign in: $e');
      }
      rethrow;
    }
  }

  /// Sign in with Google OAuth
  Future<UserModel> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('🔐 Signing in with Google');
      }

      // Sign in with Google OAuth
      final authResponse = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.vibenou://login-callback',
      );

      if (!authResponse) {
        throw Exception('Google sign in was cancelled');
      }

      // Wait for auth state change
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Failed to get user after Google sign in');
      }

      if (kDebugMode) {
        print('✅ Google sign in successful: ${user.id}');
      }

      // Check if user profile exists
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser != null) {
        // Update last active
        await _supabase.from('users').update({
          'last_active': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        return UserModel.fromJson(existingUser);
      }

      // Create new user profile for Google sign in
      final userModel = UserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['full_name'] ?? 'User',
        age: 18, // Default age, user should update later
        bio: null,
        interests: [],
        photoUrl: user.userMetadata?['avatar_url'],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'name': userModel.name,
        'age': userModel.age,
        'photo_url': userModel.photoUrl,
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('✅ Google user profile created');
      }

      return userModel;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Auth error during Google sign in: ${e.message}');
      }
      throw Exception(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during Google sign in: $e');
      }
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('📧 Sending password reset email to: $email');
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? null
            : 'io.supabase.vibenou://reset-password-callback',
      );

      if (kDebugMode) {
        print('✅ Password reset email sent');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Error sending password reset email: ${e.message}');
      }
      throw Exception(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during password reset: $e');
      }
      rethrow;
    }
  }

  /// Update password for authenticated user
  Future<void> updatePassword(String newPassword) async {
    try {
      if (kDebugMode) {
        print('🔐 Updating password');
      }

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (kDebugMode) {
        print('✅ Password updated successfully');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Error updating password: ${e.message}');
      }
      throw Exception(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during password update: $e');
      }
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('👋 Signing out user');
      }

      // Update last active before signing out
      if (currentUserId != null) {
        await _supabase.from('users').update({
          'last_active': DateTime.now().toIso8601String(),
        }).eq('id', currentUserId!);
      }

      await _supabase.auth.signOut();

      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Error during sign out: ${e.message}');
      }
      throw Exception(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during sign out: $e');
      }
      rethrow;
    }
  }

  /// Get current user's profile from database
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUserId!)
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

  /// Refresh current session
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
      if (kDebugMode) {
        print('✅ Session refreshed');
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing session: ${e.message}');
      }
      throw Exception(e.message);
    }
  }
}
