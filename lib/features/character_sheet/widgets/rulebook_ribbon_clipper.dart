import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Convex fillet on clipped rulebook ribbons (name banner, skill tiles, stance headers).
const double kRulebookRibbonCornerRadius = 6;

/// Horizontal inset so the ribbon diagonal is ~45° (rise equals height, so tangent is 1).
/// Capped when width is narrower than height so the path stays valid.
double _ribbonSkewFor45(Size size) {
  final w = size.width;
  final h = size.height;
  if (w <= 0 || h <= 0) return 0;
  return math.min(h, math.max(0.0, w - 1));
}

extension _RibbonOffsetNormalize on Offset {
  Offset ribbonNorm() {
    final len = distance;
    if (len < 1e-9) return Offset.zero;
    return Offset(dx / len, dy / len);
  }
}

double _ribbonCornerInteriorAngle(Offset prev, Offset corner, Offset next) {
  final incoming = (corner - prev).ribbonNorm();
  final outgoing = (next - corner).ribbonNorm();
  final cosT =
      (-incoming.dx * outgoing.dx - incoming.dy * outgoing.dy).clamp(-1.0, 1.0);
  return math.acos(cosT);
}

/// Straight **left** edge; **right** diagonal (~45° via [_ribbonSkewFor45]).
/// Optional [topRightRadius]: convex fillet only at the top-right (where top meets the slash).
class LeftRibbonClipper extends CustomClipper<Path> {
  const LeftRibbonClipper({this.topRightRadius});

  /// When set, radius in logical pixels for the top-right corner only.
  final double? topRightRadius;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final skew = _ribbonSkewFor45(size);

    if (skew <= 0 || h <= 0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, math.max(w, 0), math.max(h, 0)));
    }

    final rawR = topRightRadius;
    if (rawR != null && rawR > 0.5) {
      final r = math.min(
        rawR,
        math.min(skew * 0.28, math.min(h * 0.22, (w - skew) * 0.35)),
      );
      if (r > 0.5) {
        final tl = Offset.zero;
        final tr = Offset(w, 0);
        final br = Offset(w - skew, h);
        final bl = Offset(0, h);

        final thetaTr = _ribbonCornerInteriorAngle(tl, tr, br);
        final tTr = r / math.tan(thetaTr / 2);
        final incomingTop = (tr - tl).ribbonNorm();
        final outgoingDiag = (br - tr).ribbonNorm();
        final arcStartTr = tr - incomingTop * tTr;
        final arcEndTr = tr + outgoingDiag * tTr;

        return Path()
          ..moveTo(bl.dx, bl.dy)
          ..lineTo(tl.dx, tl.dy)
          ..lineTo(arcStartTr.dx, arcStartTr.dy)
          ..arcToPoint(
            arcEndTr,
            radius: Radius.circular(r),
            rotation: 0,
            largeArc: false,
            clockwise: true,
          )
          ..lineTo(br.dx, br.dy)
          ..lineTo(bl.dx, bl.dy)
          ..close();
      }
    }

    return Path()
      ..moveTo(0, h)
      ..lineTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - skew, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant LeftRibbonClipper oldClipper) =>
      oldClipper.topRightRadius != topRightRadius;
}

/// Straight **right** edge; **left** diagonal (top inset on the left).
///
/// Optional [bottomLeftRadius]: convex fillet only at the bottom-left (where bottom meets the slash).
class RightRibbonClipper extends CustomClipper<Path> {
  const RightRibbonClipper({this.bottomLeftRadius});

  final double? bottomLeftRadius;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final skew = _ribbonSkewFor45(size);

    if (skew <= 0 || h <= 0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, math.max(w, 0), math.max(h, 0)));
    }

    final tl = Offset(skew, 0);
    final tr = Offset(w, 0);
    final br = Offset(w, h);
    final bl = Offset(0, h);

    final rawR = bottomLeftRadius;
    if (rawR != null && rawR > 0.5) {
      final r = math.min(
        rawR,
        math.min(skew * 0.28, math.min(h * 0.22, w * 0.3)),
      );
      if (r > 0.5) {
        final thetaBl = _ribbonCornerInteriorAngle(br, bl, tl);
        final tBl = r / math.tan(thetaBl / 2);
        final towardBr = (br - bl).ribbonNorm();
        final towardTl = (tl - bl).ribbonNorm();
        final arcEndOnBottom = bl + towardBr * tBl;
        final arcStartOnDiag = bl + towardTl * tBl;

        return Path()
          ..moveTo(tl.dx, tl.dy)
          ..lineTo(tr.dx, tr.dy)
          ..lineTo(br.dx, br.dy)
          ..lineTo(arcEndOnBottom.dx, arcEndOnBottom.dy)
          ..arcToPoint(
            arcStartOnDiag,
            radius: Radius.circular(r),
            rotation: 0,
            largeArc: false,
            clockwise: true,
          )
          ..lineTo(tl.dx, tl.dy)
          ..close();
      }
    }

    return Path()
      ..moveTo(skew, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant RightRibbonClipper oldClipper) =>
      oldClipper.bottomLeftRadius != bottomLeftRadius;
}
