import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws a recognizable die silhouette for stance dice chips (avoids broken raster placeholders).
class DieSilhouettePainter extends CustomPainter {
  DieSilhouettePainter({required this.silhouetteSides, required this.label})
    : assert({4, 6, 8, 10}.contains(silhouetteSides));

  /// Shape family: 4 / 6 / 8 / 10 only.
  final int silhouetteSides;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = math.max(1.5, w * 0.06);
    final rect = Rect.fromLTWH(inset, inset, w - 2 * inset, h - 2 * inset);

    final path = _outlinePath(rect, silhouetteSides);
    canvas.drawShadow(path, Colors.black, 2.5, false);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0F4F8)],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * 0.045)
        ..color = Colors.black54,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black87,
          fontSize: w * (label.length >= 2 ? 0.28 : 0.36),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((w - tp.width) / 2, (h - tp.height) / 2 - h * 0.02),
    );
  }

  Path _outlinePath(Rect r, int sides) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    switch (sides) {
      case 4:
        return Path()
          ..moveTo(cx, r.top)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close();
      case 6:
        final rr = RRect.fromRectXY(
          r,
          r.shortestSide * 0.14,
          r.shortestSide * 0.14,
        );
        return Path()..addRRect(rr);
      case 8:
        return Path()
          ..moveTo(cx, r.top)
          ..lineTo(r.right, cy)
          ..lineTo(cx, r.bottom)
          ..lineTo(r.left, cy)
          ..close();
      case 10:
        final kite = Path()
          ..moveTo(cx, r.top + r.height * 0.05)
          ..lineTo(r.right - r.width * 0.06, cy - r.height * 0.06)
          ..lineTo(r.right - r.width * 0.12, r.bottom - r.height * 0.08)
          ..lineTo(r.left + r.width * 0.12, r.bottom - r.height * 0.08)
          ..lineTo(r.left + r.width * 0.06, cy - r.height * 0.06)
          ..close();
        return kite;
      default:
        throw ArgumentError.value(
          sides,
          'silhouetteSides',
          'expected 4, 6, 8, or 10',
        );
    }
  }

  @override
  bool shouldRepaint(covariant DieSilhouettePainter oldDelegate) =>
      oldDelegate.silhouetteSides != silhouetteSides ||
      oldDelegate.label != label;
}
