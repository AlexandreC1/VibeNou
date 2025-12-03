import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileView {
  final String id;
  final String viewerId; // User who viewed the profile
  final String viewedUserId; // User whose profile was viewed
  final DateTime viewedAt;
  final bool isRead; // Has the profile owner seen this notification

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

  ProfileView copyWith({
    String? id,
    String? viewerId,
    String? viewedUserId,
    DateTime? viewedAt,
    bool? isRead,
  }) {
    return ProfileView(
      id: id ?? this.id,
      viewerId: viewerId ?? this.viewerId,
      viewedUserId: viewedUserId ?? this.viewedUserId,
      viewedAt: viewedAt ?? this.viewedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
