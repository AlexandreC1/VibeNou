import 'package:flutter/foundation.dart';

/// User model representing a VibeNou user profile
/// Maps to the 'users' table in Supabase
class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final String? bio;
  final List<String> interests;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final DateTime lastActive;
  final String preferredLanguage;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    this.bio,
    this.interests = const [],
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    required this.createdAt,
    required this.lastActive,
    this.preferredLanguage = 'en',
  });

  /// Create UserModel from Supabase JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse location from PostGIS POINT format if present
    double? lat;
    double? lng;

    // Location might come as geography JSON or separate fields
    if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num?)?.toDouble();
      lng = (json['longitude'] as num?)?.toDouble();
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bio: json['bio'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : [],
      photoUrl: json['photo_url'] as String?,
      latitude: lat,
      longitude: lng,
      city: json['city'] as String?,
      country: json['country'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActive: DateTime.parse(json['last_active'] as String),
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
    );
  }

  /// Convert UserModel to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'interests': interests,
      'photo_url': photoUrl,
      'city': city,
      'country': country,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'preferred_language': preferredLanguage,
    };
  }

  /// Convert location to PostGIS POINT format for database storage
  /// Returns a string like "POINT(longitude latitude)"
  String? get locationAsPoint {
    if (latitude == null || longitude == null) return null;
    return 'POINT($longitude $latitude)';
  }

  /// Check if user has a valid location
  bool get hasLocation => latitude != null && longitude != null;

  /// Calculate age group for matching
  String get ageGroup {
    if (age < 20) return '13-19';
    if (age < 30) return '20-29';
    if (age < 40) return '30-39';
    if (age < 50) return '40-49';
    return '50+';
  }

  /// Check if user is recently active (within last 7 days)
  bool get isRecentlyActive {
    final difference = DateTime.now().difference(lastActive);
    return difference.inDays < 7;
  }

  /// Copy with method for immutability
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? bio,
    List<String>? interests,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? lastActive,
    String? preferredLanguage,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.age == age &&
        other.bio == bio &&
        listEquals(other.interests, interests) &&
        other.photoUrl == photoUrl &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.city == city &&
        other.country == country &&
        other.createdAt == createdAt &&
        other.lastActive == lastActive &&
        other.preferredLanguage == preferredLanguage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      age,
      bio,
      Object.hashAll(interests),
      photoUrl,
      latitude,
      longitude,
      city,
      country,
      createdAt,
      lastActive,
      preferredLanguage,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, age: $age, city: $city)';
  }
}

/// Extension for nearby user results from get_nearby_users function
class NearbyUser extends UserModel {
  final double distanceKm;

  NearbyUser({
    required super.id,
    required super.email,
    required super.name,
    required super.age,
    super.bio,
    super.interests,
    super.photoUrl,
    super.latitude,
    super.longitude,
    super.city,
    super.country,
    required super.createdAt,
    required super.lastActive,
    super.preferredLanguage,
    required this.distanceKm,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    final user = UserModel.fromJson(json);
    return NearbyUser(
      id: user.id,
      email: user.email,
      name: user.name,
      age: user.age,
      bio: user.bio,
      interests: user.interests,
      photoUrl: user.photoUrl,
      latitude: user.latitude,
      longitude: user.longitude,
      city: user.city,
      country: user.country,
      createdAt: user.createdAt,
      lastActive: user.lastActive,
      preferredLanguage: user.preferredLanguage,
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km away';
    } else {
      return '${distanceKm.round()}km away';
    }
  }
}

/// Extension for users with similar interests
class SimilarInterestUser extends UserModel {
  final int commonInterests;

  SimilarInterestUser({
    required super.id,
    required super.email,
    required super.name,
    required super.age,
    super.bio,
    super.interests,
    super.photoUrl,
    super.latitude,
    super.longitude,
    super.city,
    super.country,
    required super.createdAt,
    required super.lastActive,
    super.preferredLanguage,
    required this.commonInterests,
  });

  factory SimilarInterestUser.fromJson(Map<String, dynamic> json) {
    final user = UserModel.fromJson(json);
    return SimilarInterestUser(
      id: user.id,
      email: user.email,
      name: user.name,
      age: user.age,
      bio: user.bio,
      interests: user.interests,
      photoUrl: user.photoUrl,
      latitude: user.latitude,
      longitude: user.longitude,
      city: user.city,
      country: user.country,
      createdAt: user.createdAt,
      lastActive: user.lastActive,
      preferredLanguage: user.preferredLanguage,
      commonInterests: json['common_interests'] as int,
    );
  }
}
