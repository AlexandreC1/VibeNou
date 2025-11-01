# VibeNou Setup Guide

This guide will walk you through setting up VibeNou from scratch, including Firebase configuration.

## Prerequisites

Before you begin, ensure you have:
- Flutter SDK installed (3.0.0+)
- Android Studio or Xcode installed
- A Google/Firebase account
- Git installed

## Step 1: Clone and Install Dependencies

```bash
git clone https://github.com/yourusername/vibenou.git
cd vibenou
flutter pub get
```

## Step 2: Firebase Project Setup

### 2.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `VibeNou`
4. Disable Google Analytics (optional)
5. Click "Create project"

### 2.2 Add Android App

1. In Firebase Console, click "Add app" → Android icon
2. Enter package name: `com.vibenou.vibenou`
3. Enter app nickname: `VibeNou Android`
4. Click "Register app"
5. Download `google-services.json`
6. Place `google-services.json` in `android/app/` directory

### 2.3 Add iOS App

1. In Firebase Console, click "Add app" → iOS icon
2. Enter bundle ID: `com.vibenou.vibenou`
3. Enter app nickname: `VibeNou iOS`
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place `GoogleService-Info.plist` in `ios/Runner/` directory

## Step 3: Enable Firebase Services

### 3.1 Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Click "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

### 3.2 Enable Firestore Database

1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in production mode"
4. Select a location (choose closest to your users)
5. Click "Enable"

### 3.3 Configure Firestore Security Rules

1. Go to "Firestore Database" → "Rules" tab
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Chat rooms
    match /chatRooms/{chatRoomId} {
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        request.auth.uid in resource.data.participants;
    }

    // Chat messages
    match /chatRooms/{chatRoomId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }

    // Reports
    match /reports/{reportId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

3. Click "Publish"

### 3.4 Enable Storage (Optional)

1. Go to "Storage"
2. Click "Get started"
3. Use the default rules
4. Click "Done"

## Step 4: Update Firebase Configuration

### 4.1 Get Firebase Configuration

1. In Firebase Console, go to Project Settings (gear icon)
2. Scroll down to "Your apps"
3. For each app (Android/iOS), you'll see the configuration

### 4.2 Update lib/utils/firebase_options.dart

Replace the placeholder values with your actual Firebase configuration:

```dart
class DefaultFirebaseOptions {
  static const firebaseOptions = {
    'apiKey': 'YOUR_API_KEY_FROM_FIREBASE',
    'appId': 'YOUR_APP_ID_FROM_FIREBASE',
    'messagingSenderId': 'YOUR_SENDER_ID_FROM_FIREBASE',
    'projectId': 'your-project-id',
    'storageBucket': 'your-project-id.appspot.com',
  };
}
```

You can find these values in:
- Android: In the `google-services.json` file
- iOS: In the `GoogleService-Info.plist` file

### 4.3 Enable Firebase in main.dart

In `lib/main.dart`, uncomment these lines:

```dart
// Uncomment these imports
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_options.dart';

// Uncomment this in main() function
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Step 5: Configure Platform-Specific Settings

### 5.1 Android Configuration

The AndroidManifest.xml is already configured with:
- Internet permission
- Location permissions (fine and coarse)

No additional changes needed!

### 5.2 iOS Configuration

The Info.plist is already configured with:
- Location usage descriptions
- Required permissions

No additional changes needed!

### 5.3 Android Gradle Settings (Optional)

If you encounter issues, update `android/gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
```

## Step 6: Create Firestore Indexes (Optional)

For better performance, create these indexes:

1. Go to Firestore Database → Indexes tab
2. Add composite indexes:

**chatRooms collection:**
- Field: `participants` (Array)
- Field: `lastMessageTime` (Descending)

**reports collection:**
- Field: `reportedUserId` (Ascending)
- Field: `timestamp` (Descending)

## Step 7: Test the App

### 7.1 Run on Android

```bash
flutter run -d android
```

### 7.2 Run on iOS

```bash
flutter run -d ios
```

### 7.3 Test Features

1. **Sign Up**:
   - Create a new account
   - Fill in profile information
   - Select interests

2. **Location**:
   - Grant location permission
   - Check if location is detected

3. **Discovery**:
   - Create multiple test accounts
   - Verify nearby users appear
   - Check interest-based matching

4. **Chat**:
   - Start a conversation
   - Send messages
   - Verify real-time updates

5. **Reports**:
   - Test the report functionality
   - Check reports in Firestore

## Step 8: Troubleshooting

### Firebase initialization error

**Problem**: App crashes on startup

**Solution**:
- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Check Firebase configuration in `firebase_options.dart`
- Run `flutter clean` and `flutter pub get`

### Location not working

**Problem**: Cannot get user location

**Solution**:
- Check location permissions in device settings
- Enable location services on device
- Test on physical device (not emulator)
- Verify permissions in AndroidManifest.xml/Info.plist

### Build errors

**Problem**: Compilation fails

**Solution**:
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter run
```

### Firestore permission denied

**Problem**: Cannot read/write to Firestore

**Solution**:
- Check Firestore security rules
- Verify user is authenticated
- Check rule syntax in Firebase Console

### Dependencies conflict

**Problem**: Package version conflicts

**Solution**:
- Update Flutter: `flutter upgrade`
- Update packages: `flutter pub upgrade`
- Check pubspec.yaml for version conflicts

## Step 9: Deployment Preparation

### 9.1 Update App Icons

Replace default icons in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Use a tool like [App Icon Generator](https://appicon.co/)

### 9.2 Update App Name

Android (`android/app/src/main/AndroidManifest.xml`):
```xml
android:label="VibeNou"
```

iOS (`ios/Runner/Info.plist`):
```xml
<key>CFBundleDisplayName</key>
<string>VibeNou</string>
```

### 9.3 Generate Signing Keys

**Android**:
```bash
keytool -genkey -v -keystore ~/vibenou-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vibenou
```

Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=vibenou
storeFile=/path/to/vibenou-key.jks
```

**iOS**:
- Use Xcode to configure signing
- Set up Apple Developer account
- Configure signing certificates

## Step 10: Production Checklist

Before releasing:

- [ ] Firebase configuration is correct
- [ ] All API keys are secured
- [ ] Firestore security rules are production-ready
- [ ] Location permissions are properly explained
- [ ] Privacy policy is added
- [ ] Terms of service are added
- [ ] App icons are updated
- [ ] App is tested on multiple devices
- [ ] Crashlytics is set up (optional)
- [ ] Analytics is configured (optional)
- [ ] Push notifications are tested (if implemented)

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Setup](https://firebase.flutter.dev/docs/overview)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli)

## Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
3. Check [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
4. Open an issue in this repository

---

Happy coding! 🚀
