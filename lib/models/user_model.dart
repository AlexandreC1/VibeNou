/// UserModel - Complete User Profile Data Structure
///
/// This is the core data model representing a user in VibeNou.
/// It contains all profile information, preferences, and security keys.
///
/// ============================================================================
/// DATA ORGANIZATION
/// ============================================================================
///
/// The model is organized into logical sections:
library;
/// 1. BASIC PROFILE: Essential user information
/// 2. LOCATION DATA: GPS and geocoded location
/// 3. DATING PREFERENCES: User's search criteria
/// 4. ENCRYPTION KEYS: For end-to-end encrypted chat
/// 5. PUSH NOTIFICATIONS: FCM token management
///
/// ============================================================================
/// FIRESTORE MAPPING
/// ============================================================================
///
/// This model maps directly to Firestore documents:
/// Collection: `users/{uid}`
///
/// Special field types:
/// - GeoPoint: Firestore's geolocation type (lat, lng)
/// - Timestamp: Firestore's timestamp (converted to DateTime)
/// - Arrays: Firestore arrays (interests, photos, etc.)
///
/// ============================================================================
/// PRIVACY CONSIDERATIONS
/// ============================================================================
///
/// Sensitive fields that require protection:
/// - location: Only shared if locationSharingEnabled == true
/// - publicKey: Safe to share (used for encryption)
/// - encryptedPrivateKey: Never shared, device-only storage
/// - fcmToken: Server-only, not exposed in API
///
/// ============================================================================
/// IMMUTABILITY
/// ============================================================================
///
/// This model is IMMUTABLE (all fields are final).
/// To update, use the `copyWith()` method:
///
/// ```dart
/// final updatedUser = currentUser.copyWith(name: "New Name");
/// ```
///
/// Benefits:
/// - Prevents accidental mutations
/// - Easier to track state changes
/// - Better for Provider/state management
///
/// ============================================================================
/// USAGE EXAMPLES
/// ============================================================================
///
/// Create from Firestore:
/// ```dart
/// final snapshot = await FirebaseFirestore.instance
///     .collection('users')
///     .doc(uid)
///     .get();
/// final user = UserModel.fromMap(snapshot.data()!, snapshot.id);
/// ```
///
/// Update and save:
/// ```dart
/// final updated = user.copyWith(bio: "New bio");
/// await FirebaseFirestore.instance
///     .collection('users')
///     .doc(user.uid)
///     .update(updated.toMap());
/// ```
///
/// ============================================================================
/// VALIDATION RULES
/// ============================================================================
///
/// Client-side validation (enforced in UI):
/// - age: 18-100
/// - name: 1-50 characters
/// - bio: 0-500 characters
/// - interests: 0-15 items
/// - photos: 0-6 URLs
///
/// Server-side validation (Firestore Security Rules):
/// - uid must match authenticated user
/// - required fields cannot be null
/// - age >= 18
///
/// Last updated: 2025-12-22
/// Author: VibeNou Team

import 'package:cloud_firestore/cloud_firestore.dart';

/// UserModel - Immutable user profile data model
///
/// Represents a complete user profile with all associated data.
/// Maps to Firestore collection: `users/{uid}`
class UserModel {
  // ========== SECTION 1: BASIC PROFILE INFORMATION ==========

  /// Unique user identifier from Firebase Authentication
  /// This is the primary key and never changes
  final String uid;

  /// User's email address from Firebase Auth
  /// Used for login and account recovery
  final String email;

  /// Display name (1-50 characters)
  /// Shown on profile, in chat, and in discovery
  final String name;

  /// User's age (18-100)
  /// Used for age-based matching and filtering
  final int age;

  /// Personal bio/description (0-500 characters)
  /// Appears on profile to describe the user
  final String bio;

  /// List of interests (0-15 items)
  /// Examples: ["Music", "Travel", "Sports"]
  /// Used for matching algorithm
  final List<String> interests;

  /// Primary profile picture URL
  /// Stored in Supabase Storage, referenced here
  /// Null if user hasn't uploaded a photo
  final String? photoUrl;

  /// Additional profile photos (0-6 URLs)
  /// Shown in photo gallery on profile
  /// Stored in Supabase Storage
  final List<String> photos;

  // ========== SECTION 2: LOCATION DATA ==========

  /// User's GPS location as GeoPoint(latitude, longitude)
  /// Used for nearby user discovery
  /// Only shared if locationSharingEnabled == true
  /// Null if user hasn't granted location permission
  final GeoPoint? location;

  /// Geocoded city name
  /// Example: "Port-au-Prince"
  /// Derived from GPS coordinates via reverse geocoding
  final String? city;

  /// Geocoded country name
  /// Example: "Haiti"
  /// Derived from GPS coordinates
  final String? country;

  // ========== SECTION 3: ACCOUNT METADATA ==========

  /// Account creation timestamp
  /// Set once during signup, never changes
  final DateTime createdAt;

  /// Last time user was active in the app
  /// Updated on app launch and periodically during use
  final DateTime lastActive;

  /// Preferred app language (ISO 639-1 code)
  /// Options: 'en' (English), 'fr' (French), 'ht' (Haitian Creole)
  /// Default: 'en'
  final String preferredLanguage;

  /// Whether user consents to sharing location data
  /// If false, location is not shown to other users
  /// Default: true
  final bool locationSharingEnabled;

  // ========== SECTION 4: PERSONAL ATTRIBUTES ==========

  /// User's self-identified gender
  /// Options: 'male', 'female', null
  /// Determines UI theming (blue vs pink)
  final String? gender;

  /// User's ethnicity (optional)
  /// Free-form text, examples: "Black/African", "Hispanic", "Asian"
  final String? ethnicity;

