/// VibeNou Logo - Professional, Playful, and Sexy
///
/// Features:
/// - Two silhouettes "meeting" in the middle forming a heart
/// - Sparkle/connection animations
/// - Pink/Purple romantic gradients
/// - Wink/flirt animation on the 'N'
/// - Modern, professional design
///
/// Last updated: 2026-03-24
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;

class VibeNouLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showWordmark;

  const VibeNouLogo({
    super.key,
    this.size = 120,
    this.animate = true,
    this.showWordmark = false,
  });

  @override
  State<VibeNouLogo> createState() => _VibeNouLogoState();
}

class _VibeNouLogoState extends State<VibeNouLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _winkController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _winkAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the heart
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Wink animation (for the 'N')
    _winkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _winkAnimation = CurvedAnimation(
      parent: _winkController,
      curve: Curves.easeInOutBack,
    );

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();

      // Wink occasionally (every 3 seconds)
      _scheduleWink();
    }
  }

  void _scheduleWink() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.animate) {
        _winkController.forward().then((_) {
          _winkController.reverse();
          _scheduleWink();
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkleController.dispose();
    _winkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon
        AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _sparkleController,
            _winkController,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.animate ? _pulseAnimation.value : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: widget.size * 1.3,
                    height: widget.size * 1.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFF4081).withValues(alpha: 0.3),
                          const Color(0xFF9C27B0).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Main logo
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CustomPaint(
                      painter: _MeetNLogoPainter(
                        sparkleProgress: _sparkleAnimation.value,
                        winkProgress: _winkAnimation.value,
                      ),
                    ),
                  ),

                  // Sparkles
                  if (widget.animate)
                    ..._buildSparkles(),
                ],
              ),
            );
          },
        ),

        // Wordmark
        if (widget.showWordmark) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFF4081),
                Color(0xFF9C27B0),
                Color(0xFF42A5F5),
              ],
            ).createShader(bounds),
            child: const Text(
              'VibeNou',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Meet N Connect',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSparkles() {
    final sparkles = <Widget>[];
    final positions = [
      const Offset(-0.3, -0.3),
      const Offset(0.3, -0.3),
      const Offset(-0.4, 0.0),
      const Offset(0.4, 0.0),
      const Offset(0.0, 0.4),
    ];

    for (int i = 0; i < positions.length; i++) {
      final delay = i * 0.2;
      final sparkleValue = (_sparkleAnimation.value - delay).clamp(0.0, 1.0);
      final opacity = (math.sin(sparkleValue * math.pi) * 0.8).clamp(0.0, 1.0);

      sparkles.add(
        Positioned(
          left: widget.size * 0.5 + positions[i].dx * widget.size,
          top: widget.size * 0.5 + positions[i].dy * widget.size,
          child: Transform.scale(
            scale: sparkleValue,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: opacity),
              size: 16,
            ),
          ),
        ),
      );
    }

    return sparkles;
  }
}

/// Custom painter for the "Meet N" logo
class _MeetNLogoPainter extends CustomPainter {
  final double sparkleProgress;
  final double winkProgress;

  // Sexy pink/purple gradient colors
  static const Color primaryPink = Color(0xFFFF4081);
  static const Color deepPink = Color(0xFFEC407A);
  static const Color royalPurple = Color(0xFF9C27B0);
  static const Color lightPurple = Color(0xFFBA68C8);

