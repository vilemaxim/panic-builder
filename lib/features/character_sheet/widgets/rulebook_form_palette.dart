import 'package:flutter/material.dart';

/// Printed rulebook-style colors for **form** blocks when separated from stance chrome:
/// violet ribbon → lighter violet lateral rails → pale lavender body.
abstract final class RulebookFormPalette {
  /// Main skew ribbon behind the form name (white title text).
  static const Color ribbon = Color(0xFF527AFE);

  /// Left/right lateral rails (“columns”) — lighter than [ribbon].
  static const Color lateralRail = Color(0xFF839CFF);

  /// Passive text well — lighter still.
  static const Color bodyBackground = Color(0xFFD2C7FF);
}
