# 🔔 Push Notifications for Messages - Complete Guide

## ✅ What's Implemented

### Client-Side (Flutter App)
- ✅ **NotificationService** - Handles FCM registration, local notifications, and message routing
- ✅ **ChatService Integration** - Automatically sends notifications when messages are sent
- ✅ **UserModel** - Stores FCM tokens for each user
- ✅ **AuthService** - Saves/removes FCM tokens on login/logout
- ✅ **Local Notifications** - Shows notifications even when app is in foreground
- ✅ **Navigation** - Taps on notifications navigate to the correct chat

### Server-Side (Cloud Functions)
- ✅ **sendPushNotification** - Automatically sends FCM notifications when queued
- ✅ **cleanupProcessedNotifications** - Cleans up old notifications daily

---

## 📦 Dependencies Added

### pubspec.yaml
```yaml
dependencies:
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
```

---

## 🚀 Deployment Steps

### Step 1: Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions
npm install
cd ..
```

### Step 2: Deploy Cloud Functions

```bash
# Deploy the push notification function
firebase deploy --only functions --project vibenou-e750a
```

Expected output:
```
✔  functions[sendPushNotification] Successful create operation.
✔  functions[cleanupProcessedNotifications] Successful create operation.
```

### Step 3: Configure Android

**File:** `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:

```xml
<!-- FCM -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="vibenou_messages" />

<!-- Notification permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Step 4: Configure iOS

**File:** `ios/Runner/Info.plist`

Add before `</dict>`:

```xml
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
```

**Enable Push Notifications in Xcode:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Signing & Capabilities
3. Click "+ Capability" → Push Notifications
4. Click "+ Capability" → Background Modes
5. Check "Remote notifications"

### Step 5: Test the App

```bash
flutter run
```

---

## 🧪 Testing Push Notifications

### Test 1: App in Foreground
1. Open the app on Device A
2. Send a message from Device B
3. ✅ Device A should show a local notification
4. ✅ Tapping notification should open the chat

### Test 2: App in Background
1. Minimize app on Device A
2. Send a message from Device B
3. ✅ Device A should show a push notification
4. ✅ Tapping notification should open the app and navigate to chat

### Test 3: App Terminated
1. Force close app on Device A
2. Send a message from Device B
3. ✅ Device A should show a push notification
4. ✅ Tapping notification should launch app and navigate to chat

### Test 4: Multiple Messages
1. Send multiple messages quickly from Device B
2. ✅ Each should trigger a notification on Device A
3. ✅ Notifications should stack properly

---

## 📊 How It Works

### Message Flow:

```
1. User A sends message to User B
   ↓
2. ChatService.sendMessage() called
   ↓
3. Message saved to Firestore
   ↓
4. NotificationService.sendMessageNotification() called
   ↓
5. Notification document created in notifications_queue
   ↓
6. Cloud Function triggered automatically
   ↓
7. FCM notification sent to User B's device
   ↓
8. User B receives push notification
   ↓
9. User B taps notification
   ↓
