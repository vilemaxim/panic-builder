import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character.dart';
import '../../../domain/hero_type_kind.dart';
import '../character_sheet_presenter.dart';
import 'rulebook_ribbon_clipper.dart';

/// Optional tap targets on the banner: name, hero type, build, archetypes.
class RulebookSheetIdentityHandlers {
  const RulebookSheetIdentityHandlers({
    this.onCharacterName,
    this.onHeroType,
    this.onPickBuild,
    this.onPickArchetype,
  });

  final ValueChanged<String>? onCharacterName;
  final VoidCallback? onHeroType;
  final VoidCallback? onPickBuild;
  /// Slot index 0..n-1; banner segment determines which archetype is edited.
  final ValueChanged<int>? onPickArchetype;
}

/// Orange skill ribbons: swap first stance skill (one slot global) + two-word skill.
class RulebookSheetSkillHandlers {
  const RulebookSheetSkillHandlers({
    this.onReplaceStanceSkill,
    this.onEditTwoWordSkill,
  });

  /// Stance index 0–2; replaces [skillsByStance][i][0] with a skill from rules.
  final ValueChanged<int>? onReplaceStanceSkill;
  final VoidCallback? onEditTwoWordSkill;
}

/// Rulebook-style panel: yellow field, orange rails on the **sides only**,
/// brown name ribbon + orange skill tags (left column / right column geometry from source sheets).
class RulebookCharacterSheetPanel extends StatelessWidget {
  const RulebookCharacterSheetPanel({
    super.key,
    required this.character,
    required this.rules,
    this.identityHandlers,
    this.skillHandlers,
  });

  final Character character;
  final MergedRules rules;
  final RulebookSheetIdentityHandlers? identityHandlers;
  final RulebookSheetSkillHandlers? skillHandlers;

  static const Color _yellowBg = Color(0xFFFFF2B8);
  static const Color _orangeRail = Color(0xFFE87722);
  static const Color _pillOrange = Color(0xFFE86921);
  static const Color _bannerBrown = Color(0xFFB8722E);
  static const Color _purpleBand = Color(0xFF5C376B);
  static const Color _purpleBg = Color(0xFFEADDF5);

  static const double _railW = 12;

  static const double _bannerNameFontSize = 28;
  /// Hero-type line: smaller than name, still readable next to larger name.
  static const double _bannerSubtitleFontSize = 20;
  /// Skill/build/archetype labels, slightly larger for readability.
  static const double _skillFontSize = 15;
  /// Fits two lines of [_skillFontSize] with tight vertical padding.
  static const double _skillRibbonHeight = 38;

  /// Keeps label text out of the clipped diagonal (~skew ≈ ribbon height).
  static const double _skillRibbonDiagonalReserve = _skillRibbonHeight + 12;
  /// Vertical rhythm between stacked ribbon rows.
  static const double _ribbonGap = 5;

  /// Reserve at trailing edge so text clears the ~45° diagonal (skew ≈ ribbon height).
  /// Uses two-line estimate so wrapping/long subtitles stay inside the clip after softWrap.
  static double _bannerTrailingReserveForDiagonal(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    const verticalPad = 28.0; // matches banner EdgeInsets vertical 14+14
    const mainLine = _bannerNameFontSize * 1.15;
    const subLine = _bannerSubtitleFontSize * 1.15;
    return scale * (verticalPad + mainLine + subLine);
  }

  VoidCallback? _stanceSkillEdit(
    RulebookSheetSkillHandlers? h,
    Character ch,
    int stanceIndex,
  ) {
    if (h?.onReplaceStanceSkill == null) return null;
    if (stanceIndex >= ch.stances.length) return null;
    if (ch.stances[stanceIndex].formId.isEmpty) return null;
    return () => h!.onReplaceStanceSkill!(stanceIndex);
  }

