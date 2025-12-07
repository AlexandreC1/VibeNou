# Supabase Setup Guide for VibeNou

Since you're using Firebase's free tier (Spark plan) which doesn't include Cloud Storage, we're using Supabase for image storage instead.

## Why Supabase?

- **Free Tier**: 1GB storage (perfect for profile pictures)
- **Fast CDN**: Automatic image optimization and CDN delivery
- **Easy to use**: Simple API similar to Firebase
- **No credit card required**: Get started completely free

## Setup Steps

### 1. Create a Supabase Account

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up with GitHub, Google, or email

### 2. Create a New Project

1. Click "New Project"
2. Give it a name (e.g., "vibenou")
3. Set a strong database password (save this!)
4. Choose a region close to your users
5. Click "Create new project"
6. Wait 1-2 minutes for setup to complete

### 3. Create a Storage Bucket

1. In your Supabase project dashboard, go to **Storage** (left sidebar)
2. Click "Create a new bucket"
3. Name it: `vibenou-profiles`
4. Make it **Public** (toggle the "Public bucket" option ON)
5. Click "Create bucket"

### 4. Configure Bucket Policies

1. Click on your `vibenou-profiles` bucket
2. Go to "Policies" tab
3. Click "New Policy"
4. Select "For full customization, create a policy from scratch"
5. Add this policy for uploads:

```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'vibenou-profiles');
```

6. Add this policy for public access:

```sql
CREATE POLICY "Allow public downloads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'vibenou-profiles');
```

### 5. Get Your Supabase Credentials

1. Go to **Project Settings** (⚙️ icon in left sidebar)
2. Click **API** tab
3. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (the long string under "Project API keys")

### 6. Configure Your Flutter App

1. Open `lib/utils/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  static const String profileBucket = 'vibenou-profiles';
}
```

### 7. Initialize Supabase in Your App

Open `lib/main.dart` and add Supabase initialization:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase for image storage
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}
```

### 8. Install Dependencies

Run this command in your terminal:

```bash
cd VibeNou
flutter pub get
```

## Testing

1. Run your app
2. Go to profile screen
3. Tap "Edit Profile"
4. Tap on the camera icon to upload a picture
5. Select an image from gallery or take a photo
6. The image will be uploaded to Supabase!

You can verify uploads in Supabase Dashboard:
- Go to **Storage** > **vibenou-profiles**
- You should see files named `profile_[userId].jpg`

## Storage Limits

Supabase Free Tier:
- **1 GB storage** (plenty for profile pictures)
- **50 MB max file size**
- **Unlimited bandwidth** for downloads

To optimize storage:
- Profile pictures are automatically compressed to 1024x1024 pixels
- Images are saved as JPEG with 85% quality
- Each user can only have 1 profile picture (upsert: true overwrites old ones)

## Troubleshooting

### "Storage bucket not found"
- Make sure you created the bucket named exactly `vibenou-profiles`
- Check that it's set to **Public**

### "Permission denied"
- Verify your storage policies are set correctly
- Make sure the bucket is public

### "Invalid API key"
- Double-check your `supabaseUrl` and `supabaseAnonKey` in `supabase_config.dart`
- Make sure there are no extra spaces or quotes

### Images not loading
- Check that the bucket is set to **Public**
- Verify the URL in your database matches the Supabase storage URL

## Cost Comparison

| Service | Free Tier | Cost Beyond Free |
|---------|-----------|------------------|
| Firebase Storage | ❌ Not available on Spark plan | Starts at $25/month |
| Supabase Storage | ✅ 1GB free forever | $0.021/GB/month |

For a small to medium app, Supabase's free tier should be more than enough!

## Need Help?

- [Supabase Documentation](https://supabase.com/docs/guides/storage)
- [Supabase Discord Community](https://discord.supabase.com)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

---

**Note**: You're still using Firebase for authentication and Firestore for the database. Only image storage has been moved to Supabase!
