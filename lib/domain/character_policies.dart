import '../data/rules_models.dart';
import 'character.dart';
import 'hero_type_kind.dart';
import 'stance.dart';

/// Max length for the custom final skill label (rules suggest two words).
const int kCustomHeroSkillMaxChars = 80;

/// Pure validation helpers for creation flow.
class CharacterPolicies {
  const CharacterPolicies(this.rules);

  final MergedRules rules;

  int archetypeSlotCount(HeroTypeKind? hero) {
    if (hero == null) return 0;
    final id = hero.name;
    final h = rules.heroTypeById(id);
    return h?.archetypeSlots ??
        switch (hero) {
          HeroTypeKind.focused => 1,
          HeroTypeKind.fused => 2,
          HeroTypeKind.frantic => 3,
        };
  }

  /// Pads with empty strings to [archetypeSlotCount] so each index is a fixed slot.
  List<String> paddedArchetypeIds(HeroTypeKind? hero, List<String> raw) {
    if (hero == null) return List<String>.from(raw);
    final need = archetypeSlotCount(hero);
    if (need == 0) return const [];
    final out = List<String>.filled(need, '');
    for (var i = 0; i < raw.length && i < need; i++) {
      out[i] = raw[i];
    }
    return out;
  }

  /// Validates one slot after a pick; list must already be padded to slot count.
  String? validateArchetypeSlotPick(
    HeroTypeKind? hero,
    List<String> paddedIds,
    String pickedId,
    int slotIndex,
  ) {
    if (hero == null) return 'Choose a hero type first.';
    if (rules.archetypeById(pickedId) == null) {
      return 'Unknown archetype: $pickedId';
    }
    final need = archetypeSlotCount(hero);
    if (slotIndex < 0 || slotIndex >= need) {
      return 'Invalid archetype slot.';
    }
    for (var i = 0; i < paddedIds.length; i++) {
      if (i == slotIndex) continue;
      if (paddedIds[i].isNotEmpty && paddedIds[i] == pickedId) {
        return 'Archetypes must be distinct.';
      }
    }
    return null;
  }

  /// Returns null if all slots are filled and valid, else error message.
  String? validateArchetypes(HeroTypeKind? hero, List<String> archetypeIds) {
    if (hero == null) return 'Choose a hero type first.';
    final need = archetypeSlotCount(hero);
    final padded = paddedArchetypeIds(hero, archetypeIds);
    for (var i = 0; i < need; i++) {
      if (padded[i].isEmpty) {
        return 'Select all $need archetype(s) for ${hero.name}.';
      }
    }
    final set = padded.toSet();
    if (set.length != need) {
      return 'Archetypes must be distinct.';
    }
    for (final id in padded) {
      if (rules.archetypeById(id) == null) return 'Unknown archetype: $id';
    }
    return null;
  }

  /// Style pools per stance index (0–2) for Frantic: fixed order to archetype slots.
  List<String> allowedStyleIdsForStance({
    required HeroTypeKind hero,
    required List<String> archetypeIds,
    required int stanceIndex,
    required List<Stance> partialStances,
  }) {
    if (stanceIndex < 0 || stanceIndex > 2) return const [];
    final padded = paddedArchetypeIds(hero, archetypeIds);
    if (padded.isEmpty) return const [];

    final curStyleId = stanceIndex < partialStances.length
        ? partialStances[stanceIndex].styleId
        : '';

    List<String> pool = switch (hero) {
      HeroTypeKind.focused => padded[0].isEmpty
          ? const []
          : rules.stylesForArchetype(padded[0]).map((s) => s.id).toList(),
      HeroTypeKind.fused => () {
          final out = <String>[];
          if (padded[0].isNotEmpty) {
            out.addAll(rules.stylesForArchetype(padded[0]).map((s) => s.id));
          }
          if (padded.length > 1 && padded[1].isNotEmpty) {
            out.addAll(rules.stylesForArchetype(padded[1]).map((s) => s.id));
          }
          return out;
        }(),
      HeroTypeKind.frantic =>
        stanceIndex >= padded.length || padded[stanceIndex].isEmpty
            ? const <String>[]
            : rules
                .stylesForArchetype(padded[stanceIndex])
                .map((s) => s.id)
                .toList(),
    };

    // Fused: two stances cannot both be filled from the same archetype — the third
    // must use the other archetype. Hide saturated archetype styles in the picker.
    if (hero == HeroTypeKind.fused &&
        padded.length >= 2 &&
        padded[0].isNotEmpty &&
        padded[1].isNotEmpty) {
      final a0 = padded[0];
      final a1 = padded[1];
      var otherFromA0 = 0;
      var otherFromA1 = 0;
      for (var i = 0; i < partialStances.length; i++) {
        if (i == stanceIndex) continue;
        final sid = i < partialStances.length ? partialStances[i].styleId : '';
        if (sid.isEmpty) continue;
        final st = rules.styleById(sid);
        if (st == null) continue;
        if (st.archetypeId == a0) {
          otherFromA0++;
        } else if (st.archetypeId == a1) {
          otherFromA1++;
        }
      }
      pool = pool.where((id) {
        final st = rules.styleById(id);
        if (st == null) return false;
        if (otherFromA0 >= 2 && st.archetypeId == a0) {
          return id == curStyleId;
        }
        if (otherFromA1 >= 2 && st.archetypeId == a1) {
          return id == curStyleId;
        }
        return true;
      }).toList();
    }
    final usedElsewhere = <String>{};
    for (var i = 0; i < partialStances.length; i++) {
      if (i == stanceIndex) continue;
      final sid = partialStances[i].styleId;
      if (sid.isNotEmpty) usedElsewhere.add(sid);
    }
    return pool
        .where((id) => !usedElsewhere.contains(id) || id == curStyleId)
        .toList();
  }

