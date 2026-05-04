import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../data/stance_form_display.dart';
import 'form_dice_catalog.dart';
import 'rule_violation_marker.dart';
import 'rulebook_action_option_text.dart';
import 'rulebook_form_palette.dart';
import 'rulebook_ribbon_header_typography.dart';
import 'rulebook_section_template.dart';
import 'rulebook_stance_chrome.dart';

/// Frantic **form** card using [RulebookSectionTemplate]: violet shell, dice upper-right,
/// passive copy in the main well, tiered actions as green subs ([RulebookStanceChrome.stance]
/// action ramp — same as stance subs).
class FranticFormSection extends StatelessWidget {
  const FranticFormSection({
    super.key,
    required this.form,
    required this.rules,
    this.formDisplayLabel,
    this.formChoiceId,
    this.onPickForm,
    this.ruleViolationHint,
  });

  final RuleForm? form;
  final MergedRules rules;

  /// Overrides [RuleForm.name] in the ribbon when non-empty (alternate form label).
  final String? formDisplayLabel;

  /// Selected [RuleFormChoice.id] for this stance’s form (Frantic layout).
  final String? formChoiceId;
  final VoidCallback? onPickForm;

  /// Hover tooltip when this form choice breaks printed stance rules.
  final String? ruleViolationHint;

  static const double _diceChipSize = 66;
  static const double _diceSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final layoutW = MediaQuery.sizeOf(context).width;
    final ribbonTypo = RulebookRibbonHeaderTypography.forWidth(layoutW);
    final wellBodyStyle = TextStyle(
      color: Colors.black,
      fontSize: ribbonTypo.stanceWellBodyFontSize,
      height: 1.35,
    );
    final actionRibbonTitleStyle = TextStyle(
      color: Colors.white,
      fontSize: ribbonTypo.actionRibbonTitleFontSize,
      fontWeight: FontWeight.w800,
      height: 1.25,
    );
    final chrome = RulebookStanceChrome.stance;
    final dm = _formDisplayModel(
      form,
      rules,
      formChoiceId: formChoiceId,
      fullFormChoicePassive: true,
    );
    final badge = switch (form) {
      null => 'Form',
      final f => _trimFormSuffix(_rawFormLabel(f, formDisplayLabel)),
    };

    final titleText = switch (form) {
      null => '(Pick a Form)',
      final f => _trimFormSuffix(_rawFormLabel(f, formDisplayLabel)),
    };

    final diceRow = _diceUpperRight(form);

    final passiveWidgets = _buildPassiveWidgets(dm, badge, wellBodyStyle);
    final mainBody =
        passiveWidgets ??
        (form == null
            ? Text(
                'Tap the title above to choose a form after picking a style.',
                style: wellBodyStyle.copyWith(color: Colors.black54),
              )
            : null);

    final subs = _buildActionSubSections(
      dm,
      form,
      badge,
      chrome,
      wellBodyStyle: wellBodyStyle,
      actionRibbonTitleStyle: actionRibbonTitleStyle,
    );

    final model = RulebookSectionTemplateModel(
      mainLateralBorder: const RulebookTemplateLateralBorder(
        color: RulebookFormPalette.lateralRail,
      ),
      mainBackground: RulebookFormPalette.bodyBackground,
      mainRibbonStyle: const RulebookTemplateRibbonStyle(
        fill: RulebookFormPalette.ribbon,
        minHeight: 52,
        diagonalReserve: 66,
        padding: EdgeInsets.fromLTRB(12, 10, 66, 10),
      ),
      mainRibbonTitle: _ribbonTitle(titleText, ribbonTypo, layoutW),
      upperRight: diceRow,
      mainBody: mainBody,
      subSections: subs,
    );