  _MeetNLogoPainter({
    required this.sparkleProgress,
    required this.winkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    // Draw two silhouettes meeting and forming a heart
    _drawMeetingSilhouettes(canvas, size);

    // Draw connection sparkle in the middle
    _drawConnectionSparkle(canvas, centerX, centerY);

    // Draw flirty wink
    _drawFlirtyWink(canvas, centerX, centerY);
  }

  void _drawMeetingSilhouettes(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create heart shape from two meeting silhouettes
    final heartPath = Path();

    // Start from bottom point
    heartPath.moveTo(width * 0.5, height * 0.85);

    // Left person/curve
    heartPath.cubicTo(
      width * 0.2, height * 0.7,
      width * 0.1, height * 0.45,
      width * 0.1, height * 0.3,
    );
    heartPath.cubicTo(
      width * 0.1, height * 0.15,
      width * 0.2, height * 0.05,
      width * 0.35, height * 0.05,
    );

    // Top left curve (head of left person)
    heartPath.cubicTo(
      width * 0.42, height * 0.05,
      width * 0.5, height * 0.15,
      width * 0.5, height * 0.22,
    );

    // Right person/curve
    heartPath.cubicTo(
      width * 0.5, height * 0.15,
      width * 0.58, height * 0.05,
      width * 0.65, height * 0.05,
    );
    heartPath.cubicTo(
      width * 0.8, height * 0.05,
      width * 0.9, height * 0.15,
      width * 0.9, height * 0.3,
    );
    heartPath.cubicTo(
      width * 0.9, height * 0.45,
      width * 0.8, height * 0.7,
      width * 0.5, height * 0.85,
    );

    heartPath.close();

    // Gradient for the heart (sexy pink to purple)
    final heartGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryPink,
        deepPink,
        royalPurple,
        lightPurple,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final heartPaint = Paint()
      ..shader = heartGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(heartPath, heartPaint);

    // Add glossy shine effect
    final shinePath = Path();
    shinePath.moveTo(width * 0.3, height * 0.2);
    shinePath.cubicTo(
      width * 0.35, height * 0.15,
      width * 0.4, height * 0.15,
      width * 0.45, height * 0.2,
    );
    shinePath.cubicTo(
      width * 0.4, height * 0.25,
      width * 0.35, height * 0.25,
      width * 0.3, height * 0.2,
    );
    shinePath.close();

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(shinePath, shinePaint);

    // Add smooth outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(heartPath, outlinePaint);

    // Draw subtle "meeting point" in the middle (where they connect)
    final meetingPointPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(
      Offset(width * 0.5, height * 0.22),
      width * 0.08,
      meetingPointPaint,
    );
  }

  void _drawConnectionSparkle(Canvas canvas, double centerX, double centerY) {
    // Draw animated sparkle at the connection point
    final sparkleSize = 8.0 * (math.sin(sparkleProgress * math.pi * 2) * 0.5 + 0.5);

    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Draw 4-pointed star
    final starPath = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final radius = (i % 2 == 0) ? sparkleSize : sparkleSize * 0.4;
      final x = centerX + math.cos(angle) * radius;
      final y = centerY * 0.44 + math.sin(angle) * radius;

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    canvas.drawPath(starPath, sparklePaint);
  }

  void _drawFlirtyWink(Canvas canvas, double centerX, double centerY) {
    if (winkProgress > 0) {
      // Draw a cute wink (semicircle) on the right "person"
      final winkPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * winkProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      // Winking eye position (right side of heart, near top)
      final eyeX = centerX + centerX * 0.3;
      final eyeY = centerY * 0.5;

      // Draw semicircle wink
      final winkPath = Path();
      winkPath.addArc(
        Rect.fromCircle(center: Offset(eyeX, eyeY), radius: 5),
        0,
        math.pi,
      );

      canvas.drawPath(winkPath, winkPaint);

      // Add small sparkle near the wink
      final winkSparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * winkProgress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(eyeX + 8, eyeY - 6),
        2 * winkProgress,
        winkSparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeetNLogoPainter oldDelegate) =>
      oldDelegate.sparkleProgress != sparkleProgress ||
      oldDelegate.winkProgress != winkProgress;
}

/// Compact logo for small spaces (app bar, etc.)
class VibeNouLogoCompact extends StatelessWidget {
  final double size;

  const VibeNouLogoCompact({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF4081),
            Color(0xFF9C27B0),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4081).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.favorite,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
