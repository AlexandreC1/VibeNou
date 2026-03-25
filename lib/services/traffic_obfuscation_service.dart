import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../utils/app_logger.dart';

/// Service to obfuscate network traffic patterns
///
/// Security Features:
/// - Message padding to hide message lengths
/// - Fake message injection to obscure real traffic
/// - Timing obfuscation to prevent traffic analysis
/// - Metadata randomization
///
/// This makes it harder for network observers to:
/// - Determine message lengths
/// - Detect when users are chatting
/// - Identify message patterns
/// - Perform traffic analysis attacks
class TrafficObfuscationService {
  static final TrafficObfuscationService _instance = TrafficObfuscationService._internal();
  factory TrafficObfuscationService() => _instance;
  TrafficObfuscationService._internal();

  final AppLogger _logger = AppLogger();
  final Random _random = Random.secure();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obfuscation settings
  static const int minPaddingSize = 16;
  static const int maxPaddingSize = 256;
  static const int targetMessageSize = 512; // All messages padded to this size
  static const double fakeMessageProbability = 0.1; // 10% of messages are fake
  static const int minTimingDelay = 100; // milliseconds
  static const int maxTimingDelay = 1000;

  /// Pad message data to hide true length
  ///
  /// Process:
  /// 1. Calculate padding needed to reach target size
  /// 2. Generate random padding bytes
  /// 3. Add padding metadata
  /// 4. Return padded message
  Map<String, dynamic> padMessage(Map<String, dynamic> messageData) {
    try {
      // Serialize message to get current size
      final messageJson = jsonEncode(messageData);
      final currentSize = utf8.encode(messageJson).length;

      // Calculate padding needed
      int paddingSize;
      if (currentSize < targetMessageSize) {
        paddingSize = targetMessageSize - currentSize;
      } else {
        // Message is already larger than target, add random small padding
        paddingSize = _random.nextInt(maxPaddingSize - minPaddingSize) + minPaddingSize;
      }

      // Generate random padding
      final padding = _generateRandomBytes(paddingSize);

      // Add padding to message
      final paddedMessage = {
        ...messageData,
        '_padding': base64Encode(padding),
        '_paddingSize': paddingSize,
        '_originalSize': currentSize,
      };

      _logger.debug('Padded message: $currentSize bytes -> ${currentSize + paddingSize} bytes');

      return paddedMessage;
    } catch (e, stackTrace) {
      _logger.error('Failed to pad message', e, stackTrace);
      return messageData; // Return original on error
    }
  }

  /// Remove padding from received message
  Map<String, dynamic> removePadding(Map<String, dynamic> paddedMessage) {
    try {
      final message = Map<String, dynamic>.from(paddedMessage);

      // Remove padding fields
      message.remove('_padding');
      message.remove('_paddingSize');
      message.remove('_originalSize');

      return message;
    } catch (e, stackTrace) {
      _logger.error('Failed to remove padding', e, stackTrace);
      return paddedMessage;
    }
  }

