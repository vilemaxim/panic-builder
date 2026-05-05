// Rulebook PNG chrome for sheet sections (backgrounds include lateral rails + fill;
// banners are ribbon strips overlaid with dynamic text).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layout targets shared by sheet chrome (matches ~375-400px book column width).
abstract final class RulebookSheetLayout {
  /// Caps banner/ribbon height on wide layouts; narrower viewports use full width.
  static const double bannerMaxDisplayWidth = 380;

  /// Native width of [RulebookSheetImageAssets.backgroundSkills] (for inset math).
  static const double skillsBackgroundNativeWidth = 375;

  /// Horizontal inset before banners/content so they clear the orange rails in
  /// `skills.png`. Derived offline by scanning columns for saturated orange (rail
  /// ends ~x=7–8 at native width; no extra gutter—ribbon aligns with the inner edge.
  static const double skillsBackgroundLeftInsetPx = 7;

  /// [skillsBackgroundLeftInsetPx] / [skillsBackgroundNativeWidth].
  static const double skillsBackgroundLeftInsetRatio =
      skillsBackgroundLeftInsetPx / skillsBackgroundNativeWidth;

  /// Horizontal inset (each side) so content clears the orange rails in
  /// `skills.png` — use for symmetric [Padding].
  static double skillsBackgroundHorizontalRailInset(double sheetColumnWidth) =>
      sheetColumnWidth * skillsBackgroundLeftInsetRatio;

  /// Same as [skillsBackgroundHorizontalRailInset] (name kept for call sites).
  static double skillsBackgroundLeftRailInset(double sheetColumnWidth) =>
      skillsBackgroundHorizontalRailInset(sheetColumnWidth);
}

/// Asset paths aligned with the printed rulebook (375×236 backgrounds, 400×60 banners).
abstract final class RulebookSheetImageAssets {
  static const String backgroundStyle =
      'assets/images/backgrounds/style.png';
  static const String backgroundStance =
      'assets/images/backgrounds/stance.png';
  static const String backgroundForm = 'assets/images/backgrounds/form.png';
  static const String backgroundSkills =
      'assets/images/backgrounds/skills.png';
  static const String backgroundAction =
      'assets/images/backgrounds/action.png';
  static const String backgroundArchetype =
      'assets/images/backgrounds/archetype.png';

  static const String bannerStyle = 'assets/images/banners/banner-style.png';
  static const String bannerStance = 'assets/images/banners/banner-stance.png';
  static const String bannerForm = 'assets/images/banners/banner-form.png';
  /// Character name + hero type ribbon on the main sheet.
  static const String bannerCharacterName =
      'assets/images/banners/banner-character_name.png';
  static const String bannerSkill = 'assets/images/banners/banner-skill.png';
  static const String bannerAction = 'assets/images/banners/banner-action.png';
  static const String bannerArchetype =
      'assets/images/banners/banner-archtype.png';
}

/// Ribbon from [imageAsset] scaled to [width] with [child] centered vertically;
/// height follows the asset aspect ratio (400×60).
class RulebookAssetRibbon extends StatelessWidget {
  const RulebookAssetRibbon({
    super.key,
    required this.imageAsset,
    required this.child,
    this.padding = EdgeInsets.zero,
    /// When set (e.g. [RulebookSheetLayout.bannerMaxDisplayWidth]), ribbon height
    /// stops growing past book scale on wide screens; widget is left-aligned.
    this.maxDisplayWidth,
    this.alignment = Alignment.centerLeft,
    /// Overrides intrinsic aspect height (e.g. skill ribbons at fixed logical height).
    this.fixedHeight,
    /// Horizontal mirror for the PNG only.
    this.mirrorBackgroundImage = false,
    /// Rotates only the background PNG by 180 degrees (text/content unchanged).
    this.rotateBackground180 = false,
  });

  final String imageAsset;
  final Widget child;
  final EdgeInsets padding;
  final double? maxDisplayWidth;
  final AlignmentGeometry alignment;
  final double? fixedHeight;
  final bool mirrorBackgroundImage;
  final bool rotateBackground180;

  static const double _srcW = 400;
  static const double _srcH = 60;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final w = maxDisplayWidth != null
            ? math.min(maxW, maxDisplayWidth!)
            : maxW;
        final h = fixedHeight ?? (w * (_srcH / _srcW));
        Widget layer = Image.asset(
          imageAsset,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
        if (mirrorBackgroundImage) {
          layer = Transform.flip(flipX: true, child: layer);
        }
        if (rotateBackground180) {
          layer = Transform.rotate(angle: math.pi, child: layer);
        }
        final ribbon = SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: layer),
              Positioned.fill(
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        );
        if (maxDisplayWidth == null || (w - maxW).abs() < 0.5) {
          return ribbon;
        }
        return Align(alignment: alignment, child: ribbon);
      },
    );
  }
}

/// Paints [backgroundAsset] behind [child] using [BoxFit.fill] so the frame
/// grows with content (same pattern as a solid [BoxDecoration.color]).
class RulebookAssetPanelBackground extends StatelessWidget {
  const RulebookAssetPanelBackground({
    super.key,
    required this.backgroundAsset,
    required this.child,
  });

  final String backgroundAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
        ),
      ),
      child: child,
    );
  }
}
