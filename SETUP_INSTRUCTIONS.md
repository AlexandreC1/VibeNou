# VibeNou Setup Instructions

Complete guide to set up and run the VibeNou Flutter social networking app with Supabase backend.

## Prerequisites

- Flutter SDK 3.0+ installed ([Get Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio / Xcode for platform development
- Supabase account ([Sign up](https://supabase.com))
- Git

## Step 1: Clone and Setup Project

```bash
# Navigate to the project directory
cd VibeNou

# Install dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

## Step 2: Create Supabase Project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Choose your organization (or create one)
4. Fill in project details:
   - **Name**: VibeNou (or any name you prefer)
   - **Database Password**: Choose a strong password (save it securely)
   - **Region**: Choose closest to your users
5. Click "Create new project" (takes ~2 minutes)

## Step 3: Setup Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy the entire contents of `supabase_schema.sql` from the project
4. Paste it into the SQL editor
5. Click "Run" to execute the schema
6. Wait for success message
7. Verify tables were created:
   - Go to **Database** > **Tables**
   - You should see: `users`, `chat_rooms`, `messages`

## Step 4: Create Storage Bucket for Profile Photos

1. In Supabase dashboard, go to **Storage**
2. Click "Create a new bucket"
3. Name it: `profile-photos`
4. Make it **Public** (check the public checkbox)
5. Click "Create bucket"

### Configure Storage Policies

In the SQL Editor, run these commands to set up storage policies:

```sql
-- Allow users to upload their own profile photos
CREATE POLICY "Users can upload their own profile photo"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public access to profile photos
CREATE POLICY "Profile photos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-photos');

-- Allow users to update their own profile photos
CREATE POLICY "Users can update their own profile photo"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own profile photos
CREATE POLICY "Users can delete their own profile photo"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

## Step 5: Enable Realtime for Messages

1. Go to **Database** > **Replication**
2. Find the `messages` table
3. Toggle it ON to enable realtime updates
4. This allows real-time chat functionality

## Step 6: Get Supabase Credentials

1. In Supabase dashboard, go to **Settings** > **API**
2. Find and copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

⚠️ **NEVER use the `service_role` key in client-side code!**

## Step 7: Configure Flutter App

1. Open `lib/utils/supabase_config.dart`
2. Replace the placeholder values:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

## Step 8: Configure Google Sign-In (Optional)

### For Supabase:

1. In Supabase dashboard, go to **Authentication** > **Providers**
2. Enable **Google** provider
3. Add authorized redirect URLs:
   - For development: `http://localhost:3000/**`
   - For production: `your-app-url/**`

### For Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable **Google+ API**
4. Create OAuth 2.0 credentials:
   - **Android**: Add SHA-1 fingerprint
   - **iOS**: Add iOS bundle ID
5. Copy Client ID and Client Secret
6. Add them to Supabase Google provider settings

## Step 9: Configure Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)

Already configured, but verify these permissions exist:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS (`ios/Runner/Info.plist`)

Add these keys:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>VibeNou needs your location to find nearby users</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>VibeNou needs your location to find nearby users</string>
<key>NSCameraUsageDescription</key>
<string>VibeNou needs camera access to take profile photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>VibeNou needs photo library access to select profile photos</string>
```

## Step 10: Run the App

```bash
# Check for any issues
flutter doctor

# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Or run in debug mode
flutter run --debug

# Or build release version
flutter build apk  # For Android
flutter build ios  # For iOS
```

## Testing the App

### 1. Create Test Users

- Sign up with different email addresses
- Complete profile setup with name, age, bio, and interests
- Upload profile photos
- Allow location access

### 2. Test Location Features

- Ensure location permissions are granted
- Check that your location is saved in Supabase (Database > users table)
- Try discovering nearby users (you'll need multiple users with locations)

### 3. Test Chat

- Create a chat with another user
- Send messages
- Verify real-time updates (open chat on two devices)
- Test message read receipts

### 4. Test User Discovery

- Use the Discover tab to find users
- Test "Nearby" filter (requires location)
- Test "Similar Interests" filter
- Try tapping on user cards to view profiles

## Common Issues & Solutions

### Issue: "Supabase Not Configured" error

**Solution**: Update `lib/utils/supabase_config.dart` with your actual Supabase credentials

### Issue: Location not working

**Solution**:
- Check that location permissions are granted in device settings
- For iOS simulator: Features > Location > Custom Location
- For Android emulator: Extended controls (…) > Location

### Issue: Realtime chat not working

**Solution**:
- Verify that Realtime is enabled for `messages` table in Supabase
- Check Supabase logs for any errors
- Ensure RLS policies are correctly configured

### Issue: Profile photo upload fails

**Solution**:
- Verify `profile-photos` bucket exists and is public
- Check storage policies are correctly configured
- Ensure image file size is < 5MB

### Issue: Database query fails

**Solution**:
- Check Row Level Security (RLS) policies
- Verify user is authenticated
- Check Supabase logs for detailed errors

## Database Functions

The app uses these PostgreSQL functions (already created by schema):

- `get_nearby_users(lat, lng, radius_km)` - Find users within radius
- `get_users_by_interests(interests)` - Find users with similar interests
- `get_unread_count(room_id)` - Get unread message count
- `mark_messages_as_read(room_id)` - Mark all messages as read
- `get_or_create_chat_room(other_user_id)` - Get or create chat room

## Development Tips

1. **Enable Debug Mode**: Set `kDebugMode = true` to see detailed logs
2. **Use Hot Reload**: Press `r` in terminal or use IDE hot reload
3. **Check Logs**: Monitor console for Supabase operation logs
4. **Test on Real Device**: Location features work better on physical devices
5. **Use Supabase Dashboard**: Monitor database, auth, and storage in real-time

## Production Deployment

### Before deploying:

1. **Update Supabase Config**: Use environment variables instead of hardcoded keys
2. **Configure OAuth**: Add production redirect URLs
3. **Update App Icons**: Replace default Flutter launcher icon
4. **Configure Deep Links**: For password reset and OAuth callbacks
5. **Test Thoroughly**: All features on both iOS and Android
6. **Enable Analytics**: Track user behavior and crashes
7. **Set up CI/CD**: Automate builds and deployments

### Security Checklist:

- ✅ RLS policies enabled on all tables
- ✅ Using `anon` key (not `service_role`)
- ✅ Storage policies configured correctly
- ✅ OAuth credentials secured
- ✅ Input validation on client and database
- ✅ Rate limiting configured in Supabase
- ✅ HTTPS only in production

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [PostGIS Documentation](https://postgis.net/docs/)
- [Flutter Location Plugin](https://pub.dev/packages/geolocator)

## Support

For issues or questions:
1. Check this guide first
2. Review Supabase logs
3. Check Flutter console output
4. Search existing issues on GitHub
5. Create a new issue with detailed description

## License

See LICENSE file for details.
