// Firebase configuration
// Replace these values with your actual Firebase project configuration
// Get these from Firebase Console > Project Settings > Your apps

class DefaultFirebaseOptions {
  static const firebaseOptions = {
    'apiKey': 'YOUR_API_KEY',
    'appId': 'YOUR_APP_ID',
    'messagingSenderId': 'YOUR_MESSAGING_SENDER_ID',
    'projectId': 'YOUR_PROJECT_ID',
    'storageBucket': 'YOUR_STORAGE_BUCKET',
    'iosClientId': 'YOUR_IOS_CLIENT_ID',
    'iosBundleId': 'com.vibenou.vibenou',
  };

  // Instructions to set up Firebase:
  // 1. Go to https://console.firebase.google.com/
  // 2. Create a new project or select existing one
  // 3. Add an app (Android/iOS) to your project
  // 4. Download google-services.json (Android) and GoogleService-Info.plist (iOS)
  // 5. Place them in android/app/ and ios/Runner/ respectively
  // 6. Enable Authentication (Email/Password) in Firebase Console
  // 7. Enable Firestore Database in Firebase Console
  // 8. Enable Storage in Firebase Console
  // 9. Update the values above with your Firebase configuration
}
