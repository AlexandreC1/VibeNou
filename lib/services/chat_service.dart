import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';
import 'encryption_service.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Validate message content
  String? _validateMessage(String message) {
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      return 'Message cannot be empty';
    }

    if (trimmed.length > 5000) {
      return 'Message too long (max 5000 characters)';
    }

    return null; // Valid
  }

  // Sanitize message content (remove potential HTML/script tags)
  String _sanitizeMessage(String message) {
    return message
        .trim()
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  // Generate chat room ID
  String getChatRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort();
    return users.join('_');
  }

  // Create or get chat room (with encryption key generation)
  Future<String> createChatRoom(String userId1, String userId2) async {
    String chatRoomId = getChatRoomId(userId1, userId2);

    try {
      DocumentSnapshot chatRoom =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();

      if (!chatRoom.exists) {
        // Fetch both users' public keys for encryption
        final user1Doc = await _firestore.collection('users').doc(userId1).get();
        final user2Doc = await _firestore.collection('users').doc(userId2).get();

        final user1PublicKey = user1Doc.data()?['publicKey'] as String?;
        final user2PublicKey = user2Doc.data()?['publicKey'] as String?;

        Map<String, String>? encryptedKeys;

        // Generate symmetric key for this conversation if both users have encryption enabled
        if (user1PublicKey != null && user2PublicKey != null) {
          try {
            final symmetricKey = EncryptionService.generateSymmetricKey();

            // Encrypt symmetric key for each participant
            encryptedKeys = {
              userId1: EncryptionService.encryptSymmetricKey(symmetricKey, user1PublicKey),
              userId2: EncryptionService.encryptSymmetricKey(symmetricKey, user2PublicKey),
            };

            AppLogger.info('Created encrypted chat room: $chatRoomId');
          } catch (e) {
            AppLogger.warning('Failed to setup encryption for chat room, falling back to plaintext: $e');
          }
        } else {
          AppLogger.info('Created unencrypted chat room (users missing keys): $chatRoomId');
        }

        await _firestore.collection('chatRooms').doc(chatRoomId).set({
          'participants': [userId1, userId2],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            userId1: 0,
            userId2: 0,
          },
          if (encryptedKeys != null) 'encryptedSymmetricKeys': encryptedKeys,
        });
      }

      return chatRoomId;
    } catch (e) {
      AppLogger.error('Error creating chat room', e);
      rethrow;
    }
  }

  // Send message (with optional encryption)
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
    String? senderPrivateKey, // Optional: if provided, message will be encrypted
  }) async {
    try {
      // Validate message
      final validationError = _validateMessage(message);
      if (validationError != null) {
        throw ArgumentError(validationError);
      }

      // Sanitize message
      final sanitizedMessage = _sanitizeMessage(message);

      String? encryptedMessage;
      String? iv;
      String displayMessage = sanitizedMessage;

      // Try to encrypt message if sender has private key
      if (senderPrivateKey != null) {
        try {
          // Get chat room to retrieve encrypted symmetric key
          final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
          final encryptedSymmetricKeys = chatRoomDoc.data()?['encryptedSymmetricKeys'] as Map<String, dynamic>?;

          if (encryptedSymmetricKeys != null && encryptedSymmetricKeys.containsKey(senderId)) {
            // Decrypt symmetric key using sender's private key
            final encryptedKey = encryptedSymmetricKeys[senderId] as String;
            final symmetricKey = EncryptionService.decryptSymmetricKey(encryptedKey, senderPrivateKey);

            // Encrypt message
            final encrypted = EncryptionService.encryptMessage(sanitizedMessage, symmetricKey);
            encryptedMessage = encrypted['encryptedMessage'];
            iv = encrypted['iv'];
            displayMessage = '[Encrypted]'; // Placeholder for old clients

            AppLogger.info('Message encrypted successfully');
          }
        } catch (e) {
          AppLogger.warning('Failed to encrypt message, sending plaintext: $e');
          // Continue with plaintext if encryption fails
        }
      }

      ChatMessage chatMessage = ChatMessage(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        message: displayMessage,
        timestamp: DateTime.now(),
        isRead: false, // Explicitly set to false for new messages
        imageUrl: imageUrl,
        encryptedMessage: encryptedMessage,
        iv: iv,
      );

      // Add message to messages subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(chatMessage.toMap());

      // Update chat room with last message (use placeholder if encrypted)
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': encryptedMessage != null ? '[Encrypted Message]' : sanitizedMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });

      // Send push notification to receiver
      try {
        // Get sender's name
        final senderDoc = await _firestore.collection('users').doc(senderId).get();
        final senderName = senderDoc.data()?['name'] ?? 'Someone';

        // Prepare message preview (truncate if too long)
        String messagePreview = sanitizedMessage;
        if (messagePreview.length > 100) {
          messagePreview = '${messagePreview.substring(0, 97)}...';
        }

        // Send notification
        await _notificationService.sendMessageNotification(
          senderId: senderId,
          senderName: senderName,
          receiverId: receiverId,
          chatRoomId: chatRoomId,
          messagePreview: messagePreview,
        );

        AppLogger.info('Notification sent to $receiverId');
      } catch (notifError) {
        // Don't fail message sending if notification fails
        AppLogger.warning('Failed to send notification: $notifError');
      }
    } catch (e) {
      AppLogger.error('Error sending message', e);
      rethrow;
    }
  }

  // Get messages stream (kept for compatibility, but limited)
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20) // Limit to recent 20 messages for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get paginated messages (for loading message history)
  Future<PaginatedMessages> getMessagesPaginated(
    String chatRoomId, {
    DocumentSnapshot? startAfter,
    int limit = 20,
    String? userId,
    String? userPrivateKey,
  }) async {
    try {
      Query query = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit + 1); // Fetch one extra to check if more exist

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final hasMore = docs.length > limit;
      var messages = docs
          .take(limit)
          .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Decrypt messages if user has private key
      if (userId != null && userPrivateKey != null) {
        messages = await _decryptMessages(chatRoomId, messages, userId, userPrivateKey);
      }

      return PaginatedMessages(
        messages: messages,
        lastDocument: messages.isNotEmpty ? docs[messages.length - 1] : null,
        hasMore: hasMore,
      );
    } catch (e) {
      AppLogger.error('Error getting paginated messages', e);
      rethrow;
    }
  }

  // Helper method to decrypt messages
  Future<List<ChatMessage>> _decryptMessages(
    String chatRoomId,
    List<ChatMessage> messages,
    String userId,
    String userPrivateKey,
  ) async {
    try {
      // Get chat room to retrieve encrypted symmetric key
      final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
      final encryptedSymmetricKeys = chatRoomDoc.data()?['encryptedSymmetricKeys'] as Map<String, dynamic>?;

      if (encryptedSymmetricKeys == null || !encryptedSymmetricKeys.containsKey(userId)) {
        // No encryption setup for this chat
        return messages;
      }

      // Decrypt symmetric key
      final encryptedKey = encryptedSymmetricKeys[userId] as String;
      final symmetricKey = EncryptionService.decryptSymmetricKey(encryptedKey, userPrivateKey);

      // Decrypt each message
      for (var message in messages) {
        if (message.isEncrypted) {
          try {
            final decrypted = EncryptionService.decryptMessage(
              encryptedMessage: message.encryptedMessage!,
              ivBase64: message.iv!,
              symmetricKeyBase64: symmetricKey,
            );
            message.setDecryptedMessage(decrypted);
          } catch (e) {
            AppLogger.error('Failed to decrypt message ${message.id}', e);
            message.setDecryptedMessage('[Decryption Failed]');
          }
        }
      }

      return messages;
    } catch (e) {
      AppLogger.error('Error decrypting messages', e);
      return messages; // Return original messages if decryption fails
    }
  }

  // Get recent messages stream (for real-time updates)
  Stream<List<ChatMessage>> getRecentMessages(
    String chatRoomId, {
    int limit = 20,
    String? userId,
    String? userPrivateKey,
  }) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      var messages = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();

      // Decrypt messages if user has private key
      if (userId != null && userPrivateKey != null) {
        messages = await _decryptMessages(chatRoomId, messages, userId, userPrivateKey);
      }

      return messages;
    });
  }

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get total unread message count for a user
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;
        totalUnread += unreadCount as int;
      }
      return totalUnread;
    });
  }

  // Mark messages as read (optimized to avoid unnecessary writes)
  Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      final chatRoom = await _firestore.collection('chatRooms').doc(chatRoomId).get();

      if (!chatRoom.exists) return;

      final data = chatRoom.data() as Map<String, dynamic>;
      final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;

      // Only update if there are unread messages
      if (unreadCount > 0) {
        // Update unread count
        await _firestore.collection('chatRooms').doc(chatRoomId).update({
          'unreadCount.$userId': 0,
        });

        // Mark individual messages as read
        final messagesSnapshot = await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .where('receiverId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        // Use batch write for efficiency
        if (messagesSnapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (var doc in messagesSnapshot.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          await batch.commit();
          AppLogger.info('Marked ${messagesSnapshot.docs.length} messages as read');
        }
      }
    } catch (e) {
      AppLogger.error('Error marking as read', e);
    }
  }

  // Delete chat room
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // Delete all messages
      QuerySnapshot messages = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete chat room
      await _firestore.collection('chatRooms').doc(chatRoomId).delete();
    } catch (e) {
      AppLogger.error('Error deleting chat room', e);
      rethrow;
    }
  }

  // Set typing status
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'typing.$userId': isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      });
    } catch (e) {
      AppLogger.error('Error setting typing status', e);
      // Don't throw - typing indicator is not critical
    }
  }

  // Get typing status stream
  Stream<bool> getTypingStatus({
    required String chatRoomId,
    required String otherUserId,
  }) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;

      final data = snapshot.data();
      if (data == null) return false;

      final typing = data['typing'] as Map<String, dynamic>?;
      if (typing == null || !typing.containsKey(otherUserId)) return false;

      // Check if typing timestamp is recent (within last 5 seconds)
      final typingTimestamp = typing[otherUserId] as Timestamp?;
      if (typingTimestamp == null) return false;

      final now = DateTime.now();
      final typingTime = typingTimestamp.toDate();
      final difference = now.difference(typingTime).inSeconds;

      return difference < 5; // Consider typing if within last 5 seconds
    });
  }
}
