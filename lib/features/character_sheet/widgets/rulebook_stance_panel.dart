import 'package:flutter/material.dart';

import '../../../data/rulebook_style_range.dart';
import '../../../data/rules_models.dart';
import '../../../data/stance_form_display.dart';
import '../../../domain/hero_type_kind.dart';
import 'form_dice_catalog.dart';
import 'rule_violation_marker.dart';
import 'rulebook_action_option_text.dart';
import 'rulebook_asset_sheet_decor.dart';
import 'rulebook_ribbon_header_typography.dart';
import 'rulebook_section_template.dart';
import 'rulebook_stance_chrome.dart';
import 'stance_rules_tooltip.dart';

class RulebookStancePanel extends StatelessWidget {
  const RulebookStancePanel({
    super.key,
    required this.style,
    required this.form,
    this.rules,
    this.formDisplayLabel,
    this.formChoiceId,
    this.heroType,
    this.onPickStyle,
    this.onPickForm,
    this.chrome = RulebookStanceChrome.stance,
    this.styleOnly = false,
    this.ruleViolationHint,
  });

  final RuleStyle? style;
  final RuleForm? form;

  /// Overrides [RuleForm.name] in headers/citations (e.g. alternate form name from stance).
  final String? formDisplayLabel;

  /// Selected [RuleFormChoice.id] from the stance, when the form defines choices.
  final String? formChoiceId;

  /// Used to show full choice [RuleFormChoice.helpText] on the sheet for Frantic heroes.
  final HeroTypeKind? heroType;

  /// When non-null, form skill descriptions are shown in the Form info tooltip.
  final MergedRules? rules;
  final VoidCallback? onPickStyle;
  final VoidCallback? onPickForm;

  /// Shell colors (stance yellow vs frantic style-card red).
  final RulebookStanceChrome chrome;

  /// When true (Frantic style cards), show style rules only — no form header, dice,
  /// passives, or actions tied to a form.
  final bool styleOnly;

  /// Hover tooltip when the current stance row breaks printed rules.
  final String? ruleViolationHint;

  /// Action title ribbon width as a fraction of the stance panel content width.
  static const double _actionRibbonWidthFactor = 0.8;

  /// Matches clipped archetype ribbons; taller than skill pills for 22px titles.
  static const double _actionTitleRibbonMinHeight = 44;

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
    final effectiveForm = styleOnly ? null : form;
    final rawFormLabel = effectiveForm == null
        ? ''
        : (formDisplayLabel != null && formDisplayLabel!.trim().isNotEmpty)
        ? formDisplayLabel!.trim()
        : effectiveForm.name;
    final formName = effectiveForm == null
        ? '(Pick a Form)'
        : _trimFormSuffix(rawFormLabel);
    final styleCitationBadge = style == null
        ? 'Style'
        : _trimStyleSuffix(style!.name);
    final formCitationBadge = effectiveForm == null
        ? 'Form'
        : _trimFormSuffix(rawFormLabel);
    final styleSkill = _resolvedStyleSkill(style, rules);
    final resolvedChoice = effectiveForm != null && formChoiceId != null
        ? ruleFormChoiceById(effectiveForm, formChoiceId)
        : null;
    final rangeText = formatStanceRangeSubtitle(
      style,
      styleSkill,
      effectiveForm,
      formCitationBadge,
      selectedFormChoice: resolvedChoice,
    );
    final styleDm = _styleDisplayModel(style, styleSkill);
    final formDm = _formDisplayModel(
      effectiveForm,
      rules,
      formChoiceId: formChoiceId,
      fullFormChoicePassive: heroType == HeroTypeKind.frantic,
    );

    final layoutW = MediaQuery.sizeOf(context).width;
    final ribbonTypo = RulebookRibbonHeaderTypography.forWidth(layoutW);
    final headerTitleStyle = chrome.headerTitleStyle.copyWith(
      fontSize: ribbonTypo.titleFontSize,
      height: 1.0,
    );
    final rangeStyle = chrome.rangeLineStyle.copyWith(
      fontSize: ribbonTypo.rangeFontSize,
      height: 1.15,
    );
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
    final styleActionWidgets = _styleActionSections(
      style,
      styleSkill,
      styleDm,
      actionRibbonTitleStyle: actionRibbonTitleStyle,
      wellBodyStyle: wellBodyStyle,
    );
    final formActionWidgets = styleOnly
        ? const <RulebookTemplateSubSection>[]
        : _formActionSections(
            effectiveForm,
            formDm,
            formCitationBadge,
            actionRibbonTitleStyle: actionRibbonTitleStyle,
            wellBodyStyle: wellBodyStyle,
          );
    final hasActionsBelow =
        styleActionWidgets.isNotEmpty || formActionWidgets.isNotEmpty;
    final notes = style?.marginNotes.trim() ?? '';
    final hasPassives =
        styleDm.passiveParagraphs.isNotEmpty ||
        formDm.passiveParagraphs.isNotEmpty ||
        notes.isNotEmpty;

