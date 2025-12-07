import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileView {
  final String id;
  final String viewerId;
  final String viewedUserId;
  final DateTime viewedAt;
  final bool isRead;

  ProfileView({
    required this.id,
    required this.viewerId,
    required this.viewedUserId,
    required this.viewedAt,
    this.isRead = false,
  });

  factory ProfileView.fromMap(Map<String, dynamic> map, String id) {
    return ProfileView(
      id: id,
      viewerId: map['viewerId'] ?? '',
      viewedUserId: map['viewedUserId'] ?? '',
      viewedAt: (map['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'viewerId': viewerId,
      'viewedUserId': viewedUserId,
      'viewedAt': Timestamp.fromDate(viewedAt),
      'isRead': isRead,
    };
  }
}
