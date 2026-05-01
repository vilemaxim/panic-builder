import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/hero_type_kind.dart';
import '../character_sheet/character_sheet_presenter.dart';
import '../character_sheet/widgets/form_dice_catalog.dart' show formDicePoolForForm;

/// Keeps stance title + range out of the skewed ribbon corner (two-line header).
const double _kStanceTitleRibbonDiagonalReservePdf = 46;

RuleSkill? _pdfResolvedStyleSkill(RuleStyle? st, MergedRules rules) {
  if (st == null) return null;
  final id = st.skillId;
  if (id == null || id.isEmpty) return null;
  return rules.skillById(id);
}

/// Matches [RulebookStancePanel._styleRangeLabel].
String _pdfStyleRangeLabel(RuleStyle? style, RuleSkill? skill) {
  if (style == null) return 'Range: --';
  final r = style.range.trim();
  if (r.isNotEmpty) return 'Range: $r';
  final merged = skill != null && skill.description.trim().isNotEmpty
      ? skill.description
      : '${style.basicInfo}\n${style.marginNotes}';
  final m = RegExp(
    r'Range:\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(merged);
  if (m != null) return 'Range: ${m.group(1)?.trim() ?? ''}';
  return 'Range: --';
}

abstract final class _PdfPalette {
  static const PdfColor paper = PdfColor.fromInt(0xFFFFFAEC);
  static const PdfColor ink = PdfColor.fromInt(0xFF2F2418);
  static const PdfColor muted = PdfColor.fromInt(0xFF4B3B2A);
  static const PdfColor bannerBrown = PdfColor.fromInt(0xFFB8722E);
  static const PdfColor purpleBand = PdfColor.fromInt(0xFF5C376B);
  static const PdfColor purpleBg = PdfColor.fromInt(0xFFEADDF5);
  static const PdfColor purpleBorder = PdfColor.fromInt(0xFF8E6AA3);
  static const PdfColor sheetField = PdfColor.fromInt(0xFFFFF2B8);
  static const PdfColor sheetAccent = PdfColor.fromInt(0xFFE87722);
  static const PdfColor pillOrange = PdfColor.fromInt(0xFFE86921);
  static const PdfColor stanceTitle = PdfColor.fromInt(0xFFC8D53D);
  static const PdfColor stanceBody = PdfColor.fromInt(0xFFEFF2B8);
  static const PdfColor stanceActionBg = PdfColor.fromInt(0xFFC5E5D5);
  static const PdfColor stanceActionTitle = PdfColor.fromInt(0xFF177E2B);
  /// Lighter accent for inner side boards (ribbons stay [_PdfPalette.stanceActionTitle]).
  static const PdfColor stanceActionBoard = PdfColor.fromInt(0xFF42AB63);
  static const PdfColor stanceRail = PdfColor.fromInt(0xFFF5D96D);
}

const double _kOuterMargin = 14;
const double _halfGap = 8;

/// Matches rulebook rails (`RulebookCharacterSheetPanel._railW`).
const double _kRailW = 12;
const double _kRailTextInset = _kRailW + 4;

/// Stance title dice: keep chips inside the column (past yellow rail + breathing room).
const double _kStanceDiceHeaderRightInset = _kRailW + 10;

/// Inner purple/green side accent bars (narrower than [_kRailW]).
const double _kInnerBoardW = 10;

/// Inset from panel edge so boards sit slightly inside the orange/yellow rails.
const double _kInnerBoardEdgeInset = 8;

/// Text clears thick inner boards plus edge inset.
double get _kInnerBoardTextPaddingLR => 10 + _kInnerBoardW + _kInnerBoardEdgeInset;

/// Pdf ribbon height (~rulebook skill tiles, scaled for half-letter).
const double _kSkillRibbonHeightPdf = 22;

/// Keeps labels out of the skewed corner (mirrors `_skillRibbonDiagonalReserve`).
const double _kSkillRibbonDiagonalReservePdf = 30;

/// Right pad inside name banner so wrapped text clears the diagonal (~`_bannerTrailingReserveForDiagonal`).
const double _kBannerTrailingReservePdf = 62;

const _pdfRegularFontAsset = 'assets/fonts/DejaVuSerif.ttf';
const _pdfBoldFontAsset = 'assets/fonts/DejaVuSerif-Bold.ttf';
const _pdfItalicFontAsset = 'assets/fonts/DejaVuSerif-Italic.ttf';
const _pdfBoldItalicFontAsset = 'assets/fonts/DejaVuSerif-BoldItalic.ttf';

class _PdfFontPack {
  const _PdfFontPack({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;
}

Future<_PdfFontPack>? _cachedPdfFontPack;

Future<_PdfFontPack> _loadPdfFontPack() {
  return _cachedPdfFontPack ??= () async {
    final regular = pw.Font.ttf(await rootBundle.load(_pdfRegularFontAsset));
    final bold = pw.Font.ttf(await rootBundle.load(_pdfBoldFontAsset));
    final italic = pw.Font.ttf(await rootBundle.load(_pdfItalicFontAsset));
    final boldItalic = pw.Font.ttf(
      await rootBundle.load(_pdfBoldItalicFontAsset),
    );
    return _PdfFontPack(
      regular: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    );
  }();
}

/// Full letter landscape 11" x 8.5" at 72 dpi.
PdfPageFormat get halfLetterLandscape =>
    const PdfPageFormat(792, 612, marginAll: 0);

/// Usable width of one half-column (character or stance) inside page padding + center gap.
double _stanceOrCharacterHalfWidth() {
  final inner =
      halfLetterLandscape.availableWidth - 2 * _kOuterMargin - _halfGap;
  return inner / 2;
}

/// Side accent bars behind copy; optional [header] sits above [body] in the same block
/// so boards span ribbon + tinted body (not only below the ribbon).
///
/// A plain [pw.Row] + [pw.Expanded] without this [pw.Stack] sizing breaks under the pdf
/// package when the row sits in a vertically unbounded [pw.Column].
pw.Widget pdfInnerBoardedBody({
  required PdfColor backgroundColor,
  required PdfColor boardColor,
  required pw.Widget body,
  pw.Widget? header,
}) {
  final textInset =
      _kInnerBoardEdgeInset + _kInnerBoardW + 10; // mirrors prior Padding LR gap
  return pw.Container(
    width: double.infinity,
    color: backgroundColor,
    child: pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(width: _kInnerBoardEdgeInset),
              pdfFilledVerticalBar(width: _kInnerBoardW, color: boardColor),
              pw.Expanded(child: pw.SizedBox()),
              pdfFilledVerticalBar(width: _kInnerBoardW, color: boardColor),
              pw.SizedBox(width: _kInnerBoardEdgeInset),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (header != null) header,
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(textInset, 8, textInset, 10),
              child: body,
            ),
          ],
        ),
      ],
    ),
  );
}