  /// User's sexual orientation (optional)
  /// Options: 'straight', 'gay', 'lesbian', 'bisexual', 'other', null
  final String? sexualOrientation;

  // ========== SECTION 5: DATING PREFERENCES ==========

  /// Minimum age of potential matches (18-100)
  /// Default: 18
  final int preferredAgeMin;

  /// Maximum age of potential matches (18-100)
  /// Default: 100 (no upper limit)
  final int preferredAgeMax;

  /// Gender preference for matches
  /// Options: 'male', 'female', null (anyone)
  /// Default: null
  final String? preferredGender;

  /// Preferred ethnicities (empty = all)
  /// Empty list means no preference
  final List<String> preferredEthnicities;

  /// Preferred interests (empty = all)
  /// Used to prioritize users with shared interests
  final List<String> preferredInterests;

  /// Maximum distance for discovery in kilometers
  /// Null means no distance limit (global search)
  /// Example: 50 (show users within 50km)
  final int? preferredMaxDistance;

  // ========== SECTION 6: END-TO-END ENCRYPTION ==========

  /// RSA-2048 public key in PEM format
  /// Stored in Firestore (safe to share)
  /// Used by others to encrypt messages for this user
  /// Format: "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
  final String? publicKey;

  /// Encrypted private key (future feature)
  /// Will be encrypted with user's password for backup/recovery
  /// Currently not used - private keys stored device-only
  final String? encryptedPrivateKey;

  // ========== SECTION 7: PUSH NOTIFICATIONS ==========

  /// Firebase Cloud Messaging token
  /// Used to send push notifications to this user's device
  /// Regenerated periodically by FCM (not user-controlled)
  final String? fcmToken;

  /// Timestamp of last FCM token update
  /// Used to determine if token is stale
  final DateTime? fcmTokenUpdatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.bio,
    required this.interests,
    this.photoUrl,
    this.photos = const [],
    this.location,
    this.city,
    this.country,
    required this.createdAt,
    required this.lastActive,
    this.preferredLanguage = 'en',
    this.locationSharingEnabled = true,
    this.gender,
    this.ethnicity,
    this.sexualOrientation,
    this.preferredAgeMin = 18,
    this.preferredAgeMax = 100,
    this.preferredGender,
    this.preferredEthnicities = const [],
    this.preferredInterests = const [],
    this.preferredMaxDistance,
    this.publicKey,
    this.encryptedPrivateKey,
    this.fcmToken,
    this.fcmTokenUpdatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 18,
      bio: map['bio'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      photoUrl: map['photoUrl'],
      photos: List<String>.from(map['photos'] ?? []),
      location: map['location'],
      city: map['city'],
      country: map['country'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      locationSharingEnabled: map['locationSharingEnabled'] ?? true,
      gender: map['gender'],
      ethnicity: map['ethnicity'],
      sexualOrientation: map['sexualOrientation'],
      preferredAgeMin: map['preferredAgeMin'] ?? 18,
      preferredAgeMax: map['preferredAgeMax'] ?? 100,
      preferredGender: map['preferredGender'],
      preferredEthnicities: List<String>.from(map['preferredEthnicities'] ?? []),
      preferredInterests: List<String>.from(map['preferredInterests'] ?? []),
      preferredMaxDistance: map['preferredMaxDistance'],
      publicKey: map['publicKey'],
      encryptedPrivateKey: map['encryptedPrivateKey'],
      fcmToken: map['fcmToken'],
      fcmTokenUpdatedAt: (map['fcmTokenUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'interests': interests,
      'photoUrl': photoUrl,
      'photos': photos,
      'location': location,
      'city': city,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'preferredLanguage': preferredLanguage,
      'locationSharingEnabled': locationSharingEnabled,
      'gender': gender,
      'ethnicity': ethnicity,
      'sexualOrientation': sexualOrientation,
      'preferredAgeMin': preferredAgeMin,
      'preferredAgeMax': preferredAgeMax,
      'preferredGender': preferredGender,
      'preferredEthnicities': preferredEthnicities,
      'preferredInterests': preferredInterests,
      'preferredMaxDistance': preferredMaxDistance,
      'publicKey': publicKey,
      'encryptedPrivateKey': encryptedPrivateKey,
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt': fcmTokenUpdatedAt != null ? Timestamp.fromDate(fcmTokenUpdatedAt!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    int? age,
    String? bio,
    List<String>? interests,
    String? photoUrl,
    List<String>? photos,
    GeoPoint? location,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? lastActive,
    String? preferredLanguage,
    bool? locationSharingEnabled,
    String? gender,
    String? ethnicity,
    String? sexualOrientation,
    int? preferredAgeMin,
    int? preferredAgeMax,
    String? preferredGender,
    List<String>? preferredEthnicities,
    List<String>? preferredInterests,
    int? preferredMaxDistance,
    String? publicKey,
    String? encryptedPrivateKey,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photoUrl: photoUrl ?? this.photoUrl,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      gender: gender ?? this.gender,
      ethnicity: ethnicity ?? this.ethnicity,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      preferredAgeMin: preferredAgeMin ?? this.preferredAgeMin,
      preferredAgeMax: preferredAgeMax ?? this.preferredAgeMax,
      preferredGender: preferredGender ?? this.preferredGender,
      preferredEthnicities: preferredEthnicities ?? this.preferredEthnicities,
      preferredInterests: preferredInterests ?? this.preferredInterests,
      preferredMaxDistance: preferredMaxDistance ?? this.preferredMaxDistance,
      publicKey: publicKey ?? this.publicKey,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
    );
  }
}
