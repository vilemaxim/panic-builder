import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import 'form_dice_catalog.dart';
import 'rulebook_ribbon_clipper.dart';
import 'stance_rules_tooltip.dart';

class RulebookStancePanel extends StatelessWidget {
  const RulebookStancePanel({
    super.key,
    required this.style,
    required this.form,
    this.rules,
    this.formDisplayLabel,
    this.onPickStyle,
    this.onPickForm,
  });

  final RuleStyle? style;
  final RuleForm? form;

  /// Overrides [RuleForm.name] in headers/citations (e.g. alternate form name from stance).
  final String? formDisplayLabel;

  /// When non-null, form skill descriptions are shown in the Form info tooltip.
  final MergedRules? rules;
  final VoidCallback? onPickStyle;
  final VoidCallback? onPickForm;

  static const Color _titleYellow = Color(0xFFC8D53D);
  static const Color _bodyYellow = Color(0xFFEFF2B8);
  static const Color _actionTitleGreen = Color(0xFF177E2B);

  /// Softer green for action side strokes (ribbon fill stays [_actionTitleGreen]).
  static const Color _actionSideBorderGreen = Color(0xFF5CBF78);

  /// Full action block fill (ribbon row + description); dark ribbon paints on top.
  static const Color _actionDescriptionBg = Color(0xFFC5E5D5);
  static const Color _sourceBadgeYellow = Color(0xFF9A8E1E);

  /// Action title ribbon width as a fraction of the stance panel content width.
  static const double _actionRibbonWidthFactor = 0.75;

  /// Matches clipped archetype ribbons; taller than skill pills for 22px titles.
  static const double _actionTitleRibbonMinHeight = 44;

  static const TextStyle _actionRibbonTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  /// Clears [LeftRibbonClipper]'s diagonal at the bottom-right (skew ≈ ribbon height).
  static const double _actionRibbonDiagonalReserve =
      _actionTitleRibbonMinHeight + 14;

  /// Combined Style + Form title ribbon (large tap targets).
  static const double _titleHeaderRibbonMinHeight = 52;

  /// Keeps header copy clear of the clipped diagonal (~skew ≈ height).
  static const double _titleRibbonDiagonalReserve =
      _titleHeaderRibbonMinHeight + 14;

  /// Title ribbon vs dice column when dice are shown (~80% / ~20%).
  static const int _titleRibbonFlexWithDice = 4;
  static const int _titleDiceFlexWithDice = 1;

  /// Painted stance dice (default chip 44px + 50%).
  static const double _stanceDiceChipSize = 66;

  static const double _stanceDiceSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final styleName = style == null
        ? '(Pick a Style)'
        : _trimStyleSuffix(style!.name);
    final rawFormLabel = form == null
        ? ''
        : (formDisplayLabel != null && formDisplayLabel!.trim().isNotEmpty)
        ? formDisplayLabel!.trim()
        : form!.name;
    final formName = form == null
        ? '(Pick a Form)'
        : _trimFormSuffix(rawFormLabel);
    final styleSkill = _resolvedStyleSkill(style, rules);
    final rangeText = _styleRangeLabel(style, styleSkill);
    final styleCitationBadge = style == null
        ? 'Style'
        : _trimStyleSuffix(style!.name);
    final formCitationBadge = form == null
        ? 'Form'
        : _trimFormSuffix(rawFormLabel);
    final styleDm = _styleDisplayModel(style, styleSkill);
    final formDm = _formDisplayModel(form, rules);