    final mainBackgroundAsset = styleOnly
        ? RulebookSheetImageAssets.backgroundStyle
        : RulebookSheetImageAssets.backgroundStance;
    final mainRibbonAsset = styleOnly
        ? RulebookSheetImageAssets.bannerStyle
        : RulebookSheetImageAssets.bannerStance;

    final model = RulebookSectionTemplateModel(
      mainLateralBorder: RulebookTemplateLateralBorder(
        color: chrome.lateralRail,
      ),
      mainBackground: chrome.mainBodyBackground,
      mainBackgroundAsset: mainBackgroundAsset,
      mainRibbonStyle: RulebookTemplateRibbonStyle(
        fill: chrome.titleRibbonFill,
        minHeight: 52,
        diagonalReserve: 66,
        padding: const EdgeInsets.fromLTRB(12, 10, 66, 10),
      ),
      mainRibbonAsset: mainRibbonAsset,
      mainRibbonFixedHeight: styleOnly ? 80 : 84,
      mainRibbonTitle: _mainRibbonTitle(
        styleName: styleName,
        formName: formName,
        styleOnly: styleOnly,
        chrome: chrome,
        ruleViolationHint: ruleViolationHint,
        headerStyle: headerTitleStyle,
        editIconSize: ribbonTypo.editIconSize,
        layoutWidth: layoutW,
      ),
      mainRibbonSubtitle: Text(
        rangeText,
        style: rangeStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
      upperRight: styleOnly
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _diceWidgetsForForm(form).length; i++) ...[
                  if (i > 0) const SizedBox(width: _stanceDiceSpacing),
                  _diceWidgetsForForm(form)[i],
                ],
              ],
            ),
      titleRibbonFlex: _titleRibbonFlexWithDice,
      upperRightFlex: _titleDiceFlexWithDice,
      mainBody: _passiveAbilitiesSection(
        style,
        styleCitationBadge,
        formCitationBadge,
        styleDm,
        formDm,
        hasActionsBelow: hasActionsBelow,
        wellBodyStyle: wellBodyStyle,
      ),
      mainBodyPadding: (hasPassives || !hasActionsBelow)
          ? const EdgeInsets.fromLTRB(14, 12, 14, 14)
          : EdgeInsets.zero,
      subSections: [...styleActionWidgets, ...formActionWidgets],
    );

    return RulebookSectionTemplate(model: model);
  }

  Widget _mainRibbonTitle({
    required String styleName,
    required String formName,
    required bool styleOnly,
    required RulebookStanceChrome chrome,
    String? ruleViolationHint,
    required TextStyle headerStyle,
    required double editIconSize,
    required double layoutWidth,
  }) {
    final titleRuleHint = ruleViolationHint;
    final gutter = layoutWidth < 400 ? 6.0 : 8.0;
    final styleTooltip = style == null
        ? 'Tap to pick a style for this stance. Full rules text appears once you choose.'
        : stanceStyleRulesBody(style!, rules);
    final formTooltip = form == null
        ? 'Pick a style first, then tap here to choose a form.'
        : rules != null
        ? stanceFormRulesBody(form!, rules!)
        : _formTooltipWithoutRules(form!);

    Widget styleCell() {
      return Tooltip(
        message: styleTooltip,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(10),
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 200),
        child: _editableHeaderPart(
          styleName,
          onPickStyle,
          chrome,
          headerStyle,
          editIconSize,
        ),
      );
    }

    Widget formCell() {
      return Tooltip(
        message: formTooltip,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(10),
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 200),
        child: _editableHeaderPart(
          formName,
          onPickForm,
          chrome,
          headerStyle,
          editIconSize,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (titleRuleHint != null) ...[
          RuleViolationTriangle(message: titleRuleHint),
          const SizedBox(width: 4),
        ],
        if (styleOnly)
          Flexible(child: styleCell())
        else ...[
          Flexible(child: styleCell()),
          SizedBox(width: gutter),
          Flexible(child: formCell()),
        ],
      ],
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
            : splitRuleParagraphs(passive),
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
  _formDisplayModel(
    RuleForm? f,
    MergedRules? r, {
    String? formChoiceId,
    required bool fullFormChoicePassive,
  }) {
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

  List<RulebookTemplateSubSection> _styleActionSections(
    RuleStyle? st,
    RuleSkill? skill,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      String? fallbackBody,
    })
    dm, {
    required TextStyle actionRibbonTitleStyle,
    required TextStyle wellBodyStyle,
  }) {
    if (st == null) return const [];
    final badge = _trimStyleSuffix(st.name);
    final sections = <RulebookTemplateSubSection>[];
    for (final a in dm.actions) {
      final title = a.heading.trim().isNotEmpty
          ? a.heading.trim()
          : _styleActionHeading(st, skill);
      final paras = splitRuleParagraphs(a.description.trim());
      final body = paras.isEmpty
          ? const SizedBox.shrink()
          : _paragraphsWithSource(
              paras,
              badge,
              singleCitation: true,
              wellBodyStyle: wellBodyStyle,
            );
      sections.add(
        _actionSubSection(
          title: title,
          body: body,
          titleStyle: actionRibbonTitleStyle,
        ),
      );
    }
    final fb = dm.fallbackBody;
    if (fb != null && fb.isNotEmpty) {
      sections.add(
        _actionSubSection(
          title: _styleActionHeading(st, skill),
          body: _paragraphsWithSource(
            splitRuleParagraphs(fb),
            badge,
            singleCitation: true,
            wellBodyStyle: wellBodyStyle,
          ),
          titleStyle: actionRibbonTitleStyle,
        ),
      );
    }
    return sections;
  }

  List<RulebookTemplateSubSection> _formActionSections(
    RuleForm? f,
    ({
      List<String> passiveParagraphs,
      List<RuleFormAction> actions,
      List<({String text, String badge})>? fallbackAttributed,
    })
    dm,
    String formBadge, {
    required TextStyle actionRibbonTitleStyle,
    required TextStyle wellBodyStyle,
  }) {
    if (f == null) return const [];
    final sections = <RulebookTemplateSubSection>[];
    for (final a in dm.actions) {
      final title = a.heading.trim().isNotEmpty
          ? a.heading.trim()
          : _formActionHeading(f);
      final paras = splitRuleParagraphs(a.description.trim());
      final body = paras.isEmpty
          ? const SizedBox.shrink()
          : _paragraphsWithSource(
              paras,
              formBadge,
              singleCitation: true,
              wellBodyStyle: wellBodyStyle,
            );
      sections.add(
        _actionSubSection(
          title: title,
          body: body,
          titleStyle: actionRibbonTitleStyle,
        ),
      );
    }
    final fb = dm.fallbackAttributed;
    if (fb != null && fb.isNotEmpty) {
      sections.add(
        _actionSubSection(
          title: _formActionHeading(f),
          body: _attributedParagraphBadges(
            fb,
            singleCitation: true,
            wellBodyStyle: wellBodyStyle,
          ),
          titleStyle: actionRibbonTitleStyle,
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
    required TextStyle wellBodyStyle,
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
          _paragraphsWithSource(
            stylePass,
            styleCitationBadge,
            wellBodyStyle: wellBodyStyle,
          ),
          if (formPass.isNotEmpty || notes.isNotEmpty)
            const SizedBox(height: 12),
        ],
        if (formPass.isNotEmpty) ...[
          _paragraphsWithSource(
            formPass,
            formCitationBadge,
            wellBodyStyle: wellBodyStyle,
          ),
          if (notes.isNotEmpty) const SizedBox(height: 12),
        ],
        if (notes.isNotEmpty)
          Text(
            notes,
            style: wellBodyStyle.copyWith(
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

  Widget _editableHeaderPart(
    String text,
    VoidCallback? onTap,
    RulebookStanceChrome chrome,
    TextStyle headerStyle,
    double editIconSize,
  ) {
    final label = Text(
      text,
      style: headerStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
    if (onTap == null) {
      return label;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: label),
            SizedBox(width: editIconSize >= 22 ? 6 : 4),
            Icon(
              Icons.edit_outlined,
              size: editIconSize,
              color: chrome.headerIconColor,
            ),
          ],
        ),
      ),
    );
  }

  RulebookTemplateSubSection _actionSubSection({
    required String title,
    required Widget body,
    required TextStyle titleStyle,
  }) {
    return RulebookTemplateSubSection(
      lateralBorder: RulebookTemplateLateralBorder(
        color: chrome.actionSideBorderGreen,
      ),
      background: chrome.actionDescriptionBg,
      backgroundAsset: RulebookSheetImageAssets.backgroundAction,
      ribbonStyle: RulebookTemplateRibbonStyle(
        fill: chrome.actionTitleGreen,
        minHeight: _actionTitleRibbonMinHeight,
        diagonalReserve: _actionTitleRibbonMinHeight + 14,
        padding: const EdgeInsets.fromLTRB(
          14,
          8,
          _actionTitleRibbonMinHeight + 14,
          8,
        ),
      ),
      ribbonAsset: RulebookSheetImageAssets.bannerAction,
      ribbonFixedHeight: _actionTitleRibbonMinHeight,
      ribbonTitle: Text(title, softWrap: true, style: titleStyle),
      ribbonWidthFactor: _actionRibbonWidthFactor,
      body: body,
      bodyPadding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    );
  }

  Widget _stanceSourceBadge(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chrome.sourceBadgeYellow,
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
    required TextStyle wellBodyStyle,
  }) {
    if (paragraphs.isEmpty) {
      return const SizedBox.shrink();
    }
    if (singleCitation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            rulebookActionOptionParagraph(paragraphs[i], wellBodyStyle),
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
              style: wellBodyStyle,
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
              style: wellBodyStyle,
              children: [
                ...rulebookActionOptionInlineSpans(
                  items[i].text,
                  wellBodyStyle,
                ),
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

  String _trimStyleSuffix(String name) =>
      name.replaceAll(RegExp(r'\s+Style$'), '');
  String _trimFormSuffix(String name) =>
      name.replaceAll(RegExp(r'\s+Form$'), '');

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
