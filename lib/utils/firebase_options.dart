// Firebase configuration
// File generated for VibeNou
// To get your configuration values:
// 1. Go to Firebase Console > Project Settings
// 2. Scroll down to "Your apps" section
// 3. Select your Android/iOS app
// 4. Copy the config values and replace the placeholders below

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ANDROID CONFIGURATION
  // Get these values from Firebase Console > Project Settings > Android app
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  // iOS CONFIGURATION
  // Get these values from Firebase Console > Project Settings > iOS app
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.vibenou.vibenou',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
  );
}

// HOW TO GET YOUR VALUES:
// ========================
//
// 1. Go to: https://console.firebase.google.com/
// 2. Select your VibeNou project
// 3. Click the gear icon (⚙️) → Project Settings
// 4. Scroll down to "Your apps" section
//
// FOR ANDROID:
// - Click on your Android app
// - Find these values in the config snippet:
//   * apiKey: Look for "current_key" in google-services.json
//   * appId: Look for "mobilesdk_app_id" (format: 1:123456789:android:abc123...)
//   * messagingSenderId: Look for "project_number"
//   * projectId: Your Firebase project ID
//   * storageBucket: Usually "YOUR_PROJECT_ID.appspot.com"
//
// FOR iOS (if using):
// - Click on your iOS app
// - Find these values in GoogleService-Info.plist:
//   * apiKey: API_KEY value
//   * appId: GOOGLE_APP_ID value (format: 1:123456789:ios:abc123...)
//   * messagingSenderId: GCM_SENDER_ID value
//   * projectId: PROJECT_ID value
//   * iosClientId: CLIENT_ID value
//   * iosBundleId: BUNDLE_ID value
//
// EXAMPLE (DO NOT USE THESE VALUES):
// apiKey: 'AIzaSyAbc123...'
// appId: '1:123456789:android:abc123def456'
// messagingSenderId: '123456789'
// projectId: 'vibenou-12345'
// storageBucket: 'vibenou-12345.appspot.com'