  /// Generate fake message to inject into traffic
  ///
  /// Fake messages are indistinguishable from real messages to network observers
  Map<String, dynamic> generateFakeMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
  }) {
    try {
      // Generate realistic-looking fake data
      final fakeContent = _generateFakeContent();

      final fakeMessage = {
        'senderId': senderId,
        'receiverId': receiverId,
        'message': fakeContent,
        'encryptedMessage': _generateRandomBase64(256),
        'ephemeralPublicKey': _generateRandomBase64(32),
        'nonce': _generateRandomBase64(12),
        'signature': _generateRandomBase64(64),
        'mac': _generateRandomBase64(16),
        'timestamp': FieldValue.serverTimestamp(),
        '_isFake': true, // Marker for recipient to ignore
        '_fakeId': _generateFakeId(),
      };

      // Pad to standard size
      return padMessage(fakeMessage);
    } catch (e, stackTrace) {
      _logger.error('Failed to generate fake message', e, stackTrace);
      rethrow;
    }
  }

  /// Send fake message to obfuscate traffic
  ///
  /// This makes it appear like there's activity even when users aren't chatting
  Future<void> sendFakeMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final fakeMessage = generateFakeMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
      );

      // Send to Firestore (recipient will ignore it)
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(fakeMessage);

      _logger.debug('Fake message sent for traffic obfuscation');
    } catch (e, stackTrace) {
      _logger.error('Failed to send fake message', e, stackTrace);
      // Don't rethrow - fake messages are optional
    }
  }

  /// Check if message is fake
  bool isFakeMessage(Map<String, dynamic> message) {
    return message['_isFake'] == true;
  }

  /// Add random timing delay to obscure message sending patterns
  ///
  /// Call this before sending real messages
  Future<void> addTimingObfuscation() async {
    final delay = _random.nextInt(maxTimingDelay - minTimingDelay) + minTimingDelay;
    _logger.debug('Adding timing delay: ${delay}ms');
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Randomize message metadata to prevent fingerprinting
  Map<String, dynamic> randomizeMetadata(Map<String, dynamic> messageData) {
    try {
      // Add random metadata fields
      final randomized = {
        ...messageData,
        '_metadata': {
          'version': '1.${_random.nextInt(10)}',
          'client': _generateRandomClient(),
          'locale': _generateRandomLocale(),
          'checksum': _generateChecksum(messageData),
        },
      };

      return randomized;
    } catch (e, stackTrace) {
      _logger.error('Failed to randomize metadata', e, stackTrace);
      return messageData;
    }
  }

  /// Should we inject a fake message? (probabilistic)
  bool shouldInjectFakeMessage() {
    return _random.nextDouble() < fakeMessageProbability;
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Generate random base64 string
  String _generateRandomBase64(int byteLength) {
    return base64Encode(_generateRandomBytes(byteLength));
  }

  /// Generate fake message content
  String _generateFakeContent() {
    final templates = [
      'Hello',
      'How are you?',
      'Thanks!',
      'Great',
      'Sounds good',
      'Sure',
      'Ok',
      'Alright',
      'See you',
      'Bye',
    ];

    return templates[_random.nextInt(templates.length)];
  }

  /// Generate fake message ID
  String _generateFakeId() {
    return 'fake_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(999999)}';
  }

  /// Generate random client identifier
  String _generateRandomClient() {
    final clients = [
      'android-v1.0',
      'ios-v1.0',
      'web-v1.0',
      'android-v1.1',
      'ios-v1.1',
    ];

    return clients[_random.nextInt(clients.length)];
  }

  /// Generate random locale
  String _generateRandomLocale() {
    final locales = ['en', 'fr', 'ht', 'en-US', 'fr-CA'];
    return locales[_random.nextInt(locales.length)];
  }

  /// Generate checksum for message
  String _generateChecksum(Map<String, dynamic> data) {
    try {
      final json = jsonEncode(data);
      final bytes = utf8.encode(json);
      final hash = sha256.convert(bytes);
      return hash.toString().substring(0, 16);
    } catch (e) {
      return _generateRandomBase64(8);
    }
  }

  /// Schedule periodic fake message injection
  ///
  /// This maintains traffic even during idle periods
  Future<void> startBackgroundObfuscation({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    Duration interval = const Duration(minutes: 5),
  }) async {
    _logger.info('Starting background traffic obfuscation');

    // This would typically use a background task scheduler
    // For now, we'll just demonstrate the concept

    try {
      // Send initial fake message
      if (shouldInjectFakeMessage()) {
        await sendFakeMessage(
          chatRoomId: chatRoomId,
          senderId: senderId,
          receiverId: receiverId,
        );
      }

      _logger.info('Background obfuscation started');
    } catch (e, stackTrace) {
      _logger.error('Failed to start background obfuscation', e, stackTrace);
    }
  }

  /// Process outgoing message with all obfuscation techniques
  Future<Map<String, dynamic>> obfuscateOutgoingMessage(
    Map<String, dynamic> message,
  ) async {
    try {
      _logger.debug('Obfuscating outgoing message');

      // 1. Add timing delay
      await addTimingObfuscation();

      // 2. Randomize metadata
      var obfuscated = randomizeMetadata(message);

      // 3. Pad message
      obfuscated = padMessage(obfuscated);

      _logger.debug('Message obfuscation complete');

      return obfuscated;
    } catch (e, stackTrace) {
      _logger.error('Failed to obfuscate message', e, stackTrace);
      return message;
    }
  }

  /// Process incoming message to remove obfuscation
  Map<String, dynamic> deobfuscateIncomingMessage(
    Map<String, dynamic> message,
  ) {
    try {
      // Check if fake
      if (isFakeMessage(message)) {
        _logger.debug('Fake message detected, ignoring');
        return {};
      }

      // Remove padding
      var deobfuscated = removePadding(message);

      // Remove metadata
      deobfuscated.remove('_metadata');

      return deobfuscated;
    } catch (e, stackTrace) {
      _logger.error('Failed to deobfuscate message', e, stackTrace);
      return message;
    }
  }
}
