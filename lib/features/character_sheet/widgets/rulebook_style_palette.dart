import 'package:flutter/material.dart';

/// Colors for **style** blocks (rulebook-facing): vivid ribbon, softer lateral rails,
/// pale body wash.
///
/// Eyematch against the printed PaD PDF and tweak here. For PDF export, use
/// `PdfColor.fromInt` with the same `0xFF…` values as [ribbon], [lateralRail],
/// and [bodyBackground].
abstract final class RulebookStylePalette {
  /// **Main ribbon** — bright red header band (white title text).
  static const Color ribbon = Color(0xFFE53935);

  /// **Left/right borders** (“boards”) — a step lighter than [ribbon].
  static const Color lateralRail = Color(0xFFFF7961);

  /// **Main text background** — lighter still behind passive copy.
  static const Color bodyBackground = Color(0xFFFFEBEE);
}
