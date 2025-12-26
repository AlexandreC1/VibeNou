import 'package:flutter/material.dart';

/// Custom heart-shaped logo with Haitian flag colors
/// 🇭🇹 Blue (top) and Red (bottom) representing Haiti
class HaitianHeartLogo extends StatelessWidget {
  final double size;
  final bool animate;

  const HaitianHeartLogo({
    super.key,
    this.size = 120,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _HaitianHeartPainter(),
          child: Container(),
        ),
      ),
    );
  }
}

class _HaitianHeartPainter extends CustomPainter {
  // Official Haitian flag colors
  static const Color haitianBlue = Color(0xFF00209F);
  static const Color haitianRed = Color(0xFFD21034);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create heart path
    final path = Path();

    // Start at bottom point of heart
    path.moveTo(width * 0.5, height * 0.85);

    // Left curve
    path.cubicTo(
      width * 0.2, height * 0.7,
      width * 0.1, height * 0.4,
      width * 0.1, height * 0.3,
    );
    path.cubicTo(
      width * 0.1, height * 0.15,
      width * 0.2, height * 0.05,
      width * 0.35, height * 0.05,
    );
    path.cubicTo(
      width * 0.45, height * 0.05,
      width * 0.5, height * 0.15,
      width * 0.5, height * 0.2,
    );

    // Right curve
    path.cubicTo(
      width * 0.5, height * 0.15,
      width * 0.55, height * 0.05,
      width * 0.65, height * 0.05,
    );
    path.cubicTo(
      width * 0.8, height * 0.05,
      width * 0.9, height * 0.15,
      width * 0.9, height * 0.3,
    );
    path.cubicTo(
      width * 0.9, height * 0.4,
      width * 0.8, height * 0.7,
      width * 0.5, height * 0.85,
    );

    path.close();

    // Draw blue half (top)
    final blueRect = Rect.fromLTWH(0, 0, width, height * 0.5);
    canvas.save();
    canvas.clipRect(blueRect);
    canvas.drawPath(path, Paint()..color = haitianBlue);
    canvas.restore();

    // Draw red half (bottom)
    final redRect = Rect.fromLTWH(0, height * 0.5, width, height * 0.5);
    canvas.save();
    canvas.clipRect(redRect);
    canvas.drawPath(path, Paint()..color = haitianRed);
    canvas.restore();

    // Add subtle white dividing line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, height * 0.5),
      Offset(width, height * 0.5),
      linePaint,
    );

    // Optional: Add white outline to heart
    final outlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(_HaitianHeartPainter oldDelegate) => false;
}