    return RulebookSectionTemplate(model: model);
  }

  Widget _ribbonTitle(
    String text,
    RulebookRibbonHeaderTypography typo,
    double layoutWidth,
  ) {
    final style = TextStyle(
      fontSize: typo.titleFontSize,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: Colors.white,
    );
    final hint = ruleViolationHint;
    final tap = onPickForm;
    final label = Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
    if (tap == null) {
      if (hint == null) {
        return label;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RuleViolationTriangle(message: hint),
          const SizedBox(width: 6),
          Expanded(child: label),
        ],
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hint != null) ...[
              RuleViolationTriangle(message: hint),
              const SizedBox(width: 4),
            ],
            Expanded(child: label),
            SizedBox(width: layoutWidth < 400 ? 4 : 6),
            Icon(
              Icons.edit_outlined,
              size: typo.editIconSize,
              color: const Color(0xE6FFFFFF),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _diceUpperRight(RuleForm? f) {
    if (f == null) return null;
    final dice = formDicePoolForForm(f);
    if (dice.isEmpty) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < dice.length; i++) ...[
          if (i > 0) const SizedBox(width: _diceSpacing),
          formDieChip(dice[i], size: _diceChipSize),
        ],
      ],
    );
  }

  Widget? _buildPassiveWidgets(
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      List<({String text, String badge})>? fallbackAttributed,
    })
    dm,
    String badge,
    TextStyle wellBodyStyle,
  ) {
    final paras = dm.passiveParagraphs;
    if (paras.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paras.length; i++) ...[
          Text(paras[i], style: wellBodyStyle),
          if (i < paras.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        _sourceBadge(badge),
      ],
    );
  }

  List<RulebookTemplateSubSection> _buildActionSubSections(
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      List<({String text, String badge})>? fallbackAttributed,
    })
    dm,
    RuleForm? f,
    String badge,
    RulebookStanceChrome chrome, {
    required TextStyle wellBodyStyle,
    required TextStyle actionRibbonTitleStyle,
  }) {
    if (f == null) return const [];
    final out = <RulebookTemplateSubSection>[];

    final ribbonStyle = RulebookTemplateRibbonStyle(
      fill: chrome.actionTitleGreen,
      minHeight: 44,
      diagonalReserve: 58,
      padding: const EdgeInsets.fromLTRB(14, 8, 58, 8),
    );

    final lateral = RulebookTemplateLateralBorder(
      color: chrome.actionSideBorderGreen,
    );

    for (final a in dm.actions) {
      final title = a.heading.trim().isNotEmpty
          ? a.heading.trim()
          : _formActionHeading(f);
      final paras = splitRuleParagraphs(a.description.trim());
      final body = paras.isEmpty
          ? const SizedBox.shrink()
          : _paragraphsWithSource(
              paras,
              badge,
              singleCitation: true,
              wellBodyStyle: wellBodyStyle,
            );
      out.add(
        RulebookTemplateSubSection(
          lateralBorder: lateral,
          background: chrome.actionDescriptionBg,
          ribbonStyle: ribbonStyle,
          ribbonTitle: Text(title, style: actionRibbonTitleStyle),
          ribbonWidthFactor: 0.8,
          body: body,
        ),
      );
    }

    final fb = dm.fallbackAttributed;
    if (fb != null && fb.isNotEmpty) {
      out.add(
        RulebookTemplateSubSection(
          lateralBorder: lateral,
          background: chrome.actionDescriptionBg,
          ribbonStyle: ribbonStyle,
          ribbonTitle: Text(
            _formActionHeading(f),
            style: actionRibbonTitleStyle,
          ),
          ribbonWidthFactor: 0.8,
          body: _attributedParagraphBadges(
            fb,
            singleCitation: true,
            wellBodyStyle: wellBodyStyle,
          ),
        ),
      );
    }

    return out;
  }

  Widget _sourceBadge(String source) {
    const badgeYellow = Color(0xFF9A8E1E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeYellow,
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
    required bool singleCitation,
    required TextStyle wellBodyStyle,
  }) {
    if (paragraphs.isEmpty) return const SizedBox.shrink();
    if (singleCitation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            rulebookActionOptionParagraph(paragraphs[i], wellBodyStyle),
            if (i < paragraphs.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _sourceBadge(source),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          RichText(
            text: TextSpan(
              style: wellBodyStyle,
              children: [
                TextSpan(text: paragraphs[i]),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _sourceBadge(source),
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
    required bool singleCitation,
    required TextStyle wellBodyStyle,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final badgeLabel = items.first.badge;
    if (singleCitation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            rulebookActionOptionParagraph(items[i].text, wellBodyStyle),
            if (i < items.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _sourceBadge(badgeLabel),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          RichText(
            text: TextSpan(
              style: wellBodyStyle,
              children: [
                ...rulebookActionOptionInlineSpans(
                  items[i].text,
                  wellBodyStyle,
                ),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _sourceBadge(items[i].badge),
                ),
              ],
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

String _rawFormLabel(RuleForm form, String? formDisplayLabel) {
  if (formDisplayLabel != null && formDisplayLabel.trim().isNotEmpty) {
    return formDisplayLabel.trim();
  }
  return form.name;
}

String _trimFormSuffix(String name) => name.replaceAll(RegExp(r'\s+Form$'), '');

String _formPassiveLine(RuleForm f) {
  final p = f.passive.trim();
  if (p.isNotEmpty) return p;
  if (f.actions.isNotEmpty) return f.description.trim();
  return '';
}

({
  List<String> passiveParagraphs,
  List<RuleFormAction> actions,
  List<({String text, String badge})>? fallbackAttributed,
})
_formDisplayModel(
  RuleForm? f,
  MergedRules r, {
  String? formChoiceId,
  required bool fullFormChoicePassive,
}) {
  if (f == null) {
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
    List<String> passiveParagraphs;
    if (f.choices.isNotEmpty) {
      passiveParagraphs = formPassiveParagraphsForDisplay(
        f,
        formChoiceId,
        fullChoiceText: fullFormChoicePassive,
      );
      if (passiveParagraphs.isEmpty && passiveLine.isNotEmpty) {
        passiveParagraphs = splitRuleParagraphs(passiveLine);
      }
    } else {
      passiveParagraphs = passiveLine.isEmpty
          ? const []
          : splitRuleParagraphs(passiveLine);
    }
    return (
      passiveParagraphs: passiveParagraphs,
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
    final paras = splitRuleParagraphs(desc);
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

String _formActionHeading(RuleForm form) {
  final words = _trimFormSuffix(form.name);
  return '$words Action';
}
