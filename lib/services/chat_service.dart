import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import 'supabase_service.dart';

/// Chat service for managing real-time messaging
/// Handles chat rooms, messages, and real-time subscriptions using Supabase Realtime
class ChatService {
  final SupabaseClient _supabase = SupabaseService.instance.client;
  final Map<String, RealtimeChannel> _subscriptions = {};

  /// Get or create a chat room between two users
  /// Uses the get_or_create_chat_room database function
  Future<String> getOrCreateChatRoom(String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('💬 Getting or creating chat room with user: $otherUserId');
      }

      final response = await _supabase.rpc(
        'get_or_create_chat_room',
        params: {'other_user_id': otherUserId},
      );

      final chatRoomId = response as String;

      if (kDebugMode) {
        print('✅ Chat room ID: $chatRoomId');
      }

      return chatRoomId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting or creating chat room: $e');
      }
      rethrow;
    }
  }

  /// Get chat room by ID
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select()
          .eq('id', chatRoomId)
          .maybeSingle();

      if (response == null) return null;

      return ChatRoom.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching chat room: $e');
      }
      return null;
    }
  }

  /// Get all chat rooms for current user
  Future<List<ChatRoom>> getUserChatRooms() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      if (kDebugMode) {
        print('💬 Fetching chat rooms for user: $currentUserId');
      }

      final response = await _supabase
          .from('chat_rooms')
          .select()
          .or('participant_1.eq.$currentUserId,participant_2.eq.$currentUserId')
          .order('updated_at', ascending: false);

      final chatRooms = (response as List)
          .map((json) => ChatRoom.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Found ${chatRooms.length} chat rooms');
      }

      return chatRooms;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching chat rooms: $e');
      }
      return [];
    }
  }

  /// Send a message in a chat room
  Future<Message?> sendMessage({
    required String chatRoomId,
    required String content,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('💬 Sending message to chat room: $chatRoomId');
      }

      final response = await _supabase.from('messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': currentUserId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final message = Message.fromJson(response);

      if (kDebugMode) {
        print('✅ Message sent successfully');
      }

      return message;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      return null;
    }
  }

  /// Get messages for a chat room (paginated)
  Future<List<Message>> getMessages({
    required String chatRoomId,
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      if (kDebugMode) {
        print('💬 Fetching messages for chat room: $chatRoomId (page $page)');
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: false)
          .range(from, to);

      final messages = (response as List)
          .map((json) => Message.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Fetched ${messages.length} messages');
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching messages: $e');
      }
      return [];
    }
  }

  /// Subscribe to real-time message updates for a chat room
  /// Returns a stream of new messages
  Stream<Message> subscribeToMessages(String chatRoomId) {
    final streamController = StreamController<Message>.broadcast();

    try {
      if (kDebugMode) {
        print('💬 Subscribing to real-time messages for: $chatRoomId');
      }

      // Create a unique channel name
      final channelName = 'messages_$chatRoomId';

      // Remove existing subscription if any
      unsubscribeFromMessages(chatRoomId);

      // Create new realtime channel
      final channel = _supabase.channel(channelName);

      // Listen to INSERT events on messages table
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chat_room_id',
              value: chatRoomId,
            ),
            callback: (payload) {
              try {
                final message = Message.fromJson(payload.newRecord);
                streamController.add(message);

                if (kDebugMode) {
                  print('📨 New message received: ${message.id}');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Error parsing message: $e');
                }
              }
            },
          )
          .subscribe();

      // Store subscription
      _subscriptions[chatRoomId] = channel;

      if (kDebugMode) {
        print('✅ Subscribed to chat room messages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to messages: $e');
      }
    }

    return streamController.stream;
  }

  /// Unsubscribe from real-time message updates
  Future<void> unsubscribeFromMessages(String chatRoomId) async {
    try {
      final channel = _subscriptions[chatRoomId];
      if (channel != null) {
        await _supabase.removeChannel(channel);
        _subscriptions.remove(chatRoomId);

        if (kDebugMode) {
          print('✅ Unsubscribed from chat room: $chatRoomId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from messages: $e');
      }
    }
  }

  /// Mark messages as read in a chat room
  /// Uses the mark_messages_as_read database function
  Future<int> markMessagesAsRead(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('📖 Marking messages as read in: $chatRoomId');
      }

      final response = await _supabase.rpc(
        'mark_messages_as_read',
        params: {'room_id': chatRoomId},
      );

      final count = response as int;

      if (kDebugMode) {
        print('✅ Marked $count messages as read');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking messages as read: $e');
      }
      return 0;
    }
  }

  /// Get unread message count for a chat room
  /// Uses the get_unread_count database function
  Future<int> getUnreadCount(String chatRoomId) async {
    try {
      final response = await _supabase.rpc(
        'get_unread_count',
        params: {'room_id': chatRoomId},
      );

      return response as int;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Delete a specific message (only if you're the sender)
  Future<bool> deleteMessage(String messageId) async {
    try {
      if (kDebugMode) {
        print('🗑️  Deleting message: $messageId');
      }

      await _supabase.from('messages').delete().eq('id', messageId);

      if (kDebugMode) {
        print('✅ Message deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting message: $e');
      }
      return false;
    }
  }

  /// Delete a chat room and all its messages
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('🗑️  Deleting chat room: $chatRoomId');
      }

      // Unsubscribe first
      await unsubscribeFromMessages(chatRoomId);

      // Delete chat room (cascade will delete messages)
      await _supabase.from('chat_rooms').delete().eq('id', chatRoomId);

      if (kDebugMode) {
        print('✅ Chat room deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting chat room: $e');
      }
      return false;
    }
  }

  /// Search messages in a chat room
  Future<List<Message>> searchMessages({
    required String chatRoomId,
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      if (kDebugMode) {
        print('🔍 Searching messages in $chatRoomId for: $query');
      }

      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(50);

      final messages = (response as List)
          .map((json) => Message.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('✅ Found ${messages.length} messages');
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching messages: $e');
      }
      return [];
    }
  }

  /// Clean up all subscriptions
  Future<void> dispose() async {
    if (kDebugMode) {
      print('🧹 Cleaning up chat service subscriptions');
    }

    for (final chatRoomId in _subscriptions.keys.toList()) {
      await unsubscribeFromMessages(chatRoomId);
    }

    _subscriptions.clear();
  }
}
