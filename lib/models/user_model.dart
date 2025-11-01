import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final int age;
  final String bio;
  final List<String> interests;
  final String? photoUrl;
  final GeoPoint? location;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final DateTime lastActive;
  final String preferredLanguage;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.bio,
    required this.interests,
    this.photoUrl,
    this.location,
    this.city,
    this.country,
    required this.createdAt,
    required this.lastActive,
    this.preferredLanguage = 'en',
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
      location: map['location'],
      city: map['city'],
      country: map['country'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferredLanguage: map['preferredLanguage'] ?? 'en',
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
      'location': location,
      'city': city,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'preferredLanguage': preferredLanguage,
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
    GeoPoint? location,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? lastActive,
    String? preferredLanguage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
