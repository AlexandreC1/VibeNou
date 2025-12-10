import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessStory {
  final String id;
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String user1Photo;
  final String user2Photo;
  final String story;
  final DateTime metDate;
  final DateTime createdAt;
  final int likes;
  final bool isVerified;

  SuccessStory({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    required this.user1Photo,
    required this.user2Photo,
    required this.story,
    required this.metDate,
    required this.createdAt,
    this.likes = 0,
    this.isVerified = false,
  });

  factory SuccessStory.fromMap(Map<String, dynamic> map, String id) {
    return SuccessStory(
      id: id,
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      user1Name: map['user1Name'] ?? '',
      user2Name: map['user2Name'] ?? '',
      user1Photo: map['user1Photo'] ?? '',
      user2Photo: map['user2Photo'] ?? '',
      story: map['story'] ?? '',
      metDate: (map['metDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: map['likes'] ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'user1Photo': user1Photo,
      'user2Photo': user2Photo,
      'story': story,
      'metDate': Timestamp.fromDate(metDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'isVerified': isVerified,
    };
  }
}
