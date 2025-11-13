/// Message model representing a chat message
/// Maps to the 'messages' table in Supabase
class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  /// Create Message from Supabase JSON response
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatRoomId: json['chat_room_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  /// Convert Message to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  /// Check if message has been read
  bool get isRead => readAt != null;

  /// Check if message was sent by a specific user
  bool isSentBy(String userId) {
    return senderId == userId;
  }

  /// Get time difference from now in a human-readable format
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  /// Format timestamp for display in chat
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    final timeStr = '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == yesterday) {
      return 'Yesterday $timeStr';
    } else if (difference.inDays < 7) {
      return '${_getDayName(createdAt.weekday)} $timeStr';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Duration get difference => DateTime.now().difference(createdAt);

  /// Copy with method for immutability
  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Mark message as read
  Message markAsRead() {
    return copyWith(readAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.chatRoomId == chatRoomId &&
        other.senderId == senderId &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      chatRoomId,
      senderId,
      content,
      createdAt,
      readAt,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, chatRoomId: $chatRoomId, senderId: $senderId, '
        'content: ${content.substring(0, content.length > 20 ? 20 : content.length)}..., '
        'createdAt: $createdAt)';
  }
}
