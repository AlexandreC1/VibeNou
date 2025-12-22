# VibeNou Architecture Documentation

> **Last Updated:** December 22, 2025
> **Version:** 1.0.0
> **Author:** VibeNou Development Team

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Architecture Patterns](#architecture-patterns)
4. [Core Features](#core-features)
5. [Security Architecture](#security-architecture)
6. [Database Schema](#database-schema)
7. [UI/UX Design System](#uiux-design-system)
8. [Performance Optimizations](#performance-optimizations)
9. [Future Roadmap](#future-roadmap)

---

## Overview

VibeNou is a modern dating application built with Flutter, featuring end-to-end encrypted messaging, location-based discovery, and a gender-adaptive UI. The app emphasizes security, performance, and user experience.

### Key Principles

- **Security First**: End-to-end encryption for all messages
- **Privacy by Design**: Location sharing controls, encrypted data
- **Performance**: Pagination, caching, optimized queries
- **Accessibility**: Multi-language support, clear UI hierarchy
- **Maintainability**: Extensive documentation, clean code

---

## Technology Stack

### Frontend
- **Framework**: Flutter 3.x (Dart)
- **State Management**: Provider pattern
- **UI Components**: Material Design 3
- **Image Caching**: `cached_network_image`
- **Localization**: `flutter_localizations` (EN, FR, HT)

### Backend
- **Database**: Firebase Firestore (NoSQL)
- **Authentication**: Firebase Auth
- **Storage**: Supabase Storage (images)
- **Cloud Functions**: Firebase Functions (Node.js)
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Security & Encryption
- **Encryption Library**: `pointycastle` (Pure Dart crypto)
- **Key Storage**: `flutter_secure_storage`
  - iOS: Keychain
  - Android: EncryptedSharedPreferences
- **Algorithms**:
  - RSA-2048 (key exchange)
  - AES-256-GCM (message encryption)

### Services
- **Location**: `geolocator` package
- **Maps/Geocoding**: Location services
- **Analytics**: Firebase Analytics (optional)

---

## Architecture Patterns

### 1. Service-Oriented Architecture

```
lib/
├── services/          # Business logic layer
│   ├── auth_service.dart           # Authentication & user management
│   ├── chat_service.dart           # Messaging & real-time chat
│   ├── encryption_service.dart     # End-to-end encryption
│   ├── notification_service.dart   # Push notifications
│   ├── location_service.dart       # GPS & geocoding
│   ├── user_service.dart           # User data operations
│   └── key_storage_service.dart    # Secure key management
```

**Benefits:**
- Clear separation of concerns
- Reusable business logic
- Easy to test and mock
- Centralized error handling

### 2. Provider Pattern for State Management

```dart
// Example: Accessing AuthService
final authService = Provider.of<AuthService>(context, listen: false);
final user = authService.currentUser;
```

**Why Provider?**
- Simple and lightweight
- Built into Flutter
- Good performance
- Easy dependency injection

### 3. Model-View Pattern

```
lib/
├── models/            # Data models
│   ├── user_model.dart
│   ├── chat_message.dart
│   └── profile_view_model.dart
├── screens/           # UI layer (Views)
│   ├── home/
│   ├── chat/
│   └── profile/
└── widgets/           # Reusable components
```

---

## Core Features

### 1. Authentication & User Management

**Flow:**
```
Sign Up → Email Verification → Profile Creation → Key Generation → Ready
```

**Features:**
- Email/password authentication
- Profile setup (name, age, bio, interests)
- Photo upload (up to 6 photos)
- Gender & dating preferences
- Automatic RSA key pair generation

**Files:**
- `lib/services/auth_service.dart`
- `lib/screens/auth/`

### 2. End-to-End Encrypted Messaging

**Encryption Flow:**
```
1. User A types message
2. Fetch symmetric key (decrypt with private key)
3. Encrypt message with AES-256-GCM
4. Upload {encryptedMessage, IV} to Firestore
5. User B downloads encrypted message
6. Decrypt with their copy of symmetric key
7. Display plaintext
```

**Key Features:**
- Hybrid encryption (RSA + AES)
- Perfect forward secrecy (unique key per chat)
- Graceful fallback to plaintext
- Comprehensive logging

**Files:**
- `lib/services/encryption_service.dart`
- `lib/services/chat_service.dart`
- `lib/services/key_storage_service.dart`

### 3. Read Receipts

**Flow:**
```
Message Sent (isRead: false, gray, ✓)
     ↓
Recipient Opens Chat
     ↓
markAsRead() called
     ↓
Batch update isRead: true
     ↓
Real-time stream updates sender's UI
     ↓
Message turns gradient, shows ✓✓
```

**Implementation:**
- `isRead` field on each message
- Batch writes for efficiency
- Real-time sync via Firestore streams
- Visual feedback (color + checkmarks)

**Files:**
- `lib/services/chat_service.dart` (lines 515-598)
- `lib/screens/chat/chat_screen.dart`

### 4. Location-Based Discovery

**Features:**
- GPS location acquisition
- Haversine formula for distance calculation
- Configurable search radius
- Privacy controls (location sharing toggle)

**Flow:**
```
Request Permission → Get GPS → Geocode → Store GeoPoint → Query Nearby
```

**Files:**
- `lib/services/location_service.dart`
- `lib/services/user_service.dart`
- `lib/screens/home/discover_screen.dart`

### 5. Gender-Based Theming

**Design System:**

| Gender | Primary Color | Gradient | Accents |
|--------|--------------|----------|---------|
| Male   | Blue (#4A90E2) | Blue → Teal → Navy | Sky Blue, Teal |
| Female | Rose (#FF6B9D) | Rose → Pink → Purple | Coral, Lavender |

**Implementation:**
```dart
final gradient = user.gender == 'male'
    ? AppTheme.primaryBlueGradient
    : AppTheme.primaryGradient;
```

**Files:**
- `lib/utils/app_theme.dart`
- Applied throughout UI (AppBars, cards, buttons)

### 6. Push Notifications

**Architecture:**
```
Cloud Function → FCM → Device → Notification Service → Display
```

**Features:**
- Message notifications
- Background message handling
- Custom notification sounds
- Deep linking to chat

**Files:**
- `lib/services/notification_service.dart`
- `functions/index.js` (Cloud Functions)

---

## Security Architecture

### Threat Model

**Protected Against:**
- ✅ Network eavesdropping
- ✅ Server compromise
- ✅ Database breach
- ✅ Man-in-the-middle (with key verification)

**Not Protected Against:**
- ❌ Device compromise (malware with root)
- ❌ Shoulder surfing
- ❌ Screenshots

### Encryption Details

#### RSA-2048 Key Generation
```dart
// Generate on user signup
final keyPair = await EncryptionService.generateUserKeyPair();
// Returns: {publicKey: PEM, privateKey: PEM}
```

**Storage:**
- Public key → Firestore (`users/{uid}/publicKey`)
- Private key → Device secure storage (`private_key_{uid}`)

#### AES-256-GCM Message Encryption
```dart
// Encrypt
final encrypted = EncryptionService.encryptMessage(message, symmetricKey);
// Returns: {encryptedMessage: base64, iv: base64}

// Decrypt
final plaintext = EncryptionService.decryptMessage(
  encryptedMessage: encrypted['encryptedMessage'],
  ivBase64: encrypted['iv'],
  symmetricKeyBase64: symmetricKey,
);
```

### Input Validation & Sanitization

**Message Validation:**
- Max length: 5000 characters
- No empty messages
- XSS prevention (strip HTML/script tags)

**Files:**
- `lib/services/chat_service.dart` (lines 65-125)

---

## Database Schema

### Firestore Collections

#### `users`
```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "name": "John Doe",
  "age": 25,
  "gender": "male",
  "bio": "Hello!",
  "interests": ["Music", "Travel"],
  "photoUrl": "https://...",
  "photos": ["https://...", "https://..."],
  "location": GeoPoint(lat, lng),
  "city": "Port-au-Prince",
  "publicKey": "-----BEGIN PUBLIC KEY-----...",
  "fcmToken": "firebase_token",
  "preferredLanguage": "ht",
  "preferredAgeMin": 18,
  "preferredAgeMax": 35,
  "preferredGender": "female",
  "preferredEthnicities": [],
  "preferredInterests": []
}
```

#### `chatRooms`
```json
{
  "chatRoomId": "userId1_userId2",
  "participants": ["userId1", "userId2"],
  "lastMessage": "Hello!",
  "lastMessageTime": Timestamp,
  "unreadCount": {
    "userId1": 0,
    "userId2": 3
  },
  "encryptedSymmetricKeys": {
    "userId1": "encrypted_key_for_user1",
    "userId2": "encrypted_key_for_user2"
  }
}
```

#### `chatRooms/{id}/messages` (subcollection)
```json
{
  "messageId": "auto_generated",
  "senderId": "userId1",
  "receiverId": "userId2",
  "message": "[Encrypted]",
  "encryptedMessage": "base64_encrypted",
  "iv": "base64_iv",
  "isRead": false,
  "timestamp": Timestamp
}
```

### Indexes Required

```
Collection: chatRooms/{id}/messages
- receiverId ASC, isRead ASC
- timestamp DESC
```

---

## UI/UX Design System

### Color Palette

#### Female Theme
```dart
Primary: #FF6B9D (Rose)
Secondary: #9B59B6 (Royal Purple)
Accent: #FF6F61 (Coral)
Background: #FFF5F7
```

#### Male Theme
```dart
Primary: #4A90E2 (Blue)
Secondary: #26C6DA (Teal)
Accent: #1565C0 (Deep Blue)
Background: #F0F7FF
```

### Typography
```dart
Headings: Roboto Bold, 24-32px
Body: Roboto Regular, 14-16px
Captions: Roboto Light, 12px
```

### Component Library

**Cards:**
- Border radius: 20px
- Elevation: 3-4
- Padding: 20px

**Buttons:**
- Primary: Gradient background
- Secondary: Outlined
- FAB: 56x56, bottom-right

**Input Fields:**
- Border radius: 16px
- Border: 1.5px
- Focused: 2.5px

---

## Performance Optimizations

### 1. Message Pagination
- Load 20 messages per page
- Lazy loading on scroll
- Cursor-based pagination

### 2. Image Optimization
- `CachedNetworkImage` for profile pictures
- Lazy loading in galleries
- Thumbnail generation (future)

### 3. Query Optimization
- Composite indexes
- `limit()` on all queries
- Only fetch required fields

### 4. Real-time Streams
- Unsubscribe when widget disposed
- Debounced typing indicators
- Conditional stream subscriptions

---

## Future Roadmap

### Phase 1: Core Improvements
- [ ] Message editing/deletion
- [ ] Voice messages
- [ ] Image sharing in chat
- [ ] Profile verification badges
- [ ] Block/report functionality (partially implemented)

### Phase 2: Advanced Features
- [ ] Video calls (WebRTC)
- [ ] Story/status updates
- [ ] In-app purchases (premium features)
- [ ] AI matching algorithm
- [ ] Icebreaker suggestions

### Phase 3: Security Enhancements
- [ ] Key fingerprint verification
- [ ] Disappearing messages
- [ ] Screenshot detection
- [ ] Biometric authentication
- [ ] Session management

### Phase 4: Analytics & Growth
- [ ] A/B testing framework
- [ ] Advanced analytics dashboard
- [ ] Referral system
- [ ] Social media integration

---

## Getting Started

### Prerequisites
```bash
flutter --version  # >= 3.0.0
dart --version     # >= 3.0.0
```

### Setup
```bash
# 1. Clone repository
git clone https://github.com/AlexandreC1/VibeNou.git

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# - Add google-services.json (Android)
# - Add GoogleService-Info.plist (iOS)

# 4. Run app
flutter run
```

### Environment Variables
```
SUPABASE_URL=<your_supabase_url>
SUPABASE_ANON_KEY=<your_key>
```

---

## Contributing

See `CONTRIBUTING.md` for guidelines.

---

## License

Proprietary - All rights reserved

---

## Support

For questions or issues:
- Email: support@vibenou.com
- GitHub Issues: https://github.com/AlexandreC1/VibeNou/issues

---

**End of Documentation**
