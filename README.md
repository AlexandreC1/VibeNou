# VibeNou 🇭🇹

A Flutter cross-platform mobile-first app connecting the Haitian community through location-based pairing and chat.

## 🌟 Features

### Core Functionality
- **Multi-Language Support**: Full support for English, French, and Haitian Creole (Kreyòl Ayisyen)
- **Location-Based Discovery**: Find nearby users within a customizable radius
- **Interest-Based Matching**: Connect with people who share similar interests
- **Real-Time Chat**: Firebase-powered messaging system
- **User Profiles**: Customizable profiles with bio, interests, and location
- **Report System**: Built-in reporting mechanism for inappropriate behavior
- **Modern UI**: Sleek, intuitive interface with Haitian flag-inspired color palette

### Technical Features
- Firebase Authentication (Email/Password)
- Cloud Firestore for real-time data
- Location services with GPS integration
- Similarity algorithm for interest matching
- Responsive design for all screen sizes

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Firebase account
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/vibenou.git
   cd vibenou
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   a. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)

   b. Add Android and iOS apps to your Firebase project

   c. Download configuration files:
      - `google-services.json` for Android → place in `android/app/`
      - `GoogleService-Info.plist` for iOS → place in `ios/Runner/`

   d. Enable Firebase services:
      - **Authentication**: Enable Email/Password sign-in method
      - **Firestore Database**: Create a database in production mode
      - **Storage**: Enable Firebase Storage

   e. Update Firebase configuration in `lib/utils/firebase_options.dart`:
      ```dart
      static const firebaseOptions = {
        'apiKey': 'YOUR_API_KEY',
        'appId': 'YOUR_APP_ID',
        'messagingSenderId': 'YOUR_MESSAGING_SENDER_ID',
        'projectId': 'YOUR_PROJECT_ID',
        'storageBucket': 'YOUR_STORAGE_BUCKET',
      };
      ```

4. **Update Firebase in main.dart**

   Uncomment the Firebase initialization in `lib/main.dart`:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

5. **Configure Firestore Security Rules**

   Add these rules to your Firestore:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.auth.uid == userId;
       }

       match /chatRooms/{chatRoomId} {
         allow read, write: if request.auth != null &&
           request.auth.uid in resource.data.participants;
       }

       match /chatRooms/{chatRoomId}/messages/{messageId} {
         allow read, write: if request.auth != null;
       }

       match /reports/{reportId} {
         allow create: if request.auth != null;
         allow read: if request.auth != null;
       }
     }
   }
   ```

6. **Set up location permissions**

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to show nearby users</string>
   <key>NSLocationAlwaysUsageDescription</key>
   <string>We need your location to show nearby users</string>
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── l10n/                     # Localization files
│   └── app_localizations.dart
├── models/                   # Data models
│   ├── user_model.dart
│   ├── chat_message.dart
│   └── report_model.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   ├── main_screen.dart
│   │   ├── discover_screen.dart
│   │   ├── chat_list_screen.dart
│   │   └── profile_screen.dart
│   ├── chat/
│   │   └── chat_screen.dart
│   └── splash_screen.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── chat_service.dart
│   ├── report_service.dart
│   └── location_service.dart
├── widgets/                  # Reusable widgets
│   ├── user_card.dart
│   └── report_dialog.dart
├── utils/                    # Utilities
│   ├── app_theme.dart
│   └── firebase_options.dart
└── main.dart                # App entry point
```

## 🎨 Design

The app features a modern, clean design inspired by the Haitian flag:
- **Primary Blue**: #003087 (Haitian flag blue)
- **Primary Red**: #CE1126 (Haitian flag red)
- **Accent Colors**: Teal (#00BFA5), Coral (#FF6B6B)
- **Typography**: Clean, readable fonts with proper hierarchy

## 🌍 Supported Languages

- **English** (en)
- **Français** (fr) - French
- **Kreyòl Ayisyen** (ht) - Haitian Creole

Users can switch languages in the app settings or during login.

## 🔒 Privacy & Security

- All user data is stored securely in Firebase Firestore
- Location data is only shared with user consent
- Report system allows users to flag inappropriate behavior
- Firebase Authentication ensures secure login
- Firestore security rules protect user data

## 📦 Dependencies

Main packages used:
- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `cloud_firestore` - Real-time database
- `geolocator` - Location services
- `geocoding` - Address from coordinates
- `provider` - State management
- `timeago` - Relative time formatting
- `shared_preferences` - Local storage

See `pubspec.yaml` for complete list.

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🏗️ Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Haitian community for inspiration
- Flutter team for the amazing framework
- Firebase for backend services

## 📞 Support

For support, email support@vibenou.com or open an issue on GitHub.

## 🗺️ Roadmap

### Phase 1 (Current)
- [x] User authentication
- [x] Profile creation
- [x] Location-based discovery
- [x] Interest matching
- [x] Real-time chat
- [x] Report system
- [x] Multi-language support

### Phase 2 (Upcoming)
- [ ] Push notifications
- [ ] Image sharing in chat
- [ ] User verification system
- [ ] Events and meetups
- [ ] Community groups
- [ ] Video/audio calls
- [ ] Premium features

### Phase 3 (Future)
- [ ] AI-powered matching
- [ ] Advanced analytics
- [ ] Business profiles
- [ ] Marketplace integration
- [ ] Social media integration

## 💡 Tips for Development

1. **Firebase Emulator**: Use Firebase emulator for local development
2. **Hot Reload**: Take advantage of Flutter's hot reload for faster development
3. **State Management**: The app uses Provider, but can be migrated to Riverpod/Bloc
4. **Location Testing**: Use location simulation in iOS Simulator/Android Emulator
5. **Localization**: Add new translations in `lib/l10n/app_localizations.dart`

## ⚠️ Known Issues

- Firebase configuration must be completed before running
- Location services require physical device for accurate testing
- Some translations may need refinement by native speakers

## 🔧 Troubleshooting

### Firebase initialization error
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Ensure Firebase project is properly configured
- Check that all Firebase services are enabled

### Location not working
- Verify location permissions are granted
- Check that location services are enabled on device
- Ensure proper permissions in AndroidManifest.xml/Info.plist

### Build errors
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK is up to date
- Check for conflicts in pubspec.yaml

---

Made with ❤️ for the Haitian community
