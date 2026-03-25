import 'package:flutter/material.dart';

/// Modern, fluid heart-shaped logo with Haitian flag colors
/// 🇭🇹 Blue (top) and Red (bottom) representing Haiti with smooth animations
class HaitianHeartLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const HaitianHeartLogo({
    super.key,
    this.size = 120,
    this.animate = true,
  });

  @override
  State<HaitianHeartLogo> createState() => _HaitianHeartLogoState();
}

class _HaitianHeartLogoState extends State<HaitianHeartLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00209F).withValues(alpha: widget.animate ? _glowAnimation.value : 0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFD21034).withValues(alpha: widget.animate ? _glowAnimation.value * 0.6 : 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * 0.15),
              child: CustomPaint(
                painter: _ModernHaitianHeartPainter(
                  glowIntensity: widget.animate ? _glowAnimation.value : 0.5,
                ),
                child: Container(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernHaitianHeartPainter extends CustomPainter {
  final double glowIntensity;

  // Official Haitian flag colors
  static const Color haitianBlue = Color(0xFF00209F);
  static const Color haitianRed = Color(0xFFD21034);

  _ModernHaitianHeartPainter({this.glowIntensity = 0.4});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create smooth heart path with fluid curves
    final path = Path();

    // Start at bottom point of heart
    path.moveTo(width * 0.5, height * 0.88);

    // Left curve - smoother and more modern
    path.cubicTo(
      width * 0.15, height * 0.72,
      width * 0.08, height * 0.42,
      width * 0.08, height * 0.28,
    );
    path.cubicTo(
      width * 0.08, height * 0.12,
      width * 0.18, height * 0.02,
      width * 0.33, height * 0.02,
    );
    path.cubicTo(
      width * 0.43, height * 0.02,
      width * 0.5, height * 0.12,
      width * 0.5, height * 0.18,
    );

    // Right curve - smoother and more modern
    path.cubicTo(
      width * 0.5, height * 0.12,
      width * 0.57, height * 0.02,
      width * 0.67, height * 0.02,
    );
    path.cubicTo(
      width * 0.82, height * 0.02,
      width * 0.92, height * 0.12,
      width * 0.92, height * 0.28,
    );
    path.cubicTo(
      width * 0.92, height * 0.42,
      width * 0.85, height * 0.72,
      width * 0.5, height * 0.88,
    );

    path.close();

    // Create gradient for blue half (top)
    final blueGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [
        haitianBlue.withValues(alpha: 1.0),
        haitianBlue.withValues(alpha: 0.9),
        haitianBlue,
      ],
    );

    // Create gradient for red half (bottom)
    final redGradient = LinearGradient(
      begin: Alignment.center,
      end: Alignment.bottomCenter,
      colors: [
        haitianRed,
        haitianRed.withValues(alpha: 0.95),
        haitianRed.withValues(alpha: 1.0),
      ],
    );

    // Draw blue half with gradient
    final blueRect = Rect.fromLTWH(0, 0, width, height * 0.5);
    canvas.save();
    canvas.clipRect(blueRect);
    canvas.drawPath(
      path,
      Paint()..shader = blueGradient.createShader(blueRect),
    );
    canvas.restore();

    // Draw red half with gradient
    final redRect = Rect.fromLTWH(0, height * 0.5, width, height * 0.5);
    canvas.save();
    canvas.clipRect(redRect);
    canvas.drawPath(
      path,
      Paint()..shader = redGradient.createShader(redRect),
    );
    canvas.restore();

    // Add glossy shine effect on top-left
    final shinePath = Path();
    shinePath.moveTo(width * 0.25, height * 0.15);
    shinePath.cubicTo(
      width * 0.3, height * 0.12,
      width * 0.35, height * 0.12,
      width * 0.4, height * 0.15,
    );
    shinePath.cubicTo(
      width * 0.35, height * 0.2,
      width * 0.3, height * 0.2,
      width * 0.25, height * 0.15,
    );
    shinePath.close();

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: glowIntensity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(shinePath, shinePaint);

    // Add modern subtle dividing line with glow
    final dividerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: glowIntensity),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    final linePaint = Paint()
      ..shader = dividerGradient.createShader(
        Rect.fromLTWH(0, height * 0.5 - 1, width, 2),
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, height * 0.5),
      Offset(width, height * 0.5),
      linePaint,
    );

    // Add modern smooth outline to heart
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, outlinePaint);

    // Add inner glow effect
    final innerGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: glowIntensity * 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, innerGlowPaint);
  }

  @override
  bool shouldRepaint(_ModernHaitianHeartPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}
