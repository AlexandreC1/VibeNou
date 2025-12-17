import 'package:cloud_firestore/cloud_firestore.dart';

// Pagination helper class
class PaginatedMessages {
  final List<ChatMessage> messages;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedMessages({
    required this.messages,
    this.lastDocument,
    required this.hasMore,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message; // Fallback for unencrypted messages or placeholder like "[Encrypted]"
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  // Encryption fields for end-to-end encrypted messages
  final String? encryptedMessage; // AES-encrypted message content
  final String? iv; // Initialization vector for AES decryption

  // Cached decrypted message (not stored in Firestore)
  String? _decryptedMessage;

  /// Get displayable message text
  /// Returns decrypted message if available, otherwise falls back to plaintext message
  String get displayMessage => _decryptedMessage ?? message;

  /// Set decrypted message (called after decryption)
  void setDecryptedMessage(String decrypted) {
    _decryptedMessage = decrypted;
  }

  /// Check if this message is encrypted
  bool get isEncrypted => encryptedMessage != null && iv != null;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.encryptedMessage,
    this.iv,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      encryptedMessage: map['encryptedMessage'],
      iv: map['iv'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'encryptedMessage': encryptedMessage,
      'iv': iv,
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, String>? encryptedSymmetricKeys; // userId -> encrypted symmetric key

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.encryptedSymmetricKeys,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      encryptedSymmetricKeys: map['encryptedSymmetricKeys'] != null
          ? Map<String, String>.from(map['encryptedSymmetricKeys'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'encryptedSymmetricKeys': encryptedSymmetricKeys,
    };
  }
}
