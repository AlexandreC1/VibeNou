# VibeNou Firebase Setup Progress

Track your Firebase backend setup progress with this checklist.

## ✅ Completed Steps

- [ ] **Step 1:** Created Firebase project at https://console.firebase.google.com/
  - Project name: `____________________`
  - Project ID: `____________________`

- [ ] **Step 2:** Added Android app to Firebase project
  - Package name: `com.vibenou.vibenou`
  - Downloaded `google-services.json`
  - Placed in: `/home/user/VibeNou/android/app/google-services.json`

- [ ] **Step 3:** Enabled Authentication
  - Go to: Authentication → Sign-in method
  - Enabled "Email/Password" provider

- [ ] **Step 4:** Created Firestore Database
  - Go to: Firestore Database → Create Database
  - Started in: Production mode
  - Region: `____________________`

- [ ] **Step 5:** Configured Firestore Security Rules
  - Pasted clean rules from `firestore.rules` file
  - Clicked "Publish"
  - ✅ Rules saved without errors

- [ ] **Step 6:** Updated `lib/utils/firebase_options.dart`
  - Replaced `YOUR_ANDROID_API_KEY` with actual value
  - Replaced `YOUR_ANDROID_APP_ID` with actual value
  - Replaced `YOUR_MESSAGING_SENDER_ID` with actual value
  - Replaced `YOUR_PROJECT_ID` with actual value
  - Updated `storageBucket` with project ID

- [ ] **Step 7:** Enabled Firebase in app code
  - Uncommented Firebase imports in `lib/main.dart`
  - Uncommented Firebase initialization in `lib/main.dart`
  - Set `firebaseConfigured = true`

- [ ] **Step 8:** Tested the app
  - Ran `flutter pub get`
  - Ran `flutter run`
  - App shows Splash → Login screen (not Setup screen)
  - Created first test account successfully

---

## 📋 Configuration Values Needed

Get these from: Firebase Console → Project Settings → Your Android app

```
Android API Key: _________________________________
Android App ID: _________________________________
Messaging Sender ID: _________________________________
Project ID: _________________________________
Storage Bucket: _________________________________
```

### Where to Find Each Value:

**In Firebase Console:**
1. Click gear icon (⚙️) → Project Settings
2. Scroll to "Your apps" section
3. Click on your Android app
4. Click "Config" or view the JSON

**Or in `google-services.json` file:**
```json
{
  "project_info": {
    "project_number": "123456789",  ← This is messagingSenderId
    "project_id": "vibenou-xxxxx",  ← This is projectId
    "storage_bucket": "vibenou-xxxxx.appspot.com"  ← This is storageBucket
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc",  ← This is appId
        "android_client_info": {
          "package_name": "com.vibenou.vibenou"
        }
      },
      "api_key": [
        {
          "current_key": "AIzaSy..."  ← This is apiKey
        }
      ]
    }
  ]
}
```

---

## 🚀 Ready to Enable Firebase in App

Once you've completed steps 1-6 above, follow these instructions:

### 1. Open `lib/main.dart`

Find these lines (around line 6-8):
```dart
// Uncomment when Firebase is configured
// import 'package:firebase_core/firebase_core.dart';
// import 'utils/firebase_options.dart';
```

Change to:
```dart
// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_options.dart';
```

### 2. Find Firebase Initialization (around line 26-30):

Change FROM:
```dart
// Uncomment these lines when Firebase is configured:
// await Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// );
// firebaseConfigured = true;

// For now, Firebase is not configured
firebaseConfigured = false;
errorMessage = 'Firebase not configured. Please follow the setup guide.';
```

Change TO:
```dart
// Initialize Firebase
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
firebaseConfigured = true;
```

### 3. Run the App

```bash
flutter pub get
flutter clean
flutter run
```

---

## 🧪 Testing Your Setup

After enabling Firebase, test these features:

### Test 1: Authentication
- [ ] App shows Splash screen → Login screen (not Setup screen)
- [ ] Click "Sign Up"
- [ ] Complete all signup steps
- [ ] Grant location permission when prompted
- [ ] Account created successfully

### Test 2: Profile
- [ ] Go to Profile tab
- [ ] See your name, age, bio, interests
- [ ] See location (city/country)
- [ ] No "Please log in" error message

### Test 3: Nearby Users
- [ ] Create a second test account (use different email)
- [ ] Log into first account
- [ ] Go to Discover tab → Nearby Users
- [ ] See the second account listed
- [ ] Distance shows "0.0 km away" (same location)

### Test 4: Profile Visitors
- [ ] Log into Account 1
- [ ] Go to Discover tab
- [ ] Tap on Account 2's card to view profile
- [ ] Log out, log into Account 2
- [ ] Go to Profile tab
- [ ] See eye icon with "1" badge
- [ ] Click eye icon to see Account 1 visited your profile

### Test 5: Chat
- [ ] While logged in as Account 2
- [ ] Go to Discover tab
- [ ] Tap Account 1's profile
- [ ] Tap "Send Message"
- [ ] Send a test message
- [ ] Log into Account 1
- [ ] Go to Chat tab
- [ ] See message from Account 2

---

## ⚠️ Common Issues

### Issue: "Firebase not initialized" error
**Solution:** Make sure you uncommented the Firebase imports AND initialization in `lib/main.dart`

### Issue: "Permission denied" in Firestore
**Solution:** Verify security rules were published in Firebase Console → Firestore → Rules

### Issue: App still shows Setup Screen
**Solution:** Make sure `firebaseConfigured = true;` is set in main.dart (not commented out)

### Issue: "google-services.json not found"
**Solution:**
1. Check file exists at: `/home/user/VibeNou/android/app/google-services.json`
2. Make sure it's not in a subdirectory
3. Restart Android Studio/VS Code
4. Run `flutter clean` then `flutter run`

---

## 📞 Need Help?

If you encounter errors:

1. **Check Firebase Console:**
   - Is Authentication enabled?
   - Is Firestore database created?
   - Are security rules published?

2. **Check your code:**
   - Are Firebase imports uncommented?
   - Is Firebase.initializeApp() uncommented?
   - Did you replace ALL placeholder values in firebase_options.dart?

3. **Check logs:**
   ```bash
   flutter run --verbose
   ```
   Look for error messages mentioning Firebase, authentication, or Firestore.

4. **Reference documentation:**
   - FIREBASE_SETUP.md - Full setup guide
   - TROUBLESHOOTING.md - Common errors and fixes
   - BUG_FIXES.md - Recent bug fixes

---

## ✨ You're Almost There!

Current status: Firebase backend setup in progress

**Next immediate steps:**
1. ✅ Copy clean rules from `firestore.rules` and publish in Firebase Console
2. Update `lib/utils/firebase_options.dart` with your actual config values
3. Uncomment Firebase initialization in `lib/main.dart`
4. Run `flutter run` and test!