  static Future<String?> _editLine(
    BuildContext context, {
    required String title,
    required String initial,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Press Enter to save',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final presenter = CharacterSheetPresenter(rules);
    final handlers = identityHandlers;
    final skillH = skillHandlers;
    final c = character;
    final displayName = character.characterName.trim().isEmpty
        ? 'Unnamed hero'
        : character.characterName.trim();
    final subtitle = presenter.bannerSubtitle(character.heroType);
    final pills = presenter.orangePillLabels(character);

    final banner = LayoutBuilder(
      builder: (context, constraints) {
        final layoutW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final onName = handlers?.onCharacterName;
        final onHero = handlers?.onHeroType;
        const nameStyle = TextStyle(
          color: Colors.white,
          fontSize: _bannerNameFontSize,
          fontWeight: FontWeight.w700,
          height: 1.15,
        );
        const subtitleStyle = TextStyle(
          color: Colors.white,
          fontSize: _bannerSubtitleFontSize,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          height: 1.15,
        );

        Widget nameSegment() {
          if (onName != null) {
            return Semantics(
              button: true,
              label: 'Edit hero name',
              child: Tooltip(
                message: 'Edit hero name',
                preferBelow: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final v = await _editLine(
                        context,
                        title: 'Hero name',
                        initial: character.characterName,
                      );
                      if (v != null && context.mounted) {
                        onName(v);
                      }
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(displayName, style: nameStyle),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return Text(displayName, style: nameStyle);
        }

        Widget heroTypeSegment() {
          if (onHero != null) {
            return Semantics(
              button: true,
              label: 'Choose hero type',
              child: Tooltip(
                message: 'Choose hero type',
                preferBelow: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onHero,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(subtitle, style: subtitleStyle),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return Text(subtitle, style: subtitleStyle);
        }

        final bannerContent = Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            18 + _bannerTrailingReserveForDiagonal(context),
            14,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layoutW),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                nameSegment(),
                heroTypeSegment(),
              ],
            ),
          ),
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: ClipPath(
            clipper: const LeftRibbonClipper(topRightRadius: kRulebookRibbonCornerRadius),
            child: ColoredBox(
              color: _bannerBrown,
              child: bannerContent,
            ),
          ),
        );
      },
    );

    final archetypeRibbon = LayoutBuilder(
      builder: (context, constraints) {
        final layoutW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final onBuild = handlers?.onPickBuild;
        final onArch = handlers?.onPickArchetype;
        final buildLabel = presenter.buildBannerLabel(character);
        final archLabel = presenter.archetypeBannerLabel(character);
        final ht = character.heroType;
        const nameStyle = TextStyle(
          color: Colors.white,
          fontSize: _skillFontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        );
        const subtitleStyle = TextStyle(
          color: Colors.white,
          fontSize: _skillFontSize,
          fontWeight: FontWeight.w700,
          height: 1.2,
        );

        Widget buildSegment() {
          if (onBuild != null) {
            return Semantics(
              button: true,
              label: 'Choose build',
              child: Tooltip(
                message: 'Choose build',
                preferBelow: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBuild,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(buildLabel, style: nameStyle),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return Text(buildLabel, style: nameStyle);
        }

        Widget archetypeSegment(int slotIndex, {String? label}) {
          final text = label ?? archLabel;
          if (onArch != null) {
            return Semantics(
              button: true,
              label: 'Choose archetype',
              child: Tooltip(
                message: 'Choose archetype',
                preferBelow: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onArch(slotIndex),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(text, style: subtitleStyle),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 24,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return Text(text, style: subtitleStyle);
        }

        final ribbonInner = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _skillRibbonHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layoutW),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: buildSegment()),
                  const SizedBox(width: 8),
                  if (ht == HeroTypeKind.frantic)
                    const Flexible(child: Text('Frantic Hero', style: subtitleStyle))
                  else if (ht == HeroTypeKind.fused) ...[
                    Flexible(
                      child: archetypeSegment(
                        0,
                        label: presenter.archetypeSlotBannerLabel(character, 0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '/',
                        style: subtitleStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Flexible(
                      child: archetypeSegment(
                        1,
                        label: presenter.archetypeSlotBannerLabel(character, 1),
                      ),
                    ),
                  ] else
                    Flexible(child: archetypeSegment(0)),
                ],
              ),
            ),
          ),
        );

        final ribbonBar = ColoredBox(
          color: _purpleBand,
          child: ribbonInner,
        );
        return ColoredBox(
          color: _purpleBg,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClipPath(
              clipper: const LeftRibbonClipper(topRightRadius: kRulebookRibbonCornerRadius),
              child: ht == HeroTypeKind.frantic
                  ? SizedBox(
                      width: layoutW * 0.6,
                      child: ribbonBar,
                    )
                  : IntrinsicWidth(child: ribbonBar),
            ),
          ),
        );
      },
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _yellowBg,
        border: Border(
          left: BorderSide(color: _orangeRail, width: _railW),
          right: BorderSide(color: _orangeRail, width: _railW),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            banner,
            const SizedBox(height: _ribbonGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _leftRibbonOrange(
                      pills[0],
                      maxWidth: constraints.maxWidth,
                      onEdit: _stanceSkillEdit(
                        skillH,
                        c,
                        0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _rightRibbonOrange(
                      pills[1],
                      maxWidth: constraints.maxWidth,
                      onEdit: _stanceSkillEdit(
                        skillH,
                        c,
                        1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _ribbonGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _leftRibbonOrange(
                      pills[2],
                      maxWidth: constraints.maxWidth,
                      onEdit: _stanceSkillEdit(
                        skillH,
                        c,
                        2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _rightRibbonOrange(
                      pills[3],
                      maxWidth: constraints.maxWidth,
                      onEdit: skillH?.onEditTwoWordSkill,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _ribbonGap),
            archetypeRibbon,
            Container(
              width: double.infinity,
              color: _purpleBg,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _archetypeAbilityContent(),
            ),
            if (character.heroType == HeroTypeKind.frantic) ...[
              for (var i = 0; i < 3; i++) ...[
                const SizedBox(height: _ribbonGap),
                _franticBuildArchetypeArea(i, presenter),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _franticBuildArchetypeArea(int slotIndex, CharacterSheetPresenter presenter) {
    final build = rules.buildById(character.buildId);
    final buildLabel = build?.name ?? '';
    final archLabel = presenter.archetypeSlotBannerLabel(character, slotIndex);
    final onArch = identityHandlers?.onPickArchetype;
    const nameStyle = TextStyle(
      color: Colors.white,
      fontSize: _skillFontSize,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    final ribbon = ColoredBox(
      color: _purpleBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ribbonW = constraints.maxWidth * 0.6;
          return Align(
            alignment: Alignment.centerLeft,
            child: ClipPath(
              clipper: const LeftRibbonClipper(topRightRadius: kRulebookRibbonCornerRadius),
              child: SizedBox(
                width: ribbonW,
                child: ColoredBox(
                  color: _purpleBand,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _skillRibbonHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (buildLabel.isNotEmpty) ...[
                            Text(buildLabel, style: nameStyle),
                            const SizedBox(width: 8),
                          ],
                          if (onArch != null)
                            Semantics(
                              button: true,
                              label: 'Choose archetype',
                              child: Tooltip(
                                message: 'Choose archetype',
                                preferBelow: true,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => onArch(slotIndex),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(archLabel, style: nameStyle),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 24,
                                            color: Colors.white
                                                .withValues(alpha: 0.88),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(archLabel, style: nameStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ribbon,
        Container(
          width: double.infinity,
          color: _purpleBg,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: _franticSlotAbilityContent(slotIndex),
        ),
      ],
    );
  }

  Widget _franticSlotAbilityContent(int slotIndex) {
    final entries = <({String name, String ability})>[];
    final slotId = character.archetypeIds.length > slotIndex
        ? character.archetypeIds[slotIndex]
        : '';
    if (slotId.isNotEmpty) {
      final arch = rules.archetypeById(slotId);
      if (arch != null) {
        final rawAbility = (arch.abilitiesByHeroType[HeroTypeKind.frantic.name] ?? '').trim();
        final ability = _normalizeAbilityText(rawAbility);
        entries.add((
          name: arch.name,
          ability: ability.isEmpty ? 'No frantic ability text found.' : ability,
        ));
      }
    }
    if (entries.isEmpty) {
      return _archetypeHint('Pick an archetype for this stance to view its ability.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          ..._abilityParagraphsWithBadge(entries[i].ability, entries[i].name),
        ],
      ],
    );
  }

  Widget _archetypeAbilityContent() {
    final heroType = character.heroType;
    if (heroType == null) {
      return _archetypeHint('Pick a Hero Type to view archetype abilities.');
    }
    if (heroType == HeroTypeKind.frantic) {
      final build = rules.buildById(character.buildId);
      final buildDescription = (build?.description ?? '').trim();
      if (build != null && buildDescription.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._abilityParagraphsWithBadge(
              _normalizeAbilityText(buildDescription),
              build.name,
            ),
          ],
        );
      }
      return _archetypeHint('Pick a build to view its ability.');
    }
    final entries = <({String name, String ability})>[];
    final build = rules.buildById(character.buildId);
    final buildDescription = (build?.description ?? '').trim();
    if (build != null && buildDescription.isNotEmpty) {
      entries.add((name: build.name, ability: _normalizeAbilityText(buildDescription)));
    }
    for (final id in character.archetypeIds) {
      if (id.isEmpty) continue;
      final arch = rules.archetypeById(id);
      if (arch == null) continue;
      final rawAbility = (arch.abilitiesByHeroType[heroType.name] ?? '').trim();
      final ability = _normalizeAbilityText(rawAbility);
      entries.add((
        name: arch.name,
        ability: ability.isEmpty ? 'No ${heroType.name} ability text found.' : ability,
      ));
    }
    if (entries.isEmpty) {
      if (character.archetypeIds.where((e) => e.isNotEmpty).isEmpty) {
        return _archetypeHint('Pick an archetype to view its ${heroType.name} ability.');
      }
      return _archetypeHint('No archetype ability text available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          ..._abilityParagraphsWithBadge(entries[i].ability, entries[i].name),
        ],
      ],
    );
  }

  Widget _archetypeHint(String message) {
    return Text(
      message,
      style: const TextStyle(
        color: Color(0xFF2F2418),
        fontSize: 13.5,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _normalizeAbilityText(String text) {
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
            RegExp(r'[.!?]"?$').hasMatch(prev) && RegExp(r'^[A-Z(]').hasMatch(line);
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

  List<Widget> _abilityParagraphsWithBadge(String ability, String archetypeName) {
    final parts = ability
        .split(RegExp(r'\n\s*\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return [
      for (var i = 0; i < parts.length; i++) ...[
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF2F2418),
              fontSize: 15,
              height: 1.3,
            ),
            children: [
              TextSpan(text: parts[i]),
              const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _purpleBand,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    archetypeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (i < parts.length - 1) const SizedBox(height: 8),
      ],
    ];
  }

  /// Full column width (like pre–intrinsic-width behavior) with trailing inset so text clears the slash.
  Widget _leftRibbonOrange(
    String label, {
    required double maxWidth,
    VoidCallback? onEdit,
  }) {
    return SizedBox(
      width: maxWidth,
      height: _skillRibbonHeight,
      child: ClipPath(
        clipper: const LeftRibbonClipper(topRightRadius: kRulebookRibbonCornerRadius),
        child: ColoredBox(
          color: _pillOrange,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                6,
                _skillRibbonDiagonalReserve,
                6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.left,
                      style: _pillStyle(),
                    ),
                  ),
                  if (onEdit != null)
                    Semantics(
                      button: true,
                      label: 'Replace stance skill',
                      child: Tooltip(
                        message: 'Replace skill',
                        child: InkWell(
                          onTap: onEdit,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rightRibbonOrange(
    String label, {
    required double maxWidth,
    VoidCallback? onEdit,
  }) {
    return SizedBox(
      width: maxWidth,
      height: _skillRibbonHeight,
      child: ClipPath(
        clipper: const RightRibbonClipper(bottomLeftRadius: kRulebookRibbonCornerRadius),
        child: ColoredBox(
          color: _pillOrange,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _skillRibbonDiagonalReserve,
                6,
                10,
                6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.right,
                      style: _pillStyle(),
                    ),
                  ),
                  if (onEdit != null)
                    Semantics(
                      button: true,
                      label: 'Edit two-word skill',
                      child: Tooltip(
                        message: 'Two-word skill',
                        child: InkWell(
                          onTap: onEdit,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _pillStyle() => TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: _skillFontSize,
        height: 1.2,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 1.5),
        ],
      );
}
