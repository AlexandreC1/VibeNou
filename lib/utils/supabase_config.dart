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
  static const String supabaseUrl = 'https://iuqemwkjphidljtzbfoc.supabase.co';

  // Replace with your Supabase anon/public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1cWVtd2tqcGhpZGxqdHpiZm9jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMTYwOTMsImV4cCI6MjA4MDc5MjA5M30.wKFnW0xbmFCi4_-D1179yce3apPy_fM-ywGimVYHjDg';

  // Storage bucket name for profile pictures
  static const String profileBucket = 'vibenou-profiles';
}
