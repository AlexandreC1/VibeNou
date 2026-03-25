import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import '../utils/app_logger.dart';
import 'security_monitoring_service.dart';

/// Service to protect sensitive screens from screenshots and screen recording
///
/// Features:
/// - Block screenshots on sensitive screens (iOS/Android)
/// - Detect screenshot attempts and log them
/// - Blur screen content when app goes to background
/// - Warn users when screenshots are detected
///
/// Sensitive screens include:
/// - Chat conversations
/// - Profile details
/// - Payment information
/// - 2FA setup screens
class ScreenshotProtectionService {
  static final ScreenshotProtectionService _instance = ScreenshotProtectionService._internal();
  factory ScreenshotProtectionService() => _instance;
  ScreenshotProtectionService._internal();

  final AppLogger _logger = AppLogger();
  final SecurityMonitoringService _securityMonitoring = SecurityMonitoringService();

  ScreenshotCallback? _screenshotCallback;
  bool _isProtectionEnabled = false;
  final List<VoidCallback> _screenshotListeners = [];

  // Platform channels for native screenshot blocking
  static const MethodChannel _platform = MethodChannel('com.vibenou/screenshot_protection');

  /// Initialize screenshot protection
  Future<void> initialize() async {
    try {
      _logger.info('Initializing screenshot protection');

      // Initialize screenshot detection
      _screenshotCallback = ScreenshotCallback();

      _screenshotCallback!.addListener(() {
        _onScreenshotDetected();
      });

      _isProtectionEnabled = true;
      _logger.info('Screenshot protection initialized');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize screenshot protection', e, stackTrace);
    }
  }

  /// Enable screenshot blocking for current screen
  ///
  /// Call this when entering sensitive screens
  Future<void> enableProtection() async {
    if (!_isProtectionEnabled) {
      await initialize();
    }

    try {
      // Call native method to block screenshots
      await _platform.invokeMethod('enableProtection');
      _logger.debug('Screenshot protection enabled');
    } on PlatformException catch (e) {
      _logger.warning('Failed to enable screenshot protection: ${e.message}');
      // Not all platforms support this, so we don't throw
    }
  }

  /// Disable screenshot blocking
  ///
  /// Call this when leaving sensitive screens
  Future<void> disableProtection() async {
    try {
      await _platform.invokeMethod('disableProtection');
      _logger.debug('Screenshot protection disabled');
    } on PlatformException catch (e) {
      _logger.warning('Failed to disable screenshot protection: ${e.message}');
    }
  }

  /// Handle screenshot detection
  void _onScreenshotDetected() {
    _logger.warning('Screenshot detected on protected screen!');

    // Log security event
    _securityMonitoring.logSecurityEvent(
      eventType: 'screenshot_detected',
      severity: 'medium',
      description: 'Screenshot taken on protected screen',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Notify listeners
    for (final listener in _screenshotListeners) {
      listener();
    }
  }

  /// Add listener for screenshot events
  void addScreenshotListener(VoidCallback callback) {
    _screenshotListeners.add(callback);
  }

  /// Remove screenshot listener
  void removeScreenshotListener(VoidCallback callback) {
    _screenshotListeners.remove(callback);
  }

  /// Show warning dialog when screenshot is detected
  void showScreenshotWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Screenshot Detected'),
          ],
        ),
        content: const Text(
          'Screenshots of sensitive information may pose a security risk. '
          'Please be careful with any screenshots you\'ve taken.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _screenshotCallback?.dispose();
    _screenshotListeners.clear();
  }
}

/// Mixin for screens that need screenshot protection
///
/// Usage:
/// ```dart
/// class ChatScreen extends StatefulWidget {
///   // ...
/// }
///
/// class _ChatScreenState extends State<ChatScreen> with ScreenshotProtectedScreen {
///   @override
///   void initState() {
///     super.initState();
///     enableScreenshotProtection();
///   }
///
///   @override
///   void dispose() {
///     disableScreenshotProtection();
///     super.dispose();
///   }
/// }
/// ```
mixin ScreenshotProtectedScreen<T extends StatefulWidget> on State<T> {
  final ScreenshotProtectionService _protection = ScreenshotProtectionService();
  late VoidCallback _screenshotListener;

  /// Enable screenshot protection (call in initState)
  void enableScreenshotProtection({bool showWarning = true}) {
    _protection.enableProtection();

    if (showWarning) {
      _screenshotListener = () {
        if (mounted) {
          _protection.showScreenshotWarning(context);
        }
      };
      _protection.addScreenshotListener(_screenshotListener);
    }
  }

  /// Disable screenshot protection (call in dispose)
  void disableScreenshotProtection() {
    _protection.disableProtection();
    _protection.removeScreenshotListener(_screenshotListener);
  }
}

/// Widget that blurs its child when app goes to background
///
/// Prevents sensitive information from being visible in app switcher
class BlurOnBackground extends StatefulWidget {
  final Widget child;
  final double blurAmount;

  const BlurOnBackground({
    super.key,
    required this.child,
    this.blurAmount = 10.0,
  });

  @override
  State<BlurOnBackground> createState() => _BlurOnBackgroundState();
}

class _BlurOnBackgroundState extends State<BlurOnBackground> with WidgetsBindingObserver {
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isBackground = state != AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isBackground)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: Icon(
                  Icons.lock,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
