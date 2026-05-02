import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/character_policies.dart';
import '../../domain/hero_type_kind.dart';

/// Resolve printable rulebook sheet labels/bodies from merged rules JSON + character state.
class CharacterSheetPresenter {
  CharacterSheetPresenter(this.rules);

  final MergedRules rules;

  String bannerSubtitle(HeroTypeKind? hero) {
    if (hero == null) {
      return '(Pick a Hero Type)';
    }
    final label = rules.heroTypeById(hero.name)?.name ?? hero.name;
    return '($label Hero)';
  }

  /// Four orange tiles: first slot per stance (may be swapped) + two-word skill.
  List<String> orangePillLabels(Character c) {
    final pills = <String>[];
    final policies = CharacterPolicies(rules);
    final draft = policies.defaultSkillsFromStances(c.stances);
    for (var i = 0; i < 3; i++) {
      if (c.stances.length > i && c.stances[i].formId.isNotEmpty) {
        final id = c.skillsState != null &&
                i < c.skillsState!.skillsByStance.length &&
                c.skillsState!.skillsByStance[i].isNotEmpty
            ? c.skillsState!.skillsByStance[i][0]
            : draft.skillsByStance[i][0];
        final sk = rules.skillById(id);
        final label = sk?.name.trim() ?? '';
        pills.add(label.isNotEmpty ? label : '—');
      } else {
        pills.add('—');
      }
    }
    final tw = c.skillsState?.twoWordSkill ?? '';
    pills.add(tw.isNotEmpty ? tw : '—');
    return pills;
  }

  /// Build line on the archetype ribbon (brown name banner uses a parallel pattern).
  String buildBannerLabel(Character c) {
    if (c.buildId == null) return '(Pick a Build)';
    return rules.buildById(c.buildId)?.name ?? '(Pick a Build)';
  }

  List<String> _paddedArchetypeIds(Character c) {
    final ht = c.heroType;
    if (ht == null) {
      return List<String>.from(c.archetypeIds);
    }
    final need =
        rules.heroTypeById(ht.name)?.archetypeSlots ??
        switch (ht) {
          HeroTypeKind.focused => 1,
          HeroTypeKind.fused => 2,
          HeroTypeKind.frantic => 3,
        };
    final out = List<String>.filled(need, '');
    for (var i = 0; i < c.archetypeIds.length && i < need; i++) {
      out[i] = c.archetypeIds[i];
    }
    return out;
  }

  /// Archetype summary on the archetype ribbon.
  String archetypeBannerLabel(Character c) {
    final padded = _paddedArchetypeIds(c);
    final names = padded
        .where((id) => id.isNotEmpty)
        .map((id) => rules.archetypeById(id)?.name ?? id)
        .toList();
    if (names.isEmpty) return '(Pick an archetype)';
    return names.join(' · ');
  }

  /// One slot on the archetype ribbon (Fused / Frantic use multiple).
  String archetypeSlotBannerLabel(Character c, int slotIndex) {
    final padded = _paddedArchetypeIds(c);
    if (slotIndex < 0 || slotIndex >= padded.length) {
      return '(Pick an archetype)';
    }
    final id = padded[slotIndex];
    if (id.isEmpty) return '(Pick an archetype)';
    return rules.archetypeById(id)?.name ?? id;
  }
}
