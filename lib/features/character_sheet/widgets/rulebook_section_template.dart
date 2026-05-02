// Rulebook section layout template (visual patterns copied from the stance card).
//
// Standalone: does not import or modify [RulebookStancePanel].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rulebook_ribbon_clipper.dart';

// --- Terminology & evaluation (design vocabulary) ----------------------------

/// ## User vocabulary → common UX / graphic-design terms
///
/// | Your term | Also called |
/// |-----------|----------------|
/// | Left / right borders | **Lateral rails**, edge strokes, or **chrome** |
/// | Main background | **Content well**, field, or **canvas** |
/// | Main text area | **Body copy block**, primary narrative |
/// | Main ribbon | **Section header band**, title sash, **hero strip** (skew-cut) |
/// | Main ribbon sub text | **Metadata line**, eyebrow, **secondary headline** |
/// | Upper right area | **Accessory slot** (dice, badges, icons) |
/// | Sub area | **Nested band**, **action track** (tiered actions) |
/// | Sub left/right borders | **Nested rails** |
/// | Sub background | **Nested well** / inset surface |
/// | Sub text area | **Action body** |
/// | Sub ribbon | **Nested header** |
/// | Sub upper right | **Nested accessory slot** |
///
/// ## Template evaluation
///
/// **Strengths:** Rails + well + header band + body matches rulebook reading order.
/// One pipeline can serve Styles, Forms, and Stances.
///
/// **Watch-outs:** (1) On narrow widths, stack the accessory slot under the ribbon if
/// needed. (2) Multiple subs share one format—vary [ribbonWidthFactor] per sub if a row
/// needs a wider/narrower band. (3) Prefer [Widget] for copy; strings are for drafts only.

/// **Left / right borders** — lateral stroke around the **main** track.
@immutable
class RulebookTemplateLateralBorder {
  const RulebookTemplateLateralBorder({
    required this.color,
    this.width = 6,
  });

  final Color color;
  final double width;

  Border get border => Border(
        left: BorderSide(color: color, width: width),
        right: BorderSide(color: color, width: width),
      );
}

/// Styling for a skew-cut ribbon (**main ribbon** or **sub ribbon**).
@immutable
class RulebookTemplateRibbonStyle {
  const RulebookTemplateRibbonStyle({
    required this.fill,
    this.minHeight = 52,
    this.diagonalReserve = 66,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 66, 10),
  });

  final Color fill;
  final double minHeight;
  final double diagonalReserve;
  final EdgeInsets padding;
}

/// One **sub area** (nested rails + sub background + sub ribbon + sub body).
@immutable
class RulebookTemplateSubSection {
  const RulebookTemplateSubSection({
    required this.lateralBorder,
    required this.background,
    required this.ribbonStyle,
    required this.ribbonTitle,
    this.ribbonWidthFactor = 0.75,
    this.ribbonSubtitle,
    this.body,
    this.upperRight,
    this.bodyPadding = const EdgeInsets.fromLTRB(14, 10, 14, 12),
    this.titleRibbonFlex = 4,
    this.upperRightFlex = 1,
  });

  final RulebookTemplateLateralBorder lateralBorder;
  final Color background;
  final RulebookTemplateRibbonStyle ribbonStyle;
  final Widget ribbonTitle;
  final double ribbonWidthFactor;
  final Widget? ribbonSubtitle;
  final Widget? body;
  final Widget? upperRight;
  final EdgeInsets bodyPadding;
  final int titleRibbonFlex;
  final int upperRightFlex;
}

/// All inputs needed to render a rulebook-style section.
@immutable
class RulebookSectionTemplateModel {
  const RulebookSectionTemplateModel({
    required this.mainLateralBorder,
    required this.mainBackground,
    required this.mainRibbonStyle,
    required this.mainRibbonTitle,
    this.mainRibbonSubtitle,
    this.mainBody,
    this.mainBodyPadding = const EdgeInsets.fromLTRB(14, 12, 14, 14),
    this.upperRight,
    this.titleRibbonFlex = 4,
    this.upperRightFlex = 1,
    this.subSections = const [],
  });

  final RulebookTemplateLateralBorder mainLateralBorder;
  final Color mainBackground;
  final RulebookTemplateRibbonStyle mainRibbonStyle;
  final Widget mainRibbonTitle;
  final Widget? mainRibbonSubtitle;
  final Widget? mainBody;
  final EdgeInsets mainBodyPadding;
  final Widget? upperRight;
  final int titleRibbonFlex;
  final int upperRightFlex;
  final List<RulebookTemplateSubSection> subSections;
}