    final styleActionWidgets = _styleActionSections(style, styleSkill, styleDm);
    final formActionWidgets = _formActionSections(
      form,
      formDm,
      formCitationBadge,
    );
    final hasActionsBelow =
        styleActionWidgets.isNotEmpty || formActionWidgets.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: _bodyYellow,
        border: Border(
          left: BorderSide(color: Color(0xFFF5D96D), width: 6),
          right: BorderSide(color: Color(0xFFF5D96D), width: 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBar(
            styleName,
            formName,
            rangeText,
            styleCitationBadge,
            formCitationBadge,
            styleDm,
            formDm,
            hasActionsBelow: hasActionsBelow,
          ),
          for (var i = 0; i < styleActionWidgets.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            styleActionWidgets[i],
          ],
          if (styleActionWidgets.isNotEmpty && formActionWidgets.isNotEmpty)
            const SizedBox(height: 8),
          for (var i = 0; i < formActionWidgets.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            formActionWidgets[i],
          ],
        ],
      ),
    );
  }

  RuleSkill? _resolvedStyleSkill(RuleStyle? st, MergedRules? r) {
    if (st == null || r == null) return null;
    final id = st.skillId;
    if (id == null || id.isEmpty) return null;
    return r.skillById(id);
  }

  /// Passive paragraphs and tiered actions from card fields; otherwise fallback blob for skills.
  ({
    List<String> passiveParagraphs,
    List<RuleFormAction> actions,
    String? fallbackBody,
  })
  _styleDisplayModel(RuleStyle? st, RuleSkill? skill) {
    if (st == null) {
      return (
        passiveParagraphs: const [],
        actions: const [],
        fallbackBody: null,
      );
    }
    final passive = st.passive.trim();
    final structured = passive.isNotEmpty || st.actions.isNotEmpty;
    if (structured) {
      return (
        passiveParagraphs: passive.isEmpty
            ? const []
            : _splitParagraphs(passive),
        actions: st.actions,
        fallbackBody: null,
      );
    }
    final fb = _styleRulesBodyFallback(st, skill).trim();
    return (
      passiveParagraphs: const [],
      actions: const [],
      fallbackBody: fb.isEmpty ? null : fb,
    );
  }

  ({
    List<String> passiveParagraphs,
    List<RuleFormAction> actions,
    List<({String text, String badge})>? fallbackAttributed,
  })
  _formDisplayModel(RuleForm? f, MergedRules? r) {
    if (f == null || r == null) {
      return (
        passiveParagraphs: const [],
        actions: const [],
        fallbackAttributed: null,
      );
    }
    final badge = _trimFormSuffix(f.name);
    final passiveLine = _formPassiveLine(f);
    final structured = passiveLine.isNotEmpty || f.actions.isNotEmpty;
    if (structured) {
      return (
        passiveParagraphs: passiveLine.isEmpty
            ? const []
            : _splitParagraphs(passiveLine),
        actions: f.actions,
        fallbackAttributed: null,
      );
    }
    final items = _formFallbackAttributedItems(f, r, badge);
    return (
      passiveParagraphs: const [],
      actions: const [],
      fallbackAttributed: items,
    );
  }

  String _formPassiveLine(RuleForm f) {
    final p = f.passive.trim();
    if (p.isNotEmpty) return p;
    if (f.actions.isNotEmpty) return f.description.trim();
    return '';
  }

  List<({String text, String badge})> _formFallbackAttributedItems(
    RuleForm f,
    MergedRules r,
    String badge,
  ) {
    final out = <({String text, String badge})>[];
    for (final id in f.skillIds) {
      final sk = r.skillById(id);
      if (sk == null) continue;
      final desc = sk.description.trim();
      if (desc.isEmpty) {
        final label = sk.name.trim().isEmpty ? id : sk.name.trim();
        out.add((text: label, badge: badge));
        continue;
      }
      final paras = _splitParagraphs(desc);
      if (paras.isEmpty) {
        out.add((text: desc, badge: badge));
      } else {
        for (final p in paras) {
          out.add((text: p, badge: badge));
        }
      }
    }
    if (out.isEmpty) {
      return [(text: '${f.name} — skills not loaded.', badge: badge)];
    }
    return out;
  }

  List<Widget> _styleActionSections(
    RuleStyle? st,
    RuleSkill? skill,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      String? fallbackBody,
    })
    dm,
  ) {
    if (st == null) return const [];
    final badge = _trimStyleSuffix(st.name);
    final sections = <Widget>[];
    for (final a in dm.actions) {
      final title = a.heading.trim().isNotEmpty
          ? a.heading.trim()
          : _styleActionHeading(st, skill);
      final paras = _splitParagraphs(a.description.trim());
      final body = paras.isEmpty
          ? const SizedBox.shrink()
          : _paragraphsWithSource(paras, badge, singleCitation: true);
      sections.add(_actionSection(title: title, body: body));
    }
    final fb = dm.fallbackBody;
    if (fb != null && fb.isNotEmpty) {
      sections.add(
        _actionSection(
          title: _styleActionHeading(st, skill),
          body: _paragraphsWithSource(
            _splitParagraphs(fb),
            badge,
            singleCitation: true,
          ),
        ),
      );
    }
    return sections;
  }

  List<Widget> _formActionSections(
    RuleForm? f,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      List<({String text, String badge})>? fallbackAttributed,
    })
    dm,
    String formBadge,
  ) {
    if (f == null) return const [];
    final sections = <Widget>[];
    for (final a in dm.actions) {
      final title = a.heading.trim().isNotEmpty
          ? a.heading.trim()
          : _formActionHeading(f);
      final paras = _splitParagraphs(a.description.trim());
      final body = paras.isEmpty
          ? const SizedBox.shrink()
          : _paragraphsWithSource(paras, formBadge, singleCitation: true);
      sections.add(_actionSection(title: title, body: body));
    }
    final fb = dm.fallbackAttributed;
    if (fb != null && fb.isNotEmpty) {
      sections.add(
        _actionSection(
          title: _formActionHeading(f),
          body: _attributedParagraphBadges(fb, singleCitation: true),
        ),
      );
    }
    return sections;
  }

  String _styleRulesBodyFallback(RuleStyle? st, RuleSkill? skill) {
    if (skill != null && skill.description.trim().isNotEmpty) {
      return skill.description.trim();
    }
    if (st == null) return '';
    return '${st.basicInfo}\n\n${st.marginNotes}'.trim();
  }

  Widget _buildTitleBar(
    String styleName,
    String formName,
    String rangeText,
    String styleCitationBadge,
    String formCitationBadge,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      String? fallbackBody,
    })
    styleDm,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      List<({String text, String badge})>? fallbackAttributed,
    })
    formDm, {
    required bool hasActionsBelow,
  }) {
    final notes = style?.marginNotes.trim() ?? '';
    final hasPassives =
        styleDm.passiveParagraphs.isNotEmpty ||
        formDm.passiveParagraphs.isNotEmpty ||
        notes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title ribbon flush with top of stance panel; row uses [start] so dice
        // height does not vertically center the ribbon.
        LayoutBuilder(
          builder: (context, constraints) {
            final diceRow = _diceWidgetsForForm(form);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: diceRow.isEmpty ? 1 : _titleRibbonFlexWithDice,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ClipPath(
                      clipper: const LeftRibbonClipper(
                        topRightRadius: kRulebookRibbonCornerRadius,
                      ),
                      child: ColoredBox(
                        color: _titleYellow,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _titleHeaderRibbonMinHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              10,
                              _titleRibbonDiagonalReserve,
                              10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Tooltip(
                                      message: style == null
                                          ? 'Tap to pick a style for this stance. Full rules text appears once you choose.'
                                          : stanceStyleRulesBody(style!, rules),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      preferBelow: true,
                                      waitDuration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: _editableHeaderPart(
                                        styleName,
                                        onPickStyle,
                                      ),
                                    ),
                                    Tooltip(
                                      message: form == null
                                          ? 'Pick a style first, then tap here to choose a form.'
                                          : rules != null
                                          ? stanceFormRulesBody(form!, rules!)
                                          : _formTooltipWithoutRules(form!),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      preferBelow: true,
                                      waitDuration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: _editableHeaderPart(
                                        formName,
                                        onPickForm,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rangeText,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (diceRow.isNotEmpty)
                  Expanded(
                    flex: _titleDiceFlexWithDice,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < diceRow.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(width: _stanceDiceSpacing),
                                diceRow[i],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Padding(
          padding: (hasPassives || !hasActionsBelow)
              ? const EdgeInsets.fromLTRB(14, 12, 14, 14)
              : EdgeInsets.zero,
          child: _passiveAbilitiesSection(
            style,
            styleCitationBadge,
            formCitationBadge,
            styleDm,
            formDm,
            hasActionsBelow: hasActionsBelow,
          ),
        ),
      ],
    );
  }

  Widget _passiveAbilitiesSection(
    RuleStyle? ruleStyle,
    String styleCitationBadge,
    String formCitationBadge,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      String? fallbackBody,
    })
    styleDm,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      List<({String text, String badge})>? fallbackAttributed,
    })
    formDm, {
    required bool hasActionsBelow,
  }) {
    final notes = ruleStyle?.marginNotes.trim() ?? '';
    final stylePass = styleDm.passiveParagraphs;
    final formPass = formDm.passiveParagraphs;
    final hasPassives =
        stylePass.isNotEmpty || formPass.isNotEmpty || notes.isNotEmpty;

    if (!hasPassives && hasActionsBelow) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stylePass.isNotEmpty) ...[
          _paragraphsWithSource(stylePass, styleCitationBadge),
          if (formPass.isNotEmpty || notes.isNotEmpty)
            const SizedBox(height: 12),
        ],
        if (formPass.isNotEmpty) ...[
          _paragraphsWithSource(formPass, formCitationBadge),
          if (notes.isNotEmpty) const SizedBox(height: 12),
        ],
        if (notes.isNotEmpty)
          Text(
            notes,
            style: const TextStyle(
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        if (!hasPassives && !hasActionsBelow) const SizedBox(height: 48),
      ],
    );
  }

  String _formTooltipWithoutRules(RuleForm f) {
    final alt = f.altNames.where((e) => e.trim().isNotEmpty).join(', ');
    final buf = StringBuffer(f.name.trim());
    if (alt.isNotEmpty) buf.writeln('\nAlso known as: $alt.');
    buf.writeln('\nSkills: ${f.skillIds.join(', ')}');
    return buf.toString().trim();
  }

  Widget _editableHeaderPart(String text, VoidCallback? onTap) {
    const headerStyle = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: Colors.black,
    );
    if (onTap == null) {
      return Text(text, style: headerStyle, softWrap: true);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(text, style: headerStyle, softWrap: true),
            const Icon(Icons.edit_outlined, size: 24, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  /// Full-width green header strip with trailing inset sized to ribbon height so the slash clip does not eat glyphs.
  Widget _actionRibbonTitle(String title) {
    const padL = 14.0;
    const padT = 8.0;
    const padB = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOuterW =
            constraints.maxWidth.isFinite && constraints.maxWidth > 8
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final ribbonW = maxOuterW * _actionRibbonWidthFactor;
        var padR = _actionRibbonDiagonalReserve;
        var textHeight = 22.0;
        for (var i = 0; i < 6; i++) {
          final maxTextW = math.max(40.0, ribbonW - padL - padR);
          final tp = TextPainter(
            text: TextSpan(text: title, style: _actionRibbonTitleStyle),
            textDirection: Directionality.of(context),
          )..layout(maxWidth: maxTextW);
          textHeight = tp.height;
          final ribbonH = math.max(
            _actionTitleRibbonMinHeight,
            textHeight + padT + padB,
          );
          final neededReserve = ribbonH + 14;
          final upper = math.max(
            ribbonW - padL - 40,
            _actionRibbonDiagonalReserve,
          );
          final nextPadR = math.min(neededReserve, upper);
          if ((nextPadR - padR).abs() < 0.5) {
            padR = nextPadR;
            break;
          }
          padR = nextPadR;
        }

        final minRibbonH = math.max(
          _actionTitleRibbonMinHeight,
          textHeight + padT + padB,
        );

        final ribbon = ClipPath(
          clipper: const LeftRibbonClipper(
            topRightRadius: kRulebookRibbonCornerRadius,
          ),
          child: ColoredBox(
            color: _actionTitleGreen,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minRibbonH),
              child: Padding(
                padding: EdgeInsets.fromLTRB(padL, padT, padR, padB),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    softWrap: true,
                    style: _actionRibbonTitleStyle,
                  ),
                ),
              ),
            ),
          ),
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: ribbonW, child: ribbon),
        );
      },
    );
  }

  Widget _actionSection({required String title, required Widget body}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _actionDescriptionBg,
        border: Border(
          left: BorderSide(color: _actionSideBorderGreen, width: 6),
          right: BorderSide(color: _actionSideBorderGreen, width: 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _actionRibbonTitle(title),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: body,
          ),
        ],
      ),
    );
  }

  static const TextStyle _stanceBodyStyle = TextStyle(
    color: Colors.black,
    fontSize: 22,
    height: 1.2,
  );

  Widget _stanceSourceBadge(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _sourceBadgeYellow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _paragraphsWithSource(
    List<String> paragraphs,
    String source, {
    bool singleCitation = false,
  }) {
    if (paragraphs.isEmpty) {
      return const SizedBox.shrink();
    }
    if (singleCitation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            Text(paragraphs[i], style: _stanceBodyStyle),
            if (i < paragraphs.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _stanceSourceBadge(source),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          RichText(
            text: TextSpan(
              style: _stanceBodyStyle,
              children: [
                TextSpan(text: paragraphs[i]),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _stanceSourceBadge(source),
                ),
              ],
            ),
          ),
          if (i < paragraphs.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _attributedParagraphBadges(
    List<({String text, String badge})> items, {
    bool singleCitation = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final badgeLabel = items.first.badge;
    if (singleCitation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Text(items[i].text, style: _stanceBodyStyle),
            if (i < items.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _stanceSourceBadge(badgeLabel),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          RichText(
            text: TextSpan(
              style: _stanceBodyStyle,
              children: [
                TextSpan(text: items[i].text),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _stanceSourceBadge(items[i].badge),
                ),
              ],
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<String> _splitParagraphs(String text) {
    final t = text.replaceAll('\r', '').trim();
    if (t.isEmpty) return const [];
    return t
        .split(RegExp(r'\n\s*\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _trimStyleSuffix(String name) =>
      name.replaceAll(RegExp(r'\s+Style$'), '');
  String _trimFormSuffix(String name) =>
      name.replaceAll(RegExp(r'\s+Form$'), '');

  String _styleRangeLabel(RuleStyle? style, RuleSkill? skill) {
    if (style == null) return 'Range: —';
    final r = style.range.trim();
    if (r.isNotEmpty) return 'Range: $r';
    final merged = skill != null && skill.description.trim().isNotEmpty
        ? skill.description
        : '${style.basicInfo}\n${style.marginNotes}';
    final m = RegExp(
      r'Range:\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(merged);
    if (m != null) return 'Range: ${m.group(1)!.trim()}';
    return 'Range: —';
  }

  String _styleActionHeading(RuleStyle? style, RuleSkill? skill) {
    if (style == null) return 'Style Action';
    final n = skill?.name.trim();
    if (n != null && n.isNotEmpty) return '$n Action';
    final words = _trimStyleSuffix(style.name);
    return '$words Action';
  }

  String _formActionHeading(RuleForm? form) {
    if (form == null) return 'Form Action';
    final words = _trimFormSuffix(form.name);
    return '$words Action';
  }

  List<Widget> _diceWidgetsForForm(RuleForm? form) {
    if (form == null) return const [];
    final dice = formDicePoolForForm(form);
    return dice.map((d) => formDieChip(d, size: _stanceDiceChipSize)).toList();
  }
}