/// Vertical color strip that fills available height ([pw.Row] stretch or [pw.Stack] rail).
///
/// The pdf package's [pw.Container] with only `width` + `color` (no child) synthesizes a
/// [LimitedBox] capped at 0×0 unless constraints are tight on both axes, so colored
/// rails collapse to short centered stubs instead of spanning the panel.
pw.Widget pdfFilledVerticalBar({
  required double width,
  required PdfColor color,
}) {
  return pw.Container(
    width: width,
    color: color,
    child: pw.SizedBox.expand(),
  );
}

@visibleForTesting
String normalizePdfTextForHelvetica(String text) {
  return text
      .replaceAll(String.fromCharCode(0x2014), '--') // em dash
      .replaceAll(String.fromCharCode(0x2013), '-') // en dash
      .replaceAll(String.fromCharCode(0x2012), '-') // figure dash
      .replaceAll(String.fromCharCode(0x2212), '-') // minus sign
      .replaceAll(String.fromCharCode(0x2022), '* ') // bullet
      .replaceAll(String.fromCharCode(0x00B7), ' - ') // middle dot
      .replaceAll(String.fromCharCode(0x2018), "'") // ‘
      .replaceAll(String.fromCharCode(0x2019), "'") // ’
      .replaceAll(String.fromCharCode(0x201C), '"') // “
      .replaceAll(String.fromCharCode(0x201D), '"') // ”
      .replaceAll(String.fromCharCode(0x2026), '...'); // …
}

double _ribbonSkewPdf(double w, double h) {
  if (w <= 0 || h <= 0) return 0;
  return math.min(h, math.max(0.0, w - 1));
}

/// Fills and clips to a [LeftRibbonClipper]-shaped polygon (PDF y-up).
class _PdfSkewLeftRibbon extends pw.SingleChildWidget {
  _PdfSkewLeftRibbon({
    required this.fillColor,
    this.cornerRadius = 6,
    super.child,
  });

  final PdfColor fillColor;
  final double cornerRadius;

