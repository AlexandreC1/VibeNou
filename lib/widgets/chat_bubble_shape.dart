import 'package:flutter/material.dart';

/// A speech-bubble shape with a small tail on the bottom corner.
///
/// Use via [BubbleBackground] which paints the shape behind any child
/// widget. Tail is 8px tall/wide; corner radius is 20 elsewhere and 4 near
/// the tail so the tail reads as connected to the bubble.
class BubbleBackground extends StatelessWidget {
  final Widget child;
  final bool isMe;
  final Color? solidColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  const BubbleBackground({
    super.key,
    required this.child,
    required this.isMe,
    this.solidColor,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        isMe: isMe,
        solidColor: solidColor,
        gradient: gradient,
      ),
      child: Padding(
        padding: padding.add(
          EdgeInsets.only(left: isMe ? 0 : 6, right: isMe ? 6 : 0),
        ),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final bool isMe;
  final Color? solidColor;
  final Gradient? gradient;

  _BubblePainter({
    required this.isMe,
    this.solidColor,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = solidColor ?? Colors.grey;
    }

    const radius = Radius.circular(20);
    const smallRadius = Radius.circular(6);
    final bodyWidth = size.width - 6; // leave room for tail
    final bodyRect = Rect.fromLTWH(
      isMe ? 0 : 6,
      0,
      bodyWidth,
      size.height,
    );

    final rrect = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: radius,
      topRight: radius,
      bottomLeft: isMe ? radius : smallRadius,
      bottomRight: isMe ? smallRadius : radius,
    );

    final path = Path()..addRRect(rrect);

    // Tail triangle
    final tailPath = Path();
    if (isMe) {
      tailPath.moveTo(bodyRect.right - 2, size.height - 10);
      tailPath.quadraticBezierTo(
        bodyRect.right + 6, size.height - 2,
        bodyRect.right - 4, size.height,
      );
      tailPath.close();
    } else {
      tailPath.moveTo(bodyRect.left + 2, size.height - 10);
      tailPath.quadraticBezierTo(
        bodyRect.left - 6, size.height - 2,
        bodyRect.left + 4, size.height,
      );
      tailPath.close();
    }

    canvas.drawPath(Path.combine(PathOperation.union, path, tailPath), paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.isMe != isMe ||
        oldDelegate.solidColor != solidColor ||
        oldDelegate.gradient != gradient;
  }
}
