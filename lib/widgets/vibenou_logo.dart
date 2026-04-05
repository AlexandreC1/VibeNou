/// VibeNou Logo - Modern "V-Heart" Design
///
/// A stylized "V" lettermark that subtly forms a heart shape,
/// with Haitian flag color accents (blue #003087 and red #CE1126).
///
/// Animations:
/// - Splash: Stroke-by-stroke draw → gradient fill → pulse
/// - App bar: Compact static version
/// - Match celebration: Pulse with glow effect
///
/// Last updated: 2026-04-05
library;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
  late AnimationController _drawController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _drawAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();

    // Stroke draw-on animation (0 → 1 over 1.5s)
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOut,
    );

    // Fill fades in during the last 30% of the draw
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Continuous pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _drawController.forward().then((_) {
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      });
    } else {
      _drawController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_drawController, _pulseController, _glowController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _VHeartLogoPainter(
                    drawProgress: _drawAnimation.value,
                    fillOpacity: _fillAnimation.value,
                    glowIntensity: _glowAnimation.value,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showWordmark) ...[
          SizedBox(height: widget.size * 0.15),
          AnimatedBuilder(
            animation: _drawController,
            builder: (context, child) {
              return Opacity(
                opacity: _fillAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - _fillAnimation.value)),
                  child: child,
                ),
              );
            },
            child: Text(
              'VibeNou',
              style: TextStyle(
                fontSize: widget.size * 0.28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      Color(0xFFE91E63), // Rose
                      Color(0xFFCE1126), // Haitian Red
                      Color(0xFF003087), // Haitian Blue
                    ],
                  ).createShader(Rect.fromLTWH(0, 0, widget.size * 1.5, widget.size * 0.3)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact logo variant for app bars and small spaces.
class VibeNouLogoCompact extends StatelessWidget {
  final double size;

  const VibeNouLogoCompact({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VHeartLogoPainter(
          drawProgress: 1.0,
          fillOpacity: 1.0,
          glowIntensity: 0.0,
        ),
      ),
    );
  }
}

/// Custom painter that draws the V-Heart logo.
///
/// The design: two curved strokes forming a "V" that curves at the top
/// to create a heart shape. The left curve uses Haitian blue, the right
/// uses Haitian red, meeting at the bottom point with a gradient blend.
class _VHeartLogoPainter extends CustomPainter {
  final double drawProgress;
  final double fillOpacity;
  final double glowIntensity;

  _VHeartLogoPainter({
    required this.drawProgress,
    required this.fillOpacity,
    required this.glowIntensity,
  });

  static const Color _haitianBlue = Color(0xFF003087);
  static const Color _haitianRed = Color(0xFFCE1126);
  static const Color _rose = Color(0xFFE91E63);
  static const Color _coral = Color(0xFFFF6B6B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // The V-Heart path
    final path = Path();

    // Start from bottom center (the "V" point)
    path.moveTo(cx, h * 0.88);

    // Left curve (goes up and curves to form left heart lobe)
    path.cubicTo(
      cx - w * 0.15, h * 0.65,  // control 1
      w * 0.02, h * 0.45,        // control 2
      w * 0.08, h * 0.28,        // end - top of left lobe
    );

    // Left lobe top curve
    path.cubicTo(
      w * 0.12, h * 0.14,
      w * 0.28, h * 0.08,
      cx, h * 0.22,
    );

    // Right lobe top curve
    path.cubicTo(
      w * 0.72, h * 0.08,
      w * 0.88, h * 0.14,
      w * 0.92, h * 0.28,
    );

    // Right curve (goes down to "V" point)
    path.cubicTo(
      w * 0.98, h * 0.45,
      cx + w * 0.15, h * 0.65,
      cx, h * 0.88,
    );

    path.close();

    // Draw glow
    if (glowIntensity > 0 && fillOpacity > 0) {
      final glowPaint = Paint()
        ..color = _rose.withValues(alpha: 0.15 * glowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * glowIntensity);
      canvas.drawPath(path, glowPaint);
    }

    // Draw filled gradient
    if (fillOpacity > 0) {
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(w, h),
          [
            _haitianBlue,
            _rose,
            _haitianRed,
          ],
          [0.0, 0.5, 1.0],
        )
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.clipPath(path);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        fillPaint..color = fillPaint.color.withValues(alpha: fillOpacity),
      );

      // Glossy highlight
      final highlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - w * 0.1, h * 0.25),
          w * 0.4,
          [
            Colors.white.withValues(alpha: 0.35 * fillOpacity),
            Colors.white.withValues(alpha: 0.0),
          ],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), highlightPaint);
      canvas.restore();
    }

    // Draw stroke (animated)
    if (drawProgress > 0) {
      final metrics = path.computeMetrics().toList();
      for (final metric in metrics) {
        final extractPath = metric.extractPath(
          0,
          metric.length * drawProgress,
        );

        final strokePaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, 0),
            Offset(w, h),
            [_haitianBlue, _rose, _haitianRed],
            [0.0, 0.5, 1.0],
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.04
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(extractPath, strokePaint);
      }
    }

    // Inner "V" accent lines for the lettermark effect
    if (fillOpacity > 0.5) {
      final vAccent = Paint()
        ..color = Colors.white.withValues(alpha: 0.4 * fillOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015
        ..strokeCap = StrokeCap.round;

      // Left V line
      final leftV = Path()
        ..moveTo(cx - w * 0.12, h * 0.35)
        ..lineTo(cx, h * 0.72);
      canvas.drawPath(leftV, vAccent);

      // Right V line
      final rightV = Path()
        ..moveTo(cx + w * 0.12, h * 0.35)
        ..lineTo(cx, h * 0.72);
      canvas.drawPath(rightV, vAccent);
    }
  }

  @override
  bool shouldRepaint(_VHeartLogoPainter oldDelegate) {
    return drawProgress != oldDelegate.drawProgress ||
        fillOpacity != oldDelegate.fillOpacity ||
        glowIntensity != oldDelegate.glowIntensity;
  }
}