  void _drawPath(pw.Context context, {required bool clipOnly}) {
    final b = box!;
    final w = b.width;
    final h = b.height;
    final skew = _ribbonSkewPdf(w, h);
    final left = b.left;
    final bottom = b.bottom;
    final cX = left + w;
    final cY = bottom + h;
    final diagLen = math.sqrt(skew * skew + h * h);
    final outDx = diagLen <= 1e-6 ? -1.0 : -skew / diagLen;
    final outDy = diagLen <= 1e-6 ? -1.0 : -h / diagLen;
    const kappa = 0.5522847498;
    final rawR = cornerRadius;
    final r = math.min(
      rawR,
      math.min(
        skew * 0.28,
        math.min(h * 0.22, math.max(0.0, (w - skew) * 0.35)),
      ),
    );

    context.canvas
      ..moveTo(left, bottom)
      ..lineTo(left, bottom + h);
    if (r > 0.5) {
      final theta = math.acos((-outDx).clamp(-1.0, 1.0));
      final t = r / math.tan(theta / 2);
      final arcStartX = cX - t;
      final arcStartY = cY;
      final arcEndX = cX + outDx * t;
      final arcEndY = cY + outDy * t;
      final c1x = arcStartX + kappa * t;
      final c1y = arcStartY;
      final c2x = arcEndX - kappa * outDx * t;
      final c2y = arcEndY - kappa * outDy * t;
      context.canvas
        ..lineTo(arcStartX, arcStartY)
        ..curveTo(c1x, c1y, c2x, c2y, arcEndX, arcEndY)
        ..lineTo(left + w - skew, bottom);
    } else {
      context.canvas
        ..lineTo(left + w, bottom + h)
        ..lineTo(left + w - skew, bottom);
    }
    context.canvas..closePath();

    if (clipOnly) {
      context.canvas.clipPath();
    } else {
      context.canvas.fillPath();
    }
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final c = child;
    if (c == null) return;
    final b = box!;
    final mat = Matrix4.identity()..translateByDouble(b.left, b.bottom, 0, 1);

    context.canvas
      ..saveContext()
      ..setFillColor(fillColor);
    _drawPath(context, clipOnly: false);
    _drawPath(context, clipOnly: true);
    context.canvas.setTransform(mat);
    c.paint(context);
    context.canvas.restoreContext();
  }
}

/// Fills and clips to a [RightRibbonClipper]-shaped polygon (PDF y-up).
class _PdfSkewRightRibbon extends pw.SingleChildWidget {
  _PdfSkewRightRibbon({
    required this.fillColor,
    this.cornerRadius = 6,
    super.child,
  });

  final PdfColor fillColor;
  final double cornerRadius;

  void _drawPath(pw.Context context, {required bool clipOnly}) {
    final b = box!;
    final w = b.width;
    final h = b.height;
    final skew = _ribbonSkewPdf(w, h);
    final left = b.left;
    final bottom = b.bottom;
    final tlX = left + skew;
    final tlY = bottom + h;
    final blX = left;
    final blY = bottom;
    final diagLen = math.sqrt(skew * skew + h * h);
    final outDx = diagLen <= 1e-6 ? 1.0 : skew / diagLen;
    final outDy = diagLen <= 1e-6 ? 1.0 : h / diagLen;
    const kappa = 0.5522847498;
    final rawR = cornerRadius;
    final r = math.min(
      rawR,
      math.min(skew * 0.28, math.min(h * 0.22, w * 0.3)),
    );

    context.canvas
      ..moveTo(tlX, tlY)
      ..lineTo(left + w, bottom + h)
      ..lineTo(left + w, bottom);
    if (r > 0.5) {
      final theta = math.acos(outDx.clamp(-1.0, 1.0));
      final t = r / math.tan(theta / 2);
      final arcStartX = blX + t;
      final arcStartY = blY;
      final arcEndX = blX + outDx * t;
      final arcEndY = blY + outDy * t;
      final c1x = arcStartX - kappa * t;
      final c1y = arcStartY;
      final c2x = arcEndX - kappa * outDx * t;
      final c2y = arcEndY - kappa * outDy * t;
      context.canvas
        ..lineTo(arcStartX, arcStartY)
        ..curveTo(c1x, c1y, c2x, c2y, arcEndX, arcEndY)
        ..lineTo(tlX, tlY);
    } else {
      context.canvas..lineTo(left, bottom);
    }
    context.canvas..closePath();

    if (clipOnly) {
      context.canvas.clipPath();
    } else {
      context.canvas.fillPath();
    }
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final c = child;
    if (c == null) return;
    final b = box!;
    final mat = Matrix4.identity()..translateByDouble(b.left, b.bottom, 0, 1);

    context.canvas
      ..saveContext()
      ..setFillColor(fillColor);
    _drawPath(context, clipOnly: false);
    _drawPath(context, clipOnly: true);
    context.canvas.setTransform(mat);
    c.paint(context);
    context.canvas.restoreContext();
  }
}

String _normalizeAbilityTextPdf(String text) {
  if (text.isEmpty) return '';
  final normalized = text.replaceAll('\r\n', '\n');
  final blocks = <String>[];
  final lines = normalized.split('\n');
  final current = StringBuffer();

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      final chunk = current.toString().trim();
      if (chunk.isNotEmpty) blocks.add(chunk);
      current.clear();
      continue;
    }

    if (current.isNotEmpty) {
      final prev = current.toString().trimRight();
      final startsNewThought =
          RegExp(r'[.!?]"?$').hasMatch(prev) &&
          RegExp(r'^[A-Z(]').hasMatch(line);
      if (startsNewThought) {
        blocks.add(prev);
        current.clear();
      } else {
        current.write(' ');
      }
    }
    current.write(line.replaceAll(RegExp(r'\s+'), ' '));
  }

  final trailing = current.toString().trim();
  if (trailing.isNotEmpty) blocks.add(trailing);
  return blocks.join('\n\n');
}

