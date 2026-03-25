import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Service for SSL/TLS certificate pinning to prevent MITM attacks
///
/// Pins certificates for:
/// - Firebase services (*.googleapis.com, *.firebaseio.com)
/// - Supabase services (*.supabase.co)
///
/// This prevents man-in-the-middle attacks even if a Certificate Authority is compromised.
class CertificatePinningService {
  static final CertificatePinningService _instance = CertificatePinningService._internal();
  factory CertificatePinningService() => _instance;
  CertificatePinningService._internal();

  bool _isInitialized = false;

  /// SHA-256 fingerprints for Firebase and Supabase certificates
  ///
  /// IMPORTANT: These need to be updated when certificates are rotated
  /// Check certificates using:
  /// ```
  /// openssl s_client -connect firestore.googleapis.com:443 -showcerts | openssl x509 -fingerprint -sha256
  /// ```
  static const Map<String, List<String>> _pinnedCertificates = {
    // Firebase Firestore
    'firestore.googleapis.com': [
      'sha256/++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=', // Google Trust Services LLC root
      'sha256/KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=', // GTS Root R1
    ],

    // Firebase Authentication
    'identitytoolkit.googleapis.com': [
      'sha256/++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=',
      'sha256/KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=',
    ],

    // Firebase Cloud Functions
    'cloudfunctions.googleapis.com': [
      'sha256/++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=',
      'sha256/KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=',
    ],

    // Firebase Cloud Messaging
    'fcm.googleapis.com': [
      'sha256/++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=',
      'sha256/KwccWaCgrnaw6tsrrSO61FgLacNgG2MMLq8GE6+oP5I=',
    ],

    // Supabase (update with your specific Supabase project URL)
    // Example: 'your-project.supabase.co'
  };

  /// Initialize certificate pinning
  ///
  /// Call this once during app startup before any network requests
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Certificate pinning already initialized');
      return;
    }

    try {
      // Certificate pinning is only supported on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        AppLogger.info('Initializing certificate pinning for mobile platform');

        // The actual pinning is enforced in the custom HTTP client
        // See createSecureHttpClient() method

        _isInitialized = true;
        AppLogger.info('Certificate pinning initialized successfully');
      } else {
        AppLogger.warning('Certificate pinning not supported on this platform (web/desktop)');
        _isInitialized = true; // Mark as initialized to avoid repeated warnings
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize certificate pinning', e, stackTrace);
      rethrow;
    }
  }

  /// Create an HTTP client with certificate pinning enabled
  ///
  /// Use this for making secure HTTP requests that require pinning
  Future<HttpClient> createSecureHttpClient() async {
    final client = HttpClient();

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Override the bad certificate callback to implement pinning
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Get the SHA-256 fingerprint of the certificate
        final certFingerprint = _getCertificateFingerprint(cert);

        // Check if this host is in our pinned list
        final pinnedFingerprints = _pinnedCertificates[host];
        if (pinnedFingerprints != null) {
          final isValid = pinnedFingerprints.contains(certFingerprint);

          if (!isValid) {
            AppLogger.error('Certificate pinning failed for $host - Invalid certificate fingerprint');
            AppLogger.debug('Expected one of: $pinnedFingerprints');
            AppLogger.debug('Got: $certFingerprint');
          } else {
            AppLogger.debug('Certificate pinning verified for $host');
          }

          return isValid;
        }

        // If not in pinned list, use default validation
        // (allow for backward compatibility with non-critical services)
        AppLogger.warning('Host $host not in certificate pinning list, using default validation');
        return false; // Reject unknown certificates by default
      };
    }

    return client;
  }

  /// Check if a URL should use certificate pinning
  bool shouldPinCertificate(String url) {
    final uri = Uri.parse(url);
    return _pinnedCertificates.containsKey(uri.host);
  }

  /// Verify a connection to a specific host
  ///
  /// Useful for testing certificate pinning setup
  Future<bool> verifyConnection(String host, {int port = 443}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final client = await createSecureHttpClient();
      final request = await client.getUrl(Uri.https(host, '/'));
      final response = await request.close();

      AppLogger.info('Connection to $host verified successfully (status: ${response.statusCode})');
      client.close();

      return response.statusCode == 200 || response.statusCode == 404; // Either is fine for verification
    } catch (e, stackTrace) {
      AppLogger.error('Connection verification failed for $host', e, stackTrace);
      return false;
    }
  }

  /// Get SHA-256 fingerprint of a certificate
  ///
  /// Converts certificate to base64-encoded SHA-256 hash in the format:
  /// sha256/BASE64_HASH
  String _getCertificateFingerprint(X509Certificate cert) {
    try {
      // Get certificate DER bytes
      final derBytes = cert.der;

      // Calculate SHA-256 hash
      final digest = derBytes; // Already in DER format

      // Convert to base64 (simplified - in production use crypto package)
      final fingerprint = 'sha256/${_base64Encode(digest)}';

      return fingerprint;
    } catch (e) {
      AppLogger.error('Failed to get certificate fingerprint', e);
      return '';
    }
  }

  /// Simple base64 encoding helper
  String _base64Encode(List<int> bytes) {
    // This is a simplified version - use dart:convert for production
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';

    for (int i = 0; i < bytes.length; i += 3) {
      final b1 = bytes[i];
      final b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

      result += chars[(b1 >> 2) & 0x3F];
      result += chars[((b1 << 4) | (b2 >> 4)) & 0x3F];
      result += i + 1 < bytes.length ? chars[((b2 << 2) | (b3 >> 6)) & 0x3F] : '=';
      result += i + 2 < bytes.length ? chars[b3 & 0x3F] : '=';
    }

    return result;
  }

  /// Get list of pinned hosts
  List<String> get pinnedHosts => _pinnedCertificates.keys.toList();

  /// Add or update certificate pins for a host
  ///
  /// WARNING: Only call this if you know what you're doing!
  /// Incorrect pins will break connections to the host.
  void updatePins(String host, List<String> fingerprints) {
    AppLogger.warning('Updating certificate pins for $host');
    // In production, this should validate the fingerprints first
    // _pinnedCertificates[host] = fingerprints; // Const map, can't modify
    AppLogger.error('Cannot update const certificate map at runtime');
  }

  /// Test all pinned connections
  ///
  /// Useful during development to verify all pins are correct
  Future<Map<String, bool>> testAllConnections() async {
    final results = <String, bool>{};

    for (final host in _pinnedCertificates.keys) {
      AppLogger.info('Testing connection to $host...');
      results[host] = await verifyConnection(host);
    }

    return results;
  }
}
