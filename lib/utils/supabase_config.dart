/// Supabase Configuration
///
/// IMPORTANT: These values need to be replaced with your actual Supabase project credentials
///
/// To get these values:
/// 1. Go to https://supabase.com/dashboard
/// 2. Select your project (or create a new one)
/// 3. Go to Settings > API
/// 4. Copy the Project URL and anon/public key
///
/// ⚠️  SECURITY WARNING:
/// - Never commit real credentials to version control
/// - Use environment variables or secure storage for production
/// - The anon key is safe to use in client-side code (it's public)
/// - Never use the service_role key in client-side code

class SupabaseConfig {
  // Replace with your Supabase project URL
  // Format: https://your-project-id.supabase.co
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';

  // Replace with your Supabase anon/public key
  // This key is safe to use in client-side code
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
        supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }

  // Get configuration error message
  static String get configErrorMessage {
    if (!isConfigured) {
      return '''

⚠️  SUPABASE NOT CONFIGURED ⚠️

Please update lib/utils/supabase_config.dart with your Supabase credentials:

1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Settings > API
4. Copy Project URL and anon key
5. Update the values in supabase_config.dart

For detailed setup instructions, see SETUP_GUIDE.md
      ''';
    }
    return '';
  }
}
