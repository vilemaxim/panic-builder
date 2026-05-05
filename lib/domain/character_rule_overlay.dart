import 'character.dart';
import 'character_policies.dart';
import 'hero_type_kind.dart';
import 'stance.dart';

/// UI-oriented breakdown of where a character deviates from [CharacterPolicies]
/// validation (for red violation markers on the sheet and stance cards).
class CharacterRuleOverlay {
  CharacterRuleOverlay._();

  static List<Stance> stancesPadded(Character c) {
    return List<Stance>.generate(
      3,
      (i) => i < c.stances.length
          ? c.stances[i]
          : const Stance(styleId: '', formId: '', formDisplayName: ''),
    );
  }

  /// Combined style + form issues for stance [index] on the sheet (0–2).
  static String? stanceRowViolation(
    CharacterPolicies p,
    Character c,
    int index,
  ) {
    if (index < 0 || index > 2) return null;
    final hero = c.heroType;
    if (hero == null) return null;
    final padded = stancesPadded(c);
    final row = padded[index];
    final parts = <String>[];

    if (row.styleId.isNotEmpty && p.rules.styleById(row.styleId) == null) {
      parts.add('Invalid style.');
    } else if (row.styleId.isNotEmpty) {
      final s = p.explainWhyStyleNotAllowed(
        hero: hero,
        archetypeIds: c.archetypeIds,
        stanceIndex: index,
        partialStances: padded,
        styleId: row.styleId,
      );
      if (s != null) parts.add(s);
    }

    if (row.formId.isNotEmpty && p.rules.formById(row.formId) == null) {
      parts.add('Invalid form.');
    } else if (row.formId.isNotEmpty) {
      var dup = false;
      for (var j = 0; j < padded.length; j++) {
        if (j == index) continue;
        if (padded[j].formId == row.formId) dup = true;
      }
      if (dup) {
        parts.add('Each stance must use a different form.');
      }
      final f = p.rules.formById(row.formId);
      if (hero != HeroTypeKind.frantic && f != null && f.choices.isNotEmpty) {
        final cid = row.formChoiceId?.trim() ?? '';
        if (!f.choices.any((c) => c.id == cid)) {
          parts.add('Pick the ${f.name} rule option for this stance.');
        }
      }
    }

    final filtered = parts
        .where((p) => !_suppressStanceHintAsNotSelectedYet(p))
        .toList();
    if (filtered.isEmpty) return null;
    return filtered.join('\n\n');
  }

  /// Length = archetype slot count for [c.heroType]; null entries mean no marker.
  static List<String?> archetypeSlotViolations(
    CharacterPolicies p,
    Character c,
  ) {
    final hero = c.heroType;
    if (hero == null) return const <String?>[];
    final need = p.archetypeSlotCount(hero);
    final out = List<String?>.filled(need, null);
    final padded = p.paddedArchetypeIds(hero, c.archetypeIds);
    final err = p.validateArchetypes(hero, c.archetypeIds);
    if (err == null) return out;

    if (err.contains('distinct')) {
      for (var i = 0; i < need; i++) {
        if (padded[i].isEmpty) continue;
        for (var j = i + 1; j < need; j++) {
          if (padded[j] == padded[i]) {
            out[i] = err;
            out[j] = err;
          }
        }
      }
      return out;
    }

    // Unfilled slots: no marker — user has not chosen yet, not a rule break.
    if (err.contains('Select all')) {
      return out;
    }

    for (var i = 0; i < need; i++) {
      if (padded[i].isNotEmpty && p.rules.archetypeById(padded[i]) == null) {
        out[i] = err;
      }
    }
    return out;
  }

  /// Shown on stance skill orange pills (indices 0–2) when skills break rules.
  static String? stanceSkillPillViolation(CharacterPolicies p, Character c) {
    final e = p.validateSkills(c);
    if (e == null) return null;
    if (_isSkillPlayerNoteError(e)) return null;
    if (_isTwoWordOrCustomNameError(e)) return null;
    if (_suppressSkillAreaAsNotFilledInYet(e)) return null;
    return e;
  }

  /// Shown on the two-word / custom skill orange pill.
  static String? twoWordSkillPillViolation(CharacterPolicies p, Character c) {
    final e = p.validateSkills(c);
    if (e == null) return null;
    if (_isSkillPlayerNoteError(e)) return null;
    final lower = e.toLowerCase();
    // Empty custom skill: still building the character, not a printed-rules violation.
    if (lower.contains('enter your two-word')) return null;
    if (_suppressSkillAreaAsNotFilledInYet(e)) return null;
    if (_isTwoWordOrCustomNameError(e)) return e;
    return null;
  }

  static bool _isTwoWordOrCustomNameError(String e) {
    final lower = e.toLowerCase();
    return lower.contains('two-word') ||
        lower.contains('skill name') ||
        lower.contains('enter your two-word');
  }

  static bool _isSkillPlayerNoteError(String e) {
    final lower = e.toLowerCase();
    return lower.contains('short note for') ||
        (lower.contains('note must be') &&
            lower.contains('characters or fewer'));
  }

  /// Stance style row: hide hints that only mean prerequisites are not filled yet.
  static bool _suppressStanceHintAsNotSelectedYet(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('choose an archetype so')) return true;
    if (lower.contains('pick both fused archetypes')) return true;
    if (lower.contains('pick all three archetypes')) return true;
    return false;
  }

  /// Skill pills: sheet not far enough through creation / swap flow yet.
  static bool _suppressSkillAreaAsNotFilledInYet(String e) {
    final lower = e.toLowerCase();
    if (lower.contains('stances incomplete')) return true;
    if (lower.contains('skills not set')) return true;
    if (lower.contains('each stance needs three skills')) return true;
    if (lower.contains('pick a valid replacement skill')) return true;
    return false;
  }
}
