/// ChatService - Core Messaging and Encryption System
///
/// This service handles all chat-related operations including:
/// - Message sending/receiving with optional end-to-end encryption
/// - Chat room creation and management
/// - Message read receipts and status tracking
/// - Real-time message streams with pagination
/// - Typing indicators
/// - Push notification integration
library;
/// ENCRYPTION:
/// The service implements hybrid encryption:
/// - RSA-2048 for secure key exchange
/// - AES-256-GCM for message encryption
/// - Each chat room has a unique symmetric key
/// - Private keys never leave the device
///
/// READ RECEIPTS:
/// - Messages sent with isRead: false
/// - Batch updated when recipient opens chat
/// - Real-time status sync via Firestore
///
/// SECURITY FEATURES:
/// - Input validation (max 5000 chars)
/// - XSS/Script tag sanitization
/// - Graceful fallback to plaintext if encryption fails
/// - All encryption operations logged for debugging
///
/// PERFORMANCE OPTIMIZATIONS:
/// - Message pagination (default 20 per page)
/// - Batch writes for read receipts
/// - Firestore query optimization
/// - Only update unread count when > 0
///
/// FUTURE IMPROVEMENTS:
/// - Message delivery receipts (in addition to read receipts)
/// - Message editing/deletion
/// - Media message support (images, voice)
/// - Message search functionality
///
/// Last updated: 2025-12-22
/// Author: VibeNou Team

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';
import 'encryption_service.dart';
import 'notification_service.dart';

/// ChatService - Main service for all messaging operations
///
/// This service is the single source of truth for all chat functionality.
/// It integrates encryption, notifications, and Firestore operations.
class ChatService {
  // ========== DEPENDENCIES ==========

  /// Firestore instance for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Service for sending push notifications to users
  final NotificationService _notificationService = NotificationService();

  // ========== MESSAGE VALIDATION ==========

  /// Validates message content before sending
  ///
  /// Checks:
  /// - Message is not empty (after trimming)
  /// - Message is not too long (max 5000 characters)
  ///
  /// Returns:
  /// - `null` if message is valid
  /// - Error string if validation fails
  ///
  /// Example:
  /// ```dart
  /// final error = _validateMessage("Hello!");
  /// if (error != null) {
  ///   // Show error to user
  /// }
  /// ```
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

  // ========== MESSAGE SANITIZATION ==========

  /// Sanitizes message content to prevent XSS attacks
  ///
  /// Removes:
  /// - `<script>` tags and their content
  /// - All HTML tags
  ///
  /// This is a defense-in-depth measure. Even though messages are displayed
  /// as plain text in Flutter, we sanitize to prevent any potential issues
  /// if messages are displayed in web views or other contexts.
  ///
  /// Parameters:
  /// - [message]: Raw message text to sanitize
  ///
  /// Returns: Sanitized message safe for storage and display
  ///
  /// Example:
  /// ```dart
  /// final safe = _sanitizeMessage("<script>alert('xss')</script>Hello");
  /// // Returns: "Hello"
  /// ```
  String _sanitizeMessage(String message) {
    return message
        .trim()
        // Remove script tags (case insensitive)
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        // Remove all other HTML tags
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  // ========== CHAT ROOM MANAGEMENT ==========

  /// Generates a deterministic chat room ID from two user IDs
  ///
  /// The ID is the same regardless of which user initiates the chat.
  /// This ensures there's only one chat room between any two users.
  ///
  /// Algorithm:
  /// 1. Put both user IDs in a list
  /// 2. Sort alphabetically
  /// 3. Join with underscore
  ///
  /// Parameters:
  /// - [userId1]: First user's ID
  /// - [userId2]: Second user's ID
  ///
  /// Returns: Deterministic chat room ID (e.g., "abc123_def456")
  ///
  /// Example:
  /// ```dart
  /// getChatRoomId("user1", "user2") == getChatRoomId("user2", "user1")
  /// // true - always returns "user1_user2"
  /// ```
  String getChatRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort(); // Ensures consistent order
    return users.join('_');
  }