/// Renders [RulebookSectionTemplateModel] using the same structural ideas as
/// [RulebookStancePanel] (skew ribbons, lateral rails, optional accessory column).
class RulebookSectionTemplate extends StatelessWidget {
  const RulebookSectionTemplate({
    super.key,
    required this.model,
  });

  final RulebookSectionTemplateModel model;

  static const TextStyle _defaultSubtitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    final m = model;
    return Container(
      decoration: BoxDecoration(
        color: m.mainBackground,
        border: m.mainLateralBorder.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mainHeaderRow(context, m),
          if (m.mainBody != null)
            Padding(
              padding: m.mainBodyPadding,
              child: m.mainBody!,
            ),
          if (m.mainBody != null && m.subSections.isNotEmpty)
            const SizedBox(height: 8),
          for (var i = 0; i < m.subSections.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _SubSectionBlock(section: m.subSections[i]),
          ],
        ],
      ),
    );
  }

  Widget _mainHeaderRow(BuildContext context, RulebookSectionTemplateModel m) {
    final rs = m.mainRibbonStyle;
    final diceRow = m.upperRight;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: diceRow == null ? 1 : m.titleRibbonFlex,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ClipPath(
                  clipper: const LeftRibbonClipper(
                    topRightRadius: kRulebookRibbonCornerRadius,
                  ),
                  child: ColoredBox(
                    color: rs.fill,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: rs.minHeight),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          rs.padding.left,
                          rs.padding.top,
                          rs.diagonalReserve,
                          rs.padding.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            m.mainRibbonTitle,
                            if (m.mainRibbonSubtitle != null) ...[
                              const SizedBox(height: 6),
                              DefaultTextStyle(
                                style: _defaultSubtitleStyle,
                                child: m.mainRibbonSubtitle!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (diceRow != null)
              Expanded(
                flex: m.upperRightFlex,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: diceRow,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubSectionBlock extends StatelessWidget {
  const _SubSectionBlock({required this.section});

  final RulebookTemplateSubSection section;

  static const TextStyle _actionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) {
    final s = section;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.background,
        border: s.lateralBorder.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _subRibbonRow(context, s),
          if (s.body != null)
            Padding(
              padding: s.bodyPadding,
              child: s.body!,
            ),
        ],
      ),
    );
  }

  Widget _subRibbonRow(BuildContext context, RulebookTemplateSubSection s) {
    final upper = s.upperRight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOuterW = constraints.maxWidth.isFinite && constraints.maxWidth > 8
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final ribbonW = maxOuterW * s.ribbonWidthFactor;
        var padR = s.ribbonStyle.diagonalReserve;
        const padL = 14.0;
        const padT = 8.0;
        const padB = 8.0;
        var textHeight = 22.0;
        final titleText = _extractPlainTitle(s.ribbonTitle);
        for (var i = 0; i < 6; i++) {
          final maxTextW = math.max(40.0, ribbonW - padL - padR);
          final tp = TextPainter(
            text: TextSpan(text: titleText, style: _actionTitleStyle),
            textDirection: Directionality.of(context),
          )..layout(maxWidth: maxTextW);
          textHeight = tp.height;
          final ribbonH = math.max(
            44.0,
            textHeight + padT + padB,
          );
          final neededReserve = ribbonH + 14;
          final upperBound = math.max(
            ribbonW - padL - 40,
            s.ribbonStyle.diagonalReserve,
          );
          final nextPadR = math.min(neededReserve, upperBound);
          if ((nextPadR - padR).abs() < 0.5) {
            padR = nextPadR;
            break;
          }
          padR = nextPadR;
        }
        final minRibbonH = math.max(44.0, textHeight + padT + padB);

        final ribbon = ClipPath(
          clipper: const LeftRibbonClipper(
            topRightRadius: kRulebookRibbonCornerRadius,
          ),
          child: ColoredBox(
            color: s.ribbonStyle.fill,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minRibbonH),
              child: Padding(
                padding: EdgeInsets.fromLTRB(padL, padT, padR, padB),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: _actionTitleStyle,
                        child: s.ribbonTitle,
                      ),
                      if (s.ribbonSubtitle != null) ...[
                        const SizedBox(height: 4),
                        s.ribbonSubtitle!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final ribbonSized = Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: ribbonW, child: ribbon),
        );

        if (upper == null) {
          return ribbonSized;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: s.titleRibbonFlex,
              child: ribbonSized,
            ),
            Expanded(
              flex: s.upperRightFlex,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: upper,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Best-effort plain string for layout measurement when [widget] is [Text].
  String _extractPlainTitle(Widget widget) {
    if (widget is Text) {
      return widget.data ?? '';
    }
    return 'Action';
  }
}
