import 'package:flutter/material.dart';
import 'dart:async';
import '../services/online_presence_service.dart';
import '../utils/app_theme.dart';

/// Online Counter Widget
///
/// Displays animated count of users currently online.
/// Creates social proof and FOMO (Fear Of Missing Out).
///
/// Psychology:
/// - Social proof: "If others are here, I should be too"
/// - Urgency: "People are active RIGHT NOW"
/// - FOMO: "I might miss connections if I leave"
class OnlineCounterWidget extends StatefulWidget {
  const OnlineCounterWidget({super.key});

  @override
  State<OnlineCounterWidget> createState() => _OnlineCounterWidgetState();
}

class _OnlineCounterWidgetState extends State<OnlineCounterWidget>
    with SingleTickerProviderStateMixin {
  final OnlinePresenceService _presenceService = OnlinePresenceService();
  int _onlineCount = 0;
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Set up pulse animation for the indicator dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Load initial count
    _loadOnlineCount();

    // Refresh count every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOnlineCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadOnlineCount() async {
    final count = await _presenceService.getOnlineCount();
    if (mounted) {
      setState(() => _onlineCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if count is 0 (prevents awkward "0 people online" message)
    if (_onlineCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing green dot indicator
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50), // Green
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4CAF50),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Count text with nice formatting
          Text(
            _formatOnlineCount(_onlineCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Format online count for display
  /// Examples:
  /// - 5 → "5 online now"
  /// - 47 → "47 online now"
  /// - 523 → "523 people online"
  /// - 1247 → "1.2K online now"
  String _formatOnlineCount(int count) {
    if (count == 0) return '';

    final String countText;
    if (count >= 1000) {
      final double thousands = count / 1000;
      countText = '${thousands.toStringAsFixed(1)}K';
    } else {
      countText = count.toString();
    }

    // Use "people" for larger numbers, more personal for smaller
    final String suffix = count > 50 ? 'people online' : 'online now';

    return '$countText $suffix';
  }
}

/// Compact version for navigation bar or smaller spaces
class CompactOnlineCounter extends StatefulWidget {
  const CompactOnlineCounter({super.key});

  @override
  State<CompactOnlineCounter> createState() => _CompactOnlineCounterState();
}

class _CompactOnlineCounterState extends State<CompactOnlineCounter> {
  final OnlinePresenceService _presenceService = OnlinePresenceService();
  int _onlineCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOnlineCount();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOnlineCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnlineCount() async {
    final count = await _presenceService.getOnlineCount();
    if (mounted) {
      setState(() => _onlineCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onlineCount == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _onlineCount >= 1000
              ? '${(_onlineCount / 1000).toStringAsFixed(1)}K'
              : '$_onlineCount',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