  /// When non-null, choosing [archetypeId] in [editSlotIndex] duplicates another slot.
  String? explainArchetypeDuplicateForSlot(
    HeroTypeKind? hero,
    List<String> paddedArchetypeIds,
    int editSlotIndex,
    String archetypeId,
  ) {
    if (hero == null) return null;
    final need = archetypeSlotCount(hero);
    if (editSlotIndex < 0 || editSlotIndex >= need) return null;
    if (archetypeId.isEmpty) return null;
    for (var i = 0; i < paddedArchetypeIds.length; i++) {
      if (i == editSlotIndex) continue;
      if (paddedArchetypeIds[i] == archetypeId && archetypeId.isNotEmpty) {
        return 'Archetypes must be distinct (already used in another slot).';
      }
    }
    return null;
  }

  /// Explains why [styleId] is not in [allowedStyleIdsForStance] for this snapshot.
  String? explainWhyStyleNotAllowed({
    required HeroTypeKind hero,
    required List<String> archetypeIds,
    required int stanceIndex,
    required List<Stance> partialStances,
    required String styleId,
  }) {
    if (stanceIndex < 0 || stanceIndex > 2) return 'Invalid stance index.';
    final trimmed = styleId.trim();
    if (trimmed.isEmpty) return null;

    final allowed = allowedStyleIdsForStance(
      hero: hero,
      archetypeIds: archetypeIds,
      stanceIndex: stanceIndex,
      partialStances: partialStances,
    );
    if (allowed.contains(trimmed)) return null;

    if (rules.styleById(trimmed) == null) {
      return 'Unknown or invalid style.';
    }

    for (var i = 0; i < partialStances.length; i++) {
      if (i == stanceIndex) continue;
      if (partialStances[i].styleId == trimmed) {
        return 'Each stance must use a different style.';
      }
    }

    final style = rules.styleById(trimmed)!;
    final archIds = paddedArchetypeIds(hero, archetypeIds);

    switch (hero) {
      case HeroTypeKind.focused:
        if (archIds[0].isEmpty) {
          return 'Choose an archetype so Focused stance styles can follow the rules.';
        }
        if (style.archetypeId != archIds[0]) {
          return 'Focused: all styles must belong to your archetype.';
        }
        return 'This style does not match the stance rules for your current picks.';
      case HeroTypeKind.fused:
        final a0 = archIds.isNotEmpty ? archIds[0] : '';
        final a1 = archIds.length > 1 ? archIds[1] : '';
        if (a0.isEmpty || a1.isEmpty) {
          return 'Pick both fused archetypes so stance styles can follow the rules.';
        }
        if (style.archetypeId != a0 && style.archetypeId != a1) {
          return 'Fused: styles must come from your two archetypes only.';
        }
        return 'Fused: pick exactly two styles from one archetype and one from the other.';
      case HeroTypeKind.frantic:
        if (stanceIndex >= archIds.length) {
          return 'Frantic: stance ${stanceIndex + 1} uses the archetype from the same numbered slot.';
        }
        final needArch = archIds[stanceIndex];
        if (needArch.isEmpty) {
          return 'Pick all three archetypes so each Frantic stance can follow the rules.';
        }
        if (style.archetypeId != needArch) {
          return 'Frantic: stance ${stanceIndex + 1} must use a style from archetype ${stanceIndex + 1}.';
        }
        return 'This style does not match the stance rules for your current picks.';
    }
  }

  /// Form [formId] cannot be used on [stanceIndex] because another stance already has it.
  String? explainFormUsedOnAnotherStance({
    required List<Stance> stances,
    required int stanceIndex,
    required String formId,
  }) {
    final fid = formId.trim();
    if (fid.isEmpty) return null;
    for (var i = 0; i < stances.length; i++) {
      if (i == stanceIndex) continue;
      if (stances[i].formId == fid) {
        return 'Each stance must use a different form.';
      }
    }
    return null;
  }

