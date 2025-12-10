import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
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

      AppLogger.log(
        'User granted notification permission: ${settings.authorizationStatus}',
        tag: 'NotificationService',
      );

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        AppLogger.log('FCM Token: $token', tag: 'NotificationService');
        return;
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
    } catch (e) {
      AppLogger.error('Error initializing notifications', error: e, tag: 'NotificationService');
    }
  }

  // Save FCM token to Firestore
  Future<void> saveFCMToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.success('FCM token saved', tag: 'NotificationService');
      }
    } catch (e) {
      AppLogger.error('Error saving FCM token', error: e, tag: 'NotificationService');
    }
  }

  // Remove FCM token (on logout)
  Future<void> removeFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      AppLogger.log('FCM token removed', tag: 'NotificationService');
    } catch (e) {
      AppLogger.error('Error removing FCM token', error: e, tag: 'NotificationService');
    }
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.log(
      'Foreground message: ${message.notification?.title}',
      tag: 'NotificationService',
    );

    if (message.notification != null) {
      // Show local notification or update UI
      // You can use flutter_local_notifications for custom notification display
    }
  }

  // Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.log(
      'App opened from notification: ${message.notification?.title}',
      tag: 'NotificationService',
    );

    // Navigate to specific screen based on notification data
    final data = message.data;
    if (data['type'] == 'message') {
      // Navigate to chat screen
    } else if (data['type'] == 'profile_view') {
      // Navigate to who viewed me screen
    } else if (data['type'] == 'match') {
      // Navigate to match screen
    }
  }

  // Send notification to a user (call this from Cloud Functions)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        AppLogger.warning('User not found: $userId', tag: 'NotificationService');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        AppLogger.warning('No FCM token for user: $userId', tag: 'NotificationService');
        return;
      }

      // Note: Sending notifications directly from the app is not recommended
      // You should use Firebase Cloud Functions to send notifications
      AppLogger.log(
        'Would send notification to token: $fcmToken',
        tag: 'NotificationService',
      );

      // Store notification in Firestore for history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error sending notification', error: e, tag: 'NotificationService');
    }
  }

  // Get user's notifications
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
          'title': data['title'],
          'body': data['body'],
          'data': data['data'],
          'read': data['read'] ?? false,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      AppLogger.error('Error marking notification as read', error: e, tag: 'NotificationService');
    }
  }

  // Get unread notification count
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
      AppLogger.error('Error getting unread count', error: e, tag: 'NotificationService');
      return 0;
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.log(
    'Background message: ${message.notification?.title}',
    tag: 'NotificationService',
  );
}
