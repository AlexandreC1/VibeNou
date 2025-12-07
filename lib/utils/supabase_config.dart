// Supabase Configuration
//
// To use Supabase for image storage:
// 1. Create a Supabase project at https://supabase.com
// 2. Go to Storage section and create a new bucket called 'vibenou-profiles'
// 3. Make the bucket public by going to Storage Settings
// 4. Replace the values below with your Supabase project credentials
//
// Find your credentials at: Project Settings > API

class SupabaseConfig {
  // Replace with your Supabase project URL
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';

  // Replace with your Supabase anon/public key
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Storage bucket name for profile pictures
  static const String profileBucket = 'vibenou-profiles';
}
