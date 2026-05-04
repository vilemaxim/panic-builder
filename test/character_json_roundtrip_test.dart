import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/domain/advancement.dart';
import 'package:panic_at_the_dojo/domain/character.dart';
import 'package:panic_at_the_dojo/domain/hero_type_kind.dart';
import 'package:panic_at_the_dojo/domain/skills_state.dart';
import 'package:panic_at_the_dojo/domain/stance.dart';
import 'package:panic_at_the_dojo/domain/super_unlock.dart';

void main() {
  test('Character JSON roundtrip', () {
    final now = DateTime.utc(2026, 4, 29);
    final original = Character(
      id: 'id-1',
      schemaVersion: kCharacterSchemaVersion,
      createdAt: now,
      updatedAt: now,
      playerName: 'Alex',
      characterName: 'Jade Tiger',
      gender: 'f',
      description: 'Test',
      heroType: HeroTypeKind.fused,
      buildId: 'tough',
      archetypeIds: const ['iron_palm', 'ghost_thread'],
      stances: const [
        Stance(
          styleId: 'style_iron_root',
          formId: 'form_01',
          formDisplayName: 'Ox Gate',
          formChoiceId: 'control_max_plus_3',
        ),
        Stance(
          styleId: 'style_iron_ram',
          formId: 'form_02',
          formDisplayName: 'Crane Perch',
        ),
        Stance(
          styleId: 'style_ghost_smoke',
          formId: 'form_03',
          formDisplayName: 'Tiger Crossing',
        ),
      ],
      skillsState: const SkillsState(
        skillsByStance: [
          ['skill_heavy_palm', 'skill_root', 'skill_clash'],
          ['skill_balance', 'skill_dodge', 'skill_precision'],
          ['skill_rush', 'skill_rend', 'skill_intimidate'],
        ],
        twoWordSkill: 'Iron Flow',
        skillPlayerNotes: {'skill_form_blaster': 'Fire tricks'},
      ),
      xpEarned: 5,
      xpSpent: 2,
      advancements: [
        Advancement(
          kind: AdvancementKind.custom,
          costXp: 1,
          at: now,
          note: 'example',
        ),
      ],
      superUnlock: const SuperUnlock(
        superId: 'super_linebreaker',
        customLabel: null,
      ),
    );

    final json =
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
    final round = Character.fromJson(json);

    expect(round.id, original.id);
    expect(round.heroType, original.heroType);
    expect(round.stances.length, 3);
    expect(round.stances.first.formChoiceId, 'control_max_plus_3');
    expect(round.skillsState?.twoWordSkill, 'Iron Flow');
    expect(
      round.skillsState?.skillPlayerNotes['skill_form_blaster'],
      'Fire tricks',
    );
    expect(round.advancements.length, 1);
    expect(round.superUnlock?.superId, 'super_linebreaker');
  });
}
