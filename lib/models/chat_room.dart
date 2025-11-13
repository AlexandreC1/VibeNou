/// ChatRoom model representing a conversation between two users
/// Maps to the 'chat_rooms' table in Supabase
class ChatRoom {
  final String id;
  final String participant1;
  final String participant2;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.participant1,
    required this.participant2,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ChatRoom from Supabase JSON response
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      participant1: json['participant_1'] as String,
      participant2: json['participant_2'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert ChatRoom to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_1': participant1,
      'participant_2': participant2,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get the other participant's ID given the current user's ID
  String getOtherParticipantId(String currentUserId) {
    return currentUserId == participant1 ? participant2 : participant1;
  }

  /// Check if a user is a participant in this chat room
  bool isParticipant(String userId) {
    return userId == participant1 || userId == participant2;
  }

  /// Copy with method for immutability
  ChatRoom copyWith({
    String? id,
    String? participant1,
    String? participant2,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participant1: participant1 ?? this.participant1,
      participant2: participant2 ?? this.participant2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatRoom &&
        other.id == id &&
        other.participant1 == participant1 &&
        other.participant2 == participant2 &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      participant1,
      participant2,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatRoom(id: $id, participant1: $participant1, participant2: $participant2)';
  }
}

/// Extended ChatRoom with additional metadata for the chat list screen
class ChatRoomWithMetadata extends ChatRoom {
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  ChatRoomWithMetadata({
    required super.id,
    required super.participant1,
    required super.participant2,
    required super.createdAt,
    required super.updatedAt,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory ChatRoomWithMetadata.fromChatRoom(
    ChatRoom chatRoom, {
    String? otherUserName,
    String? otherUserPhotoUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int unreadCount = 0,
    bool isOnline = false,
  }) {
    return ChatRoomWithMetadata(
      id: chatRoom.id,
      participant1: chatRoom.participant1,
      participant2: chatRoom.participant2,
      createdAt: chatRoom.createdAt,
      updatedAt: chatRoom.updatedAt,
      otherUserName: otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isOnline: isOnline,
    );
  }
}
