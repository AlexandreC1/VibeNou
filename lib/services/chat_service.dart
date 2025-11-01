import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate chat room ID
  String getChatRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort();
    return users.join('_');
  }

  // Create or get chat room
  Future<String> createChatRoom(String userId1, String userId2) async {
    String chatRoomId = getChatRoomId(userId1, userId2);

    try {
      DocumentSnapshot chatRoom =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();

      if (!chatRoom.exists) {
        await _firestore.collection('chatRooms').doc(chatRoomId).set({
          'participants': [userId1, userId2],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            userId1: 0,
            userId2: 0,
          },
        });
      }

      return chatRoomId;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    try {
      ChatMessage chatMessage = ChatMessage(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );

      // Add message to messages subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(chatMessage.toMap());

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
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

  // Mark messages as read
  Future<void> markAsRead(String chatRoomId, String userId) async {
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      print('Error marking as read: $e');
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
      print('Error deleting chat room: $e');
      rethrow;
    }
  }
}