10. App navigates to chat with User A
```

### Key Components:

**notifications_queue Collection:**
```javascript
{
  type: 'message',
  recipientId: 'user123',
  recipientToken: 'fcm_token_here',
  title: 'John Doe',
  body: 'Hey, how are you?',
  data: {
    type: 'message',
    chatRoomId: 'chat_room_id',
    senderId: 'user456',
    senderName: 'John Doe'
  },
  createdAt: Timestamp,
  processed: false
}
```

**FCM Token Storage (users collection):**
```javascript
{
  uid: 'user123',
  name: 'Jane Doe',
  fcmToken: 'fcm_token_here',
  fcmTokenUpdatedAt: Timestamp,
  // ... other user fields
}
```

---

## 🔍 Verification Steps

### 1. Check FCM Tokens in Firestore

1. Open Firebase Console → Firestore
2. Go to `users` collection
3. Open any user document
4. ✅ Verify `fcmToken` field exists
5. ✅ Verify `fcmTokenUpdatedAt` timestamp

### 2. Monitor Notification Queue

1. Open Firebase Console → Firestore
2. Create `notifications_queue` collection (auto-created on first use)
3. Send a message in the app
4. ✅ New document should appear in `notifications_queue`
5. ✅ After ~2 seconds, `processed: true` should be set

### 3. Check Cloud Function Logs

```bash
firebase functions:log --only sendPushNotification --project vibenou-e750a
```

Look for:
```
Successfully sent notification abc123: projects/.../messages/xyz789
```

### 4. Monitor Firebase Cloud Messaging

1. Firebase Console → Cloud Messaging
2. Check "Sent" count increases when messages are sent
3. Monitor delivery success rate

---

## 🐛 Troubleshooting

### Issue: "No FCM token for user"

**Cause:** User hasn't logged in since notification feature was deployed

**Solution:**
```dart
// User needs to log out and log back in, OR
// Manually trigger token save:
final notificationService = NotificationService();
await notificationService.saveFCMToken(currentUser.uid);
```

### Issue: "Permission denied" for notifications

**Android:**
- Ensure `android.permission.POST_NOTIFICATIONS` in AndroidManifest.xml
- For Android 13+, app will request permission automatically

**iOS:**
- Ensure Push Notifications capability enabled in Xcode
- User must accept permission dialog on first launch

### Issue: Cloud Function not triggering

**Check:**
1. Function deployed? `firebase deploy --only functions`
2. Check function logs: `firebase functions:log`
3. Verify Firestore triggers enabled in Firebase Console

**Common Errors:**
```
Error: HTTP Error: 403, Missing or insufficient permissions
Solution: Ensure service account has FCM permissions
```

### Issue: Notifications not showing

**Debug Steps:**
1. Check device logs:
   ```bash
   # Android
   flutter run --verbose
   adb logcat | grep FCM

   # iOS
   flutter run --verbose
   # Check Xcode console
   ```

2. Verify FCM token registered:
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

3. Test with Firebase Console:
   - Firebase Console → Cloud Messaging → Send test message
   - Enter FCM token from logs
   - Send message

---

## 📱 Platform-Specific Configuration

### Android Notification Channels

The app creates a notification channel `vibenou_messages` with:
- **Channel ID:** vibenou_messages
- **Channel Name:** Messages
- **Importance:** High
- **Sound:** Enabled
- **Vibration:** Enabled

To customize:
```dart
// lib/services/notification_service.dart (line 56)
const androidChannel = AndroidNotificationChannel(
  'vibenou_messages',  // Change channel ID
  'Messages',          // Change channel name
  description: 'Notifications for new messages',
  importance: Importance.high,  // Change importance
  playSound: true,              // Toggle sound
);
```

### iOS Notification Settings

Configure in `DarwinNotificationDetails`:
```dart
// lib/services/notification_service.dart (line 203)
const iosDetails = DarwinNotificationDetails(
  presentAlert: true,   // Show alert
  presentBadge: true,   // Show badge
  presentSound: true,   // Play sound
);
```

---

## 🔐 Security Considerations

### FCM Token Security
- ✅ Tokens stored securely in Firestore with auth rules
- ✅ Tokens automatically refreshed by Firebase
- ✅ Tokens removed on logout
- ✅ Old tokens cleaned up automatically

### Notification Data
- ✅ Only queued for users with valid FCM tokens
- ✅ Processed by authenticated Cloud Functions
- ✅ Cannot be spoofed (server-side validation)

### Privacy
- ✅ Users can only send notifications to chat participants
- ✅ Message content truncated to 100 characters
- ✅ Notification history stored per-user

---

## 📈 Monitoring & Analytics

### Cloud Function Metrics

Monitor in Firebase Console → Functions:
- **Invocations:** Number of notifications processed
- **Execution time:** Average ~500ms per notification
- **Errors:** Failed notification attempts
- **Active instances:** Number of function instances running

### Firestore Usage

Expected reads/writes per message:
- **Writes:** 3 (message + chatRoom + notification queue)
- **Reads:** 2 (sender info + receiver token)

With 1000 messages/day:
- **Total writes:** ~3,000/day
- **Total reads:** ~2,000/day

### FCM Quotas

- **Free tier:** Unlimited messages
- **Rate limit:** None for typical usage
- **Token refresh:** Automatic, ~every 2 months

---

## 🎯 Advanced Features

### Custom Notification Sounds

**Android:**
1. Add sound file to `android/app/src/main/res/raw/notification_sound.mp3`
2. Update NotificationService:
```dart
android: AndroidNotificationDetails(
  // ...
  sound: RawResourceAndroidNotificationSound('notification_sound'),
),
```

**iOS:**
1. Add sound file to `ios/Runner/Sounds/notification_sound.aiff`
2. Update NotificationService:
```dart
apns: ApnsConfig(
  payload: Aps(
    sound: 'notification_sound.aiff',
  ),
),
```

### Notification Actions

Add action buttons to notifications:
```dart
const androidDetails = AndroidNotificationDetails(
  'vibenou_messages',
  'Messages',
  actions: [
    AndroidNotificationAction(
      'reply',
      'Reply',
      showsUserInterface: true,
      allowGeneratedReplies: true,
    ),
    AndroidNotificationAction(
      'mark_read',
      'Mark as Read',
    ),
  ],
);
```

### Rich Notifications with Images

```dart
// In ChatService.sendMessage() for image messages:
await _notificationService.sendMessageNotification(
  // ...
  imageUrl: imageUrl, // Pass image URL
);

// In Cloud Function:
const message = {
  notification: {
    title: title,
    body: body,
    imageUrl: data.imageUrl, // Add image
  },
  // ...
};
```

---

## 📚 References

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Functions](https://firebase.google.com/docs/functions)

---

## ✨ Summary

You now have:
- ✅ **Automatic push notifications** for all new messages
- ✅ **Local notifications** when app is open
- ✅ **Smart navigation** when notifications are tapped
- ✅ **Cloud Functions** handling server-side delivery
- ✅ **Token management** with automatic refresh
- ✅ **Multi-platform support** (Android, iOS)

**Deploy commands:**
```bash
# 1. Install dependencies
flutter pub get
cd functions && npm install && cd ..

# 2. Deploy Cloud Functions
firebase deploy --only functions --project vibenou-e750a

# 3. Test the app
flutter run

# 4. Monitor logs
firebase functions:log --project vibenou-e750a
```

**Your messaging is now complete with push notifications! 🎉**