  /// Creates a new chat room or gets existing one
  ///
  /// This method handles:
  /// 1. Checking if chat room already exists
  /// 2. Fetching both users' public keys
  /// 3. Generating a symmetric encryption key for this chat
  /// 4. Encrypting the symmetric key for each participant
  /// 5. Creating the chat room document in Firestore
  ///
  /// ENCRYPTION SETUP:
  /// - If both users have public keys: End-to-end encryption enabled
  /// - If either user lacks keys: Falls back to unencrypted chat
  /// - Each chat has a unique AES-256 symmetric key
  /// - Symmetric key is encrypted separately for each user with their RSA public key
  /// - Private keys never leave the device
  ///
  /// Firestore Structure:
  /// ```
  /// chatRooms/{chatRoomId}
  ///   ├─ participants: [userId1, userId2]
  ///   ├─ lastMessage: String
  ///   ├─ lastMessageTime: Timestamp
  ///   ├─ unreadCount: {userId1: 0, userId2: 0}
  ///   └─ encryptedSymmetricKeys: {
  ///        userId1: "encrypted_key_for_user1",
  ///        userId2: "encrypted_key_for_user2"
  ///      }
  /// ```
  ///
  /// Parameters:
  /// - [userId1]: First participant's user ID
  /// - [userId2]: Second participant's user ID
  ///
  /// Returns: Chat room ID (can be used to reference this chat)
  ///
  /// Throws: Firestore exceptions if database operation fails
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

  // ========== READ RECEIPT SYSTEM ==========

  /// Marks all unread messages in a chat as read
  ///
  /// This method implements the read receipt functionality:
  /// 1. Checks if there are any unread messages
  /// 2. Updates the unread count badge to 0
  /// 3. Batch updates all unread messages to isRead: true
  ///
  /// PERFORMANCE OPTIMIZATIONS:
  /// - Only runs if unreadCount > 0 (avoids unnecessary writes)
  /// - Uses Firestore batch writes for atomic updates
  /// - Queries only unread messages (filtered by receiverId and isRead)
  ///
  /// UI IMPACT:
  /// When messages are marked as read:
  /// - Sender sees message bubble change from gray → gradient
  /// - Sender sees checkmark change from ✓ → ✓✓
  /// - Unread badge on chat list decreases
  /// - Changes sync in real-time via Firestore streams
  ///
  /// Firestore Operations:
  /// ```
  /// 1. Update: chatRooms/{id} → unreadCount.{userId} = 0
  /// 2. Batch Update: messages where receiverId == userId AND isRead == false
  ///    → isRead = true
  /// ```
  ///
  /// Parameters:
  /// - [chatRoomId]: ID of the chat room
  /// - [userId]: ID of the user whose messages should be marked as read
  ///
  /// Called when:
  /// - User opens a chat screen
  /// - User is viewing chat and new messages arrive
  ///
  /// NOTE: This method is idempotent - safe to call multiple times
  ///
  /// Example:
  /// ```dart
  /// await chatService.markAsRead(chatRoomId, currentUserId);
  /// // All messages sent to currentUserId in this chat are now marked read
  /// ```
  Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      // Fetch chat room data to check unread count
      final chatRoom = await _firestore.collection('chatRooms').doc(chatRoomId).get();

      if (!chatRoom.exists) return;

      final data = chatRoom.data() as Map<String, dynamic>;
      final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;

      // Only update if there are unread messages (performance optimization)
      if (unreadCount > 0) {
        // Step 1: Update unread count badge to 0
        await _firestore.collection('chatRooms').doc(chatRoomId).update({
          'unreadCount.$userId': 0,
        });

        // Step 2: Mark individual messages as read
        final messagesSnapshot = await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .where('receiverId', isEqualTo: userId) // Only messages TO this user
            .where('isRead', isEqualTo: false) // Only unread messages
            .get();

        // Step 3: Use batch write for atomic, efficient updates
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
      // Don't rethrow - read receipts are not critical for app functionality
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
