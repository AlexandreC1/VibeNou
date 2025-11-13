import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service for managing Supabase client instance
/// Provides centralized access to Supabase authentication, database, storage, and realtime features
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  // Private constructor
  SupabaseService._();

  /// Get singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase with URL and anon key
  /// Call this once in main.dart before runApp()
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
          persistSession: true,
        ),
      );

      _client = Supabase.instance.client;

      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
        print('URL: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Supabase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Get Supabase client instance
  /// Throws an error if Supabase is not initialized
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase client not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Quick access to auth
  GoTrueClient get auth => client.auth;

  /// Quick access to database
  PostgrestClient get database => client.from('');

  /// Quick access to storage
  SupabaseStorageClient get storage => client.storage;

  /// Quick access to realtime
  RealtimeClient get realtime => client.realtime;

  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.id;

  /// Get current user email
  String? get currentUserEmail => auth.currentUser?.email;

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Get current session
  Session? get currentSession => auth.currentSession;

  /// Sign out and clear session
  Future<void> signOut() async {
    try {
      await auth.signOut();
      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out failed: $e');
      }
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  /// Dispose resources (call when app is terminated)
  void dispose() {
    // Clean up any subscriptions or resources if needed
    if (kDebugMode) {
      print('🧹 SupabaseService disposed');
    }
  }
}

/// Convenience getter for Supabase client
/// Usage: supabase.from('users').select()
final supabase = SupabaseService.instance.client;

/// Convenience getter for auth client
/// Usage: supabaseAuth.signIn(...)
final supabaseAuth = SupabaseService.instance.auth;
