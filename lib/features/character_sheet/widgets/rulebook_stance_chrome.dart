import 'package:flutter/material.dart';

import 'rulebook_style_palette.dart';

/// Printed rulebook colors for a stance card shell. [franticStyle] uses the style-card
/// red ramp ([RulebookStylePalette]); action tracks stay green like the book.
@immutable
class RulebookStanceChrome {
  const RulebookStanceChrome({
    required this.mainBodyBackground,
    required this.lateralRail,
    required this.titleRibbonFill,
    required this.headerTitleStyle,
    required this.headerIconColor,
    required this.rangeLineStyle,
    required this.actionTitleGreen,
    required this.actionSideBorderGreen,
    required this.actionDescriptionBg,
    required this.sourceBadgeYellow,
  });

  final Color mainBodyBackground;
  final Color lateralRail;
  final Color titleRibbonFill;

  /// Style + form names in the title ribbon (large).
  final TextStyle headerTitleStyle;
  final Color headerIconColor;
  final TextStyle rangeLineStyle;

  final Color actionTitleGreen;
  final Color actionSideBorderGreen;
  final Color actionDescriptionBg;
  final Color sourceBadgeYellow;

  static const RulebookStanceChrome stance = RulebookStanceChrome(
    mainBodyBackground: Color(0xFFEFF2B8),
    lateralRail: Color(0xFFF5D96D),
    titleRibbonFill: Color(0xFFC8D53D),
    headerTitleStyle: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: Colors.black,
    ),
    headerIconColor: Color(0xDD000000),
    rangeLineStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    actionTitleGreen: Color(0xFF177E2B),
    actionSideBorderGreen: Color(0xFF5CBF78),
    actionDescriptionBg: Color(0xFFC5E5D5),
    sourceBadgeYellow: Color(0xFF9A8E1E),
  );

  static final RulebookStanceChrome franticStyle = RulebookStanceChrome(
    mainBodyBackground: RulebookStylePalette.bodyBackground,
    lateralRail: RulebookStylePalette.lateralRail,
    titleRibbonFill: RulebookStylePalette.ribbon,
    headerTitleStyle: const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: Colors.white,
    ),
    headerIconColor: Color(0xE6FFFFFF),
    rangeLineStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xE6FFFFFF),
    ),
    actionTitleGreen: Color(0xFF177E2B),
    actionSideBorderGreen: Color(0xFF5CBF78),
    actionDescriptionBg: Color(0xFFC5E5D5),
    sourceBadgeYellow: Color(0xFF9A8E1E),
  );
}