  String? validateStances(
    HeroTypeKind? hero,
    List<String> archetypeIds,
    List<Stance> stances,
  ) {
    if (hero == null) return 'Hero type required.';
    final archErr = validateArchetypes(hero, archetypeIds);
    if (archErr != null) return archErr;
    if (stances.length != 3) return 'Configure all three stances.';

    final styleIds = stances.map((s) => s.styleId).toList();
    if (styleIds.toSet().length != 3) {
      return 'Each stance must use a different style.';
    }

    final formIds = stances.map((s) => s.formId).toList();
    if (formIds.toSet().length != 3) {
      return 'Each stance must use a different form.';
    }

    for (final st in stances) {
      if (rules.styleById(st.styleId) == null) return 'Invalid style.';
      if (rules.formById(st.formId) == null) return 'Invalid form.';
    }

    final archIds = paddedArchetypeIds(hero, archetypeIds);
    switch (hero) {
      case HeroTypeKind.focused:
        final a = archIds[0];
        for (final st in stances) {
          final style = rules.styleById(st.styleId);
          if (style == null || style.archetypeId != a) {
            return 'Focused: all styles must belong to your archetype.';
          }
        }
        break;
      case HeroTypeKind.fused:
        final a0 = archIds[0];
        final a1 = archIds[1];
        var c0 = 0;
        var c1 = 0;
        for (final st in stances) {
          final style = rules.styleById(st.styleId);
          if (style == null) return 'Invalid style.';
          if (style.archetypeId == a0) {
            c0++;
          } else if (style.archetypeId == a1) {
            c1++;
          } else {
            return 'Fused: styles must come from your two archetypes only.';
          }
        }
        if (!((c0 == 2 && c1 == 1) || (c0 == 1 && c1 == 2))) {
          return 'Fused: pick exactly two styles from one archetype and one from the other.';
        }
        break;
      case HeroTypeKind.frantic:
        for (var i = 0; i < 3; i++) {
          final arch = archIds[i];
          final style = rules.styleById(stances[i].styleId);
          if (style == null || style.archetypeId != arch) {
            return 'Frantic: stance ${i + 1} must use a style from archetype ${i + 1}.';
          }
        }
        break;
    }
    return null;
  }

  SkillsStateDraft defaultSkillsFromStances(List<Stance> stances) {
    final rows = <List<String>>[];
    for (final st in stances) {
      final form = rules.formById(st.formId);
      final ids = List<String>.from(form?.skillIds ?? const <String>[]);
      while (ids.length < 3) {
        ids.add('skill_placeholder');
      }
      rows.add(ids.take(3).toList());
    }
    return SkillsStateDraft(skillsByStance: rows);
  }

  String? validateSkills(Character c) {
    final st = c.stances;
    if (st.length != 3) return 'Stances incomplete.';
    final skills = c.skillsState;
    if (skills == null) return 'Skills not set.';

    final draft = defaultSkillsFromStances(st);
    var diffCount = 0;
    for (var i = 0; i < 3; i++) {
      final expected = draft.skillsByStance[i];
      final got = skills.skillsByStance[i];
      if (got.length != 3) return 'Each stance needs three skills.';
      for (var j = 0; j < 3; j++) {
        if (expected[j] != got[j]) diffCount++;
      }
    }
    if (diffCount > 1) {
      return 'You may change at most one skill from your form defaults.';
    }

    if (diffCount == 1) {
      if (skills.replacementSkillId == null ||
          rules.skillById(skills.replacementSkillId) == null) {
        return 'Pick a valid replacement skill from the list.';
      }
      String? changedCell;
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          if (draft.skillsByStance[i][j] != skills.skillsByStance[i][j]) {
            changedCell = skills.skillsByStance[i][j];
          }
        }
      }
      if (changedCell != skills.replacementSkillId) {
        return 'Replacement skill must match the one edited slot.';
      }
    }

    final tw = skills.twoWordSkill.trim();
    if (tw.isEmpty) return 'Enter your two-word skill.';
    if (tw.length > kCustomHeroSkillMaxChars) {
      return 'Skill name must be $kCustomHeroSkillMaxChars characters or fewer.';
    }
    return null;
  }

  /// Returns null if the character is complete enough to save after creation.
  String? validateCreationComplete(Character c) {
    if (c.heroType == null) return 'Choose a hero type.';
    if (c.buildId == null || rules.buildById(c.buildId) == null) {
      return 'Choose a build.';
    }
    final archErr = validateArchetypes(c.heroType, c.archetypeIds);
    if (archErr != null) return archErr;
    final stErr = validateStances(c.heroType, c.archetypeIds, c.stances);
    if (stErr != null) return stErr;
    return validateSkills(c);
  }
}

class SkillsStateDraft {
  const SkillsStateDraft({required this.skillsByStance});
  final List<List<String>> skillsByStance;
}