Future<Uint8List> buildCharacterPdfBytes(Character c, MergedRules rules) async {
  final fonts = await _loadPdfFontPack();
  final doc = pw.Document(
    title: 'Panic at the Dojo - Character',
    theme: pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      italic: fonts.italic,
      boldItalic: fonts.boldItalic,
      fontFallback: [fonts.regular],
    ),
  );

  pw.TextStyle style({
    double size = 10,
    PdfColor? color,
    bool bold = false,
    bool italic = false,
    double? height,
    double lineSpacing = 0,
  }) {
    final pw.Font font;
    if (bold && italic) {
      font = fonts.boldItalic;
    } else if (bold) {
      font = fonts.bold;
    } else if (italic) {
      font = fonts.italic;
    } else {
      font = fonts.regular;
    }
    return pw.TextStyle(
      font: font,
      fontSize: size,
      color: color ?? _PdfPalette.ink,
      height: height,
      lineSpacing: lineSpacing,
    );
  }

  pw.Widget archetypeRibbonPdf(CharacterSheetPresenter presenter) {
    return pw.LayoutBuilder(
      builder: (ctx, cons) {
        final ht = c.heroType;
        final ribbonStyle = style(
          size: 9.8,
          bold: true,
          color: PdfColors.white,
        );
        final slashStyle = style(size: 9.8, bold: true, color: PdfColors.white);

        pw.Widget txt(String s) =>
            pw.Text(normalizePdfTextForHelvetica(s), style: ribbonStyle);

        final rowChildren = <pw.Widget>[
          txt(presenter.buildBannerLabel(c)),
          pw.SizedBox(width: 8),
          if (ht == HeroTypeKind.frantic)
            txt('Frantic Hero')
          else if (ht == HeroTypeKind.fused) ...[
            txt(presenter.archetypeSlotBannerLabel(c, 0)),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Text('/', style: slashStyle),
            ),
            txt(presenter.archetypeSlotBannerLabel(c, 1)),
          ] else
            txt(presenter.archetypeBannerLabel(c)),
        ];

        final maxW = cons?.maxWidth ?? double.infinity;
        final colW = maxW.isFinite ? maxW : _stanceOrCharacterHalfWidth();
        return pw.Container(
          color: _PdfPalette.purpleBg,
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.SizedBox(
              width: colW * 0.75,
              child: _PdfSkewLeftRibbon(
                fillColor: _PdfPalette.purpleBand,
                child: pw.ConstrainedBox(
                  constraints: pw.BoxConstraints(
                    maxWidth: colW * 0.75,
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(
                      8 + _kRailTextInset,
                      5,
                      8,
                      5,
                    ),
                    child: pw.DefaultTextStyle(
                      style: ribbonStyle,
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: rowChildren,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<pw.Widget> abilityParagraphsWithBadgePdf(
    String ability,
    String badgeName,
    pw.TextStyle bodyStyle,
    pw.TextStyle badgeStyle,
  ) {
    final parts = ability
        .split(RegExp(r'\n\s*\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final out = <pw.Widget>[];
    for (var i = 0; i < parts.length; i++) {
      out.add(
        pw.RichText(
          text: pw.TextSpan(
            style: bodyStyle,
            children: [
              pw.TextSpan(text: normalizePdfTextForHelvetica(parts[i])),
              pw.TextSpan(text: ' ', style: bodyStyle),
              pw.WidgetSpan(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _PdfPalette.purpleBand,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    normalizePdfTextForHelvetica(badgeName),
                    style: badgeStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      if (i < parts.length - 1) {
        out.add(pw.SizedBox(height: 7));
      }
    }
    return out;
  }

  pw.Widget archetypeHintPdf(String message) {
    return pw.Text(
      normalizePdfTextForHelvetica(message),
      style: style(size: 11.8, italic: true),
    );
  }

  pw.Widget franticSlotAbilityPdf(
    CharacterSheetPresenter presenter,
    int slotIndex,
  ) {
    final entries = <({String name, String ability})>[];
    final build = rules.buildById(c.buildId);
    final buildDescription = (build?.description ?? '').trim();
    if (build != null && buildDescription.isNotEmpty) {
      entries.add((
        name: build.name,
        ability: _normalizeAbilityTextPdf(buildDescription),
      ));
    }
    final slotId = c.archetypeIds.length > slotIndex
        ? c.archetypeIds[slotIndex]
        : '';
    if (slotId.isNotEmpty) {
      final arch = rules.archetypeById(slotId);
      if (arch != null) {
        final rawAbility =
            (arch.abilitiesByHeroType[HeroTypeKind.frantic.name] ?? '').trim();
        final ability = _normalizeAbilityTextPdf(rawAbility);
        entries.add((
          name: arch.name,
          ability: ability.isEmpty ? 'No frantic ability text found.' : ability,
        ));
      }
    }
    if (entries.isEmpty) {
      return archetypeHintPdf('Pick a build and archetype to view abilities.');
    }
    final bodyStyle = style(size: 10.6, height: 1.28);
    final badgeStyle = style(
      size: 9.6,
      bold: true,
      color: PdfColors.white,
      height: 1,
    );
    final blocks = <pw.Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) blocks.add(pw.SizedBox(height: 7));
      blocks.addAll(
        abilityParagraphsWithBadgePdf(
          entries[i].ability,
          entries[i].name,
          bodyStyle,
          badgeStyle,
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: blocks,
    );
  }

  pw.Widget franticRibbonForSlotPdf(
    CharacterSheetPresenter presenter,
    int slotIndex,
  ) {
    final buildLabel = presenter.buildBannerLabel(c);
    final archLabel = presenter.archetypeSlotBannerLabel(c, slotIndex);
    final nameStyle = style(size: 9.8, bold: true, color: PdfColors.white);

    return pw.LayoutBuilder(
      builder: (ctx, cons) {
        final maxW = cons?.maxWidth ?? double.infinity;
        final colW = maxW.isFinite ? maxW : _stanceOrCharacterHalfWidth();
        return pw.Container(
          color: _PdfPalette.purpleBg,
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: _PdfSkewLeftRibbon(
              fillColor: _PdfPalette.purpleBand,
              child: pw.ConstrainedBox(
                constraints: pw.BoxConstraints(
                  maxWidth: colW,
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(
                    8 + _kRailTextInset,
                    5,
                    8,
                    5,
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      if (buildLabel.isNotEmpty)
                        pw.Text(
                          normalizePdfTextForHelvetica(buildLabel),
                          style: nameStyle,
                        ),
                      if (buildLabel.isNotEmpty) pw.SizedBox(width: 8),
                      pw.Text(
                        normalizePdfTextForHelvetica(archLabel),
                        style: nameStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  pw.Widget archetypeAbilityBodyPdf(CharacterSheetPresenter presenter) {
    final heroType = c.heroType;
    if (heroType == null) {
      return archetypeHintPdf('Pick a Hero Type to view archetype abilities.');
    }
    if (heroType == HeroTypeKind.frantic) {
      const franticRules =
          'At the start and end of your turn, you may move one space.\n'
          'When you would choose your Stance, instead choose one Frantic Ability, '
          'one Style, and one Form you know to create your Stance for the turn. '
          'You cannot choose an Ability, Style, or Form you used on your previous turn.';
      final parts = franticRules
          .split(RegExp(r'\n\s*\n+'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            pw.Text(
              normalizePdfTextForHelvetica(parts[i]),
              style: style(size: 10.8, height: 1.28),
            ),
            if (i < parts.length - 1) pw.SizedBox(height: 7),
          ],
        ],
      );
    }

    final entries = <({String name, String ability})>[];
    final build = rules.buildById(c.buildId);
    final buildDescription = (build?.description ?? '').trim();
    if (build != null && buildDescription.isNotEmpty) {
      entries.add((
        name: build.name,
        ability: _normalizeAbilityTextPdf(buildDescription),
      ));
    }
    for (final id in c.archetypeIds) {
      if (id.isEmpty) continue;
      final arch = rules.archetypeById(id);
      if (arch == null) continue;
      final rawAbility = (arch.abilitiesByHeroType[heroType.name] ?? '').trim();
      final ability = _normalizeAbilityTextPdf(rawAbility);
      entries.add((
        name: arch.name,
        ability: ability.isEmpty
            ? 'No ${heroType.name} ability text found.'
            : ability,
      ));
    }
    if (entries.isEmpty) {
      if (c.archetypeIds.where((e) => e.isNotEmpty).isEmpty) {
        return archetypeHintPdf(
          'Pick an archetype to view its ${heroType.name} ability.',
        );
      }
      return archetypeHintPdf('No archetype ability text available.');
    }

    final bodyStyle = style(size: 10.6, height: 1.28);
    final badgeStyle = style(
      size: 9.6,
      bold: true,
      color: PdfColors.white,
      height: 1,
    );
    final blocks = <pw.Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) blocks.add(pw.SizedBox(height: 7));
      blocks.addAll(
        abilityParagraphsWithBadgePdf(
          entries[i].ability,
          entries[i].name,
          bodyStyle,
          badgeStyle,
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: blocks,
    );
  }

  pw.Widget skillRibbonPdf({
    required bool alignLeft,
    required String label,
    required pw.TextStyle pillStyle,
  }) {
    final pad = alignLeft
        ? const pw.EdgeInsets.fromLTRB(
            8 + _kRailTextInset,
            3,
            _kSkillRibbonDiagonalReservePdf,
            3,
          )
        : const pw.EdgeInsets.fromLTRB(
            _kSkillRibbonDiagonalReservePdf,
            3,
            8 + _kRailTextInset,
            3,
          );

    final inner = pw.SizedBox(
      height: _kSkillRibbonHeightPdf,
      width: double.infinity,
      child: pw.Padding(
        padding: pad,
        child: pw.Align(
          alignment: alignLeft
              ? pw.Alignment.centerLeft
              : pw.Alignment.centerRight,
          child: pw.Text(
            normalizePdfTextForHelvetica(label),
            style: pillStyle,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.right,
          ),
        ),
      ),
    );

    return alignLeft
        ? _PdfSkewLeftRibbon(
            fillColor: _PdfPalette.pillOrange,
            cornerRadius: 6,
            child: inner,
          )
        : _PdfSkewRightRibbon(
            fillColor: _PdfPalette.pillOrange,
            cornerRadius: 6,
            child: inner,
          );
  }

  pw.Widget characterHalfPage() {
    final presenter = CharacterSheetPresenter(rules);
    final pills = presenter.orangePillLabels(c);
    final displayName = c.characterName.trim().isEmpty
        ? 'Unnamed hero'
        : c.characterName.trim();
    final subtitle = presenter.bannerSubtitle(c.heroType);
    final bannerNameStyle = style(
      size: 15.5,
      bold: true,
      color: PdfColors.white,
      height: 1.15,
    );
    final bannerSubStyle = style(
      size: 11.5,
      italic: true,
      color: PdfColors.white,
      height: 1.15,
    );
    final pillStyle = style(
      size: 9.2,
      bold: true,
      color: PdfColors.white,
      height: 1.15,
    );

    final railSectionChildren = <pw.Widget>[
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: skillRibbonPdf(
              alignLeft: true,
              label: pills[0],
              pillStyle: pillStyle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: skillRibbonPdf(
              alignLeft: false,
              label: pills[1],
              pillStyle: pillStyle,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: skillRibbonPdf(
              alignLeft: true,
              label: pills[2],
              pillStyle: pillStyle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: skillRibbonPdf(
              alignLeft: false,
              label: pills[3],
              pillStyle: pillStyle,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      pdfInnerBoardedBody(
        backgroundColor: _PdfPalette.purpleBg,
        boardColor: _PdfPalette.purpleBorder,
        header: archetypeRibbonPdf(presenter),
        body: archetypeAbilityBodyPdf(presenter),
      ),
      if (c.heroType == HeroTypeKind.frantic)
        for (var slot = 0; slot < 3; slot++) ...[
          pw.SizedBox(height: 5),
          pdfInnerBoardedBody(
            backgroundColor: _PdfPalette.purpleBg,
            boardColor: _PdfPalette.purpleBorder,
            header: franticRibbonForSlotPdf(presenter, slot),
            body: franticSlotAbilityPdf(presenter, slot),
          ),
        ],
      if (c.description.trim().isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Description',
                style: style(size: 7.8, color: _PdfPalette.muted, bold: true),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                normalizePdfTextForHelvetica(c.description.trim()),
                style: style(size: 9.2),
              ),
            ],
          ),
        ),
      ],
    ];

    return pw.Container(
      color: _PdfPalette.sheetField,
      child: pw.Stack(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.LayoutBuilder(
                  builder: (ctx, cons) {
                    return pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: _PdfSkewLeftRibbon(
                        fillColor: _PdfPalette.bannerBrown,
                        cornerRadius: 6,
                        child: pw.Padding(
                          padding: pw.EdgeInsets.fromLTRB(
                            12 + _kRailTextInset,
                            9,
                            14 + _kBannerTrailingReservePdf + _kRailTextInset,
                            9,
                          ),
                          child: pw.ConstrainedBox(
                            constraints: pw.BoxConstraints(
                              maxWidth: cons?.maxWidth ?? double.infinity,
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(displayName, style: bannerNameStyle),
                                pw.SizedBox(width: 8),
                                pw.Text(subtitle, style: bannerSubStyle),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ...railSectionChildren,
              ],
            ),
          ),
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pdfFilledVerticalBar(
              width: _kRailW,
              color: _PdfPalette.sheetAccent,
            ),
          ),
          pw.Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: pdfFilledVerticalBar(
              width: _kRailW,
              color: _PdfPalette.sheetAccent,
            ),
          ),
        ],
      ),
    );
  }

  String trimStyleSuffix(String value) {
    final v = value.trim();
    if (v.toLowerCase().endsWith(' style')) {
      return v.substring(0, v.length - 6).trim();
    }
    return v;
  }

  String trimFormSuffix(String value) {
    final v = value.trim();
    if (v.toLowerCase().endsWith(' form')) {
      return v.substring(0, v.length - 5).trim();
    }
    return v;
  }

  List<String> splitParagraphs(String raw) {
    final normalized = _normalizeAbilityTextPdf(raw.trim());
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  ({
    String header,
    String rangeLabel,
    List<int> dicePool,
    List<({String text, String badge})> passives,
    List<({String title, String body, String badge})> actions,
  })
  stancePageData(int stanceIndex) {
    final stance = stanceIndex < c.stances.length
        ? c.stances[stanceIndex]
        : null;
    final styleRule = rules.styleById(stance?.styleId);
    final formRule = rules.formById(stance?.formId);
    final styleSkill = _pdfResolvedStyleSkill(styleRule, rules);
    final rangeLabel = _pdfStyleRangeLabel(styleRule, styleSkill);
    final dicePool = formDicePoolForForm(formRule);

    final styleLabel = styleRule == null
        ? '(Pick a Style)'
        : trimStyleSuffix(styleRule.name);
    final formRaw = stance?.formDisplayName.trim().isNotEmpty == true
        ? stance!.formDisplayName.trim()
        : (formRule?.name ?? '');
    final formLabel = formRule == null
        ? '(Pick a Form)'
        : trimFormSuffix(formRaw);
    final header = '$styleLabel $formLabel';

    final passives = <({String text, String badge})>[
      if (styleRule != null)
        for (final p in splitParagraphs(
          styleRule.passive.isNotEmpty
              ? styleRule.passive
              : styleRule.description,
        ))
          (text: p, badge: styleLabel),
      if (formRule != null)
        for (final p in splitParagraphs(
          formRule.passive.isNotEmpty ? formRule.passive : formRule.description,
        ))
          (text: p, badge: formLabel),
    ];

    final actions = <({String title, String body, String badge})>[];
    if (styleRule != null) {
      for (final a in styleRule.actions) {
        final heading = a.heading.trim().isNotEmpty
            ? a.heading.trim()
            : styleLabel;
        final body = splitParagraphs(a.description).join('\n\n');
        if (body.isNotEmpty) {
          actions.add((title: heading, body: body, badge: styleLabel));
        }
      }
    }
    if (formRule != null) {
      for (final a in formRule.actions) {
        final heading = a.heading.trim().isNotEmpty
            ? a.heading.trim()
            : formLabel;
        final body = splitParagraphs(a.description).join('\n\n');
        if (body.isNotEmpty) {
          actions.add((title: heading, body: body, badge: formLabel));
        }
      }
    }

    if (passives.isEmpty && actions.isEmpty) {
      return (
        header: header,
        rangeLabel: rangeLabel,
        dicePool: dicePool,
        passives: const [
          (
            text: 'Choose a Style and Form to populate this stance.',
            badge: 'Stance',
          ),
        ],
        actions: const [],
      );
    }

    return (
      header: header,
      rangeLabel: rangeLabel,
      dicePool: dicePool,
      passives: passives,
      actions: actions,
    );
  }

  pw.Widget sourceParagraphWithBadge({
    required String text,
    required String badge,
    required pw.TextStyle textStyle,
    required PdfColor badgeColor,
  }) {
    return pw.RichText(
      text: pw.TextSpan(
        style: textStyle,
        children: [
          pw.TextSpan(text: normalizePdfTextForHelvetica(text)),
          pw.TextSpan(text: ' ', style: textStyle),
          pw.WidgetSpan(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: badgeColor,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                normalizePdfTextForHelvetica(badge),
                style: style(
                  size: 9.2,
                  bold: true,
                  color: PdfColors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget stanceActionSection(
    ({String title, String body, String badge}) section,
  ) {
    final titleStyle = style(
      size: 10.2,
      bold: true,
      color: PdfColors.white,
      height: 1.15,
    );
    final bodyStyle = style(size: 10.2, color: _PdfPalette.ink, height: 1.25);
    final paragraphs = section.body
        .split(RegExp(r'\n\s*\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return pdfInnerBoardedBody(
      backgroundColor: _PdfPalette.stanceActionBg,
      boardColor: _PdfPalette.stanceActionBoard,
      header: pw.LayoutBuilder(
        builder: (ctx, cons) {
          final maxW = cons?.maxWidth ?? double.infinity;
          final colW = maxW.isFinite ? maxW : _stanceOrCharacterHalfWidth();
          return pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.SizedBox(
              width: colW * 0.75,
              height: _kSkillRibbonHeightPdf + 4,
              child: _PdfSkewLeftRibbon(
                fillColor: _PdfPalette.stanceActionTitle,
                cornerRadius: 6,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(
                    10 + _kRailTextInset,
                    4,
                    10 + _kSkillRibbonDiagonalReservePdf,
                    4,
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      normalizePdfTextForHelvetica(section.title),
                      style: titleStyle,
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      body: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            sourceParagraphWithBadge(
              text: paragraphs[i],
              badge: section.badge,
              textStyle: bodyStyle,
              badgeColor: _PdfPalette.stanceActionTitle,
            ),
            if (i < paragraphs.length - 1) pw.SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  pw.Widget stanceDiceRowPdf(List<int> dice) {
    if (dice.isEmpty) return pw.SizedBox();
    final chipStyle = style(size: 10.8, bold: true, color: PdfColors.white);
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        for (var i = 0; i < dice.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 8),
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF4A4A4A),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              normalizePdfTextForHelvetica('${dice[i]}'),
              style: chipStyle,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget stanceRailsOverlay(pw.Widget child) {
    return pw.Stack(
      children: [
        child,
        pw.Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: pdfFilledVerticalBar(
            width: _kRailW,
            color: _PdfPalette.stanceRail,
          ),
        ),
        pw.Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: pdfFilledVerticalBar(
            width: _kRailW,
            color: _PdfPalette.stanceRail,
          ),
        ),
      ],
    );
  }

  pw.Widget stanceInnerColumn(int stanceIndex) {
    final data = stancePageData(stanceIndex);
    final headerStyle = style(
      size: 13.6,
      bold: true,
      color: _PdfPalette.ink,
      height: 1.1,
    );
    final rangeStyle = style(
      size: 10.4,
      bold: true,
      color: _PdfPalette.ink,
      height: 1.15,
    );
    final passiveStyle = style(
      size: 10.6,
      color: _PdfPalette.ink,
      height: 1.25,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.LayoutBuilder(
          builder: (ctx, cons) {
            final maxW = cons?.maxWidth ?? double.infinity;
            final colW = maxW.isFinite ? maxW : _stanceOrCharacterHalfWidth();
            final ribbonW = colW * 0.75;
            final dice = data.dicePool;
            final ribbon = pw.SizedBox(
              width: ribbonW,
              child: _PdfSkewLeftRibbon(
                fillColor: _PdfPalette.stanceTitle,
                cornerRadius: 6,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(
                    10 + _kRailTextInset,
                    8,
                    10 + _kStanceTitleRibbonDiagonalReservePdf,
                    8,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        normalizePdfTextForHelvetica(data.header),
                        style: headerStyle,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        normalizePdfTextForHelvetica(data.rangeLabel),
                        style: rangeStyle,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (dice.isEmpty) {
              return pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: ribbon,
              );
            }

            // Full-width stack so dice anchor from the inner edge (not squeezed past the rail).
            // Chips may overlap the ribbon on the left; [right] inset keeps them off the border.
            return pw.SizedBox(
              width: colW,
              child: pw.Stack(
                children: [
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: ribbon,
                  ),
                  pw.Positioned(
                    top: 4,
                    right: _kStanceDiceHeaderRightInset,
                    child: stanceDiceRowPdf(dice),
                  ),
                ],
              ),
            );
          },
        ),
        pw.Padding(
          padding: pw.EdgeInsets.fromLTRB(
            _kInnerBoardTextPaddingLR,
            8,
            _kInnerBoardTextPaddingLR,
            8,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < data.passives.length; i++) ...[
                sourceParagraphWithBadge(
                  text: data.passives[i].text,
                  badge: data.passives[i].badge,
                  textStyle: passiveStyle,
                  badgeColor: _PdfPalette.stanceActionTitle,
                ),
                if (i < data.passives.length - 1) pw.SizedBox(height: 6),
              ],
            ],
          ),
        ),
        for (var i = 0; i < data.actions.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 8),
          stanceActionSection(data.actions[i]),
        ],
      ],
    );
  }

  pw.Widget stanceHalfPage(int stanceIndex) {
    return pw.Container(
      color: _PdfPalette.stanceBody,
      child: stanceRailsOverlay(
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: stanceInnerColumn(stanceIndex),
        ),
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: halfLetterLandscape,
      build: (ctx) => pw.Container(
        color: _PdfPalette.paper,
        padding: const pw.EdgeInsets.all(_kOuterMargin),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(child: characterHalfPage()),
            pw.SizedBox(width: _halfGap),
            pw.Expanded(child: stanceHalfPage(0)),
          ],
        ),
      ),
    ),
  );

  doc.addPage(
    pw.Page(
      pageFormat: halfLetterLandscape,
      build: (ctx) => pw.Container(
        color: _PdfPalette.paper,
        padding: const pw.EdgeInsets.all(_kOuterMargin),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(child: stanceHalfPage(1)),
            pw.SizedBox(width: _halfGap),
            pw.Expanded(child: stanceHalfPage(2)),
          ],
        ),
      ),
    ),
  );

  return doc.save();
}
