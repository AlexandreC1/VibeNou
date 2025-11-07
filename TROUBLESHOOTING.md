# VibeNou Troubleshooting Guide

## Common Issues and Solutions

### Issue 1: "Please log in to view your profile" Message on Launch

**Symptoms:**
- App opens but shows "Please log in to view your profile" instead of login screen
- Unable to access any features

**Cause:**
Firebase is not configured/initialized, causing authentication services to fail silently.

**Solution:**
1. The app now shows a **Setup Screen** when Firebase is not configured
2. Follow the setup instructions on the screen
3. Complete Firebase configuration (see SETUP_GUIDE.md)
4. Uncomment Firebase initialization in `lib/main.dart`

---

### Issue 2: Chat Feature Errors

**Symptoms:**
- Errors when trying to open chat
- Chat screen crashes or doesn't load

**Cause:**
Without Firebase Firestore initialized, the chat service cannot connect to the database.

**Solution:**
1. Set up Firebase (see SETUP_GUIDE.md)
2. Enable Firestore Database in Firebase Console
3. Configure Firestore security rules
4. Restart the app after Firebase is configured

---

### Issue 3: Dependency Version Conflict (intl package)

**Symptoms:**
```
Because vibenou depends on flutter_localizations from sdk which depends on intl 0.20.2, intl 0.20.2 is required.
```

**Solution:**
✅ **FIXED** - Updated `pubspec.yaml` to use `intl: any`

Run:
```bash
flutter pub get
```

---

### Issue 4: Location Services Not Working

**Symptoms:**
- Cannot find nearby users
- Location permission denied

**Solution:**
1. Grant location permissions in device settings
2. Enable location services on your device
3. For Android: Check AndroidManifest.xml has location permissions
4. For iOS: Check Info.plist has NSLocationWhenInUseUsageDescription

---

### Issue 5: Firebase Initialization Fails

**Symptoms:**
- App crashes on startup after uncommenting Firebase
- Error: "No Firebase App '[DEFAULT]' has been created"

**Solution:**
1. Verify config files are in correct locations:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
2. Update `lib/utils/firebase_options.dart` with your project settings
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### Issue 6: Authentication Not Working

**Symptoms:**
- Cannot create account
- Login fails silently
- "User not found" errors

**Cause:**
Firebase Authentication not enabled or not configured properly.

**Solution:**
1. Go to Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method
4. Ensure Firebase is properly initialized in app
5. Check Firestore security rules allow user creation

---

### Issue 7: Can't See Nearby Users

**Symptoms:**
- "No users found nearby" message
- Discover tab is empty

**Possible Causes and Solutions:**

**A. No users in database:**
- Create multiple test accounts
- Add different locations to test users

**B. Location not granted:**
- Grant location permission when prompted
- Check device location settings

**C. Firestore rules too restrictive:**
- Update Firestore security rules (see SETUP_GUIDE.md)
- Ensure authenticated users can read other users' data

---

### Issue 8: Build Errors After Adding Firebase

**Symptoms:**
- Gradle build fails
- iOS build fails
- Missing dependencies

**Solution for Android:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**Solution for iOS:**
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

---

## Quick Fix Checklist

Before reporting an issue, please verify:

- [ ] `flutter pub get` completed successfully
- [ ] Firebase project created and configured
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Firebase initialization uncommented in `lib/main.dart`
- [ ] `lib/utils/firebase_options.dart` updated with your config
- [ ] Authentication enabled in Firebase Console
- [ ] Firestore Database created and rules configured
- [ ] Location permissions granted on device
- [ ] Internet connection available

---

## Current App Behavior (Before Firebase Setup)

✅ **What Works:**
- App launches successfully
- Setup screen displays with instructions
- UI themes and localization work
- Navigation structure is intact

⚠️ **What Needs Firebase:**
- User authentication (login/signup)
- Profile creation and viewing
- Chat functionality
- User discovery (nearby/similar interests)
- Location-based features

---

## Step-by-Step: First Time Setup

1. **Install Dependencies:**
   ```bash
   cd VibeNou
   flutter pub get
   ```

2. **Run the App:**
   ```bash
   flutter run
   ```
   - You'll see the **Setup Screen** with instructions

3. **Follow Setup Screen Instructions:**
   - Create Firebase project
   - Add Android/iOS apps
   - Download config files
   - Enable services

4. **Update Code:**
   - Place config files in correct locations
   - Update `lib/utils/firebase_options.dart`
   - Uncomment Firebase initialization in `lib/main.dart`:

   ```dart
   // Change from:
   // await Firebase.initializeApp(
   //   options: DefaultFirebaseOptions.currentPlatform,
   // );
   // firebaseConfigured = true;

   // To:
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   firebaseConfigured = true;
   ```

5. **Test:**
   ```bash
   flutter run
   ```
   - App should now show splash screen → login screen

---

## Getting Help

If you're still experiencing issues:

1. **Check the logs:**
   ```bash
   flutter run --verbose
   ```

2. **Check Firebase Console:**
   - Verify services are enabled
   - Check usage/quotas
   - Review security rules

3. **Common Error Messages:**

   | Error | Solution |
   |-------|----------|
   | "Firebase not initialized" | Uncomment Firebase.initializeApp() in main.dart |
   | "google-services.json not found" | Place file in android/app/ directory |
   | "Permission denied" | Update Firestore security rules |
   | "User not found" | Enable Email/Password auth in Firebase Console |

4. **Create an Issue:**
   - Include error messages
   - Include `flutter doctor` output
   - Describe steps to reproduce

---

## Pro Tips

💡 **Development Tips:**
- Use Firebase Emulator for local testing (optional)
- Create separate Firebase projects for dev/production
- Keep Firebase config files out of version control (already in .gitignore)
- Test on physical devices for location features

💡 **Performance Tips:**
- Firestore free tier: 50K reads/day, 20K writes/day
- Optimize queries to stay within limits
- Use Firestore indexes for complex queries
- Cache user data when possible

---

## Version Information

- Flutter SDK: >=3.0.0
- Firebase Core: ^2.24.2
- Firebase Auth: ^4.15.3
- Cloud Firestore: ^4.13.6

---

**Still need help?** Check:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Setup](https://firebase.flutter.dev/)
- [VibeNou SETUP_GUIDE.md](./SETUP_GUIDE.md)
