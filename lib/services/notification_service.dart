import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';

/// Service for handling push notifications and in-app notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Navigation callback for when notification is tapped
  Function(String route, Map<String, dynamic> arguments)? onNotificationTap;

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info('User granted notification permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'vibenou_messages',
        'Messages',
        description: 'Notifications for new messages',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Get and log FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (opened app from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message (app opened from terminated state)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      AppLogger.info('NotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing notifications', e);
    }
  }

  /// Save FCM token to Firestore
  Future<void> saveFCMToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.info('FCM token saved for user $userId');
      }
    } catch (e) {
      AppLogger.error('Error saving FCM token', e);
    }
  }

  /// Remove FCM token (on logout)
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      AppLogger.info('FCM token removed for user $userId');
    } catch (e) {
      AppLogger.error('Error removing FCM token', e);
    }
  }

  /// Handle foreground message (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: message.data['chatRoomId'] ?? '',
        data: message.data,
      );
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('App opened from notification: ${message.notification?.title}');

    final data = message.data;
    _navigateFromNotification(data);
  }

  /// Handle notification tap (local notifications)
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      // Payload is chatRoomId
      if (onNotificationTap != null) {
        onNotificationTap!('/chat', {'chatRoomId': response.payload});
      }
    }
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'message':
        final chatRoomId = data['chatRoomId'] as String?;
        if (chatRoomId != null && onNotificationTap != null) {
          onNotificationTap!('/chat', {'chatRoomId': chatRoomId});
        }
        break;
      case 'profile_view':
        if (onNotificationTap != null) {
          onNotificationTap!('/who_viewed_me', {});
        }
        break;
      case 'match':
        final userId = data['userId'] as String?;
        if (userId != null && onNotificationTap != null) {
          onNotificationTap!('/user_profile', {'userId': userId});
        }
        break;
      default:
        AppLogger.warning('Unknown notification type: $type');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vibenou_messages',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Send message notification to recipient
  /// This creates a notification document that Cloud Functions will use to send FCM
  Future<void> sendMessageNotification({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String chatRoomId,
    required String messagePreview,
  }) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();

      if (!receiverDoc.exists) {
        AppLogger.warning('Receiver not found: $receiverId');
        return;
      }

      final fcmToken = receiverDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        AppLogger.info('No FCM token for receiver: $receiverId');
        return;
      }

      // Create notification document for Cloud Function to process
      await _firestore.collection('notifications_queue').add({
        'type': 'message',
        'recipientId': receiverId,
        'recipientToken': fcmToken,
        'title': senderName,
        'body': messagePreview,
        'data': {
          'type': 'message',
          'chatRoomId': chatRoomId,
          'senderId': senderId,
          'senderName': senderName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      // Also save to user's notification history
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'type': 'message',
        'title': senderName,
        'body': messagePreview,
        'data': {
          'chatRoomId': chatRoomId,
          'senderId': senderId,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Message notification queued for $receiverId');
    } catch (e) {
      AppLogger.error('Error sending message notification', e);
    }
  }

  /// Get user's notifications
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'general',
          'title': data['title'] ?? '',
          'body': data['body'] ?? '',
          'data': data['data'] ?? {},
          'read': data['read'] ?? false,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      AppLogger.error('Error marking notification as read', e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('Error getting unread count', e);
      return 0;
    }
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      AppLogger.info('Cleared all notifications for user $userId');
    } catch (e) {
      AppLogger.error('Error clearing notifications', e);
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Background message: ${message.notification?.title}');
}
