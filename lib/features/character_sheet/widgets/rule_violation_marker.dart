import 'package:flutter/material.dart';

/// Small red triangle with a hover/long-press tooltip describing a rules violation.
class RuleViolationTriangle extends StatelessWidget {
  const RuleViolationTriangle({
    super.key,
    required this.message,
    this.size = 14,
  });

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 30),
      child: CustomPaint(
        size: Size(size, size),
        painter: _RedTrianglePainter(),
      ),
    );
  }
}

class _RedTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC62828)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5C0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
