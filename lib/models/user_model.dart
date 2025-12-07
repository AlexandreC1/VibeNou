import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final int age;
  final String bio;
  final List<String> interests;
  final String? photoUrl;
  final List<String> photos; // Multiple photos for profile gallery
  final GeoPoint? location;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final DateTime lastActive;
  final String preferredLanguage;
  final bool locationSharingEnabled; // Control whether to share location
  final String? gender; // 'male' or 'female'

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
    );
  }
}
