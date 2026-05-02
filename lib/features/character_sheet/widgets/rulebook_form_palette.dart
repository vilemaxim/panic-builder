import 'package:flutter/material.dart';

/// Printed rulebook-style colors for **form** blocks when separated from stance chrome:
/// vivid blue ribbon → lighter blue lateral rails → pale blue body.
abstract final class RulebookFormPalette {
  /// Main skew ribbon behind the form name (white title text).
  static const Color ribbon = Color(0xFF1565C0);

  /// Left/right lateral rails (“columns”) — lighter than [ribbon].
  static const Color lateralRail = Color(0xFF64B5F6);

  /// Passive text well — lighter still.
  static const Color bodyBackground = Color(0xFFE3F2FD);
}
