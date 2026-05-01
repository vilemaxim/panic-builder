import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/domain/character.dart';
import 'package:panic_at_the_dojo/domain/computed_stats.dart';
import 'package:panic_at_the_dojo/domain/hero_type_kind.dart';
import 'package:panic_at_the_dojo/domain/skills_state.dart';
import 'package:panic_at_the_dojo/domain/stance.dart';
import 'package:panic_at_the_dojo/features/print/character_pdf.dart';

import 'test_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildCharacterPdfBytes handles em dash and bullet without missing glyph logs', () async {
    final rules = minimalMergedRulesForTests();
    final now = DateTime(2026, 4, 30);
    final character = Character(
      id: 'c1',
      schemaVersion: kCharacterSchemaVersion,
      updatedAt: now,
      createdAt: now,
      playerName: 'Jane — Player',
      characterName: 'Blade • Dancer',
      gender: 'X',
      description: 'Uses style notes — with bullets • and unicode minus −',
      heroType: HeroTypeKind.focused,
      buildId: 'b1',
      archetypeIds: const ['a1'],
      stances: const [
        Stance(styleId: 's1', formId: 'f1', formDisplayName: 'Form — One'),
      ],
      skillsState: const SkillsState(
        skillsByStance: [
          ['k1', 'k2', 'k3'],
        ],
        twoWordSkill: 'Cut • Flow',
      ),
      computed: const ComputedStats(maxHp: 10, hpBars: 2, totalBars: 5),
    );

    final logs = <String>[];
    final bytes = await runZoned(
      () => buildCharacterPdfBytes(character, rules),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) => logs.add(message),
      ),
    );

    expect(bytes, isNotEmpty);
    expect(
      logs.where((m) => m.contains('Unable to find a font to draw')),
      isEmpty,
      reason: 'Save-to-PDF flow should not emit missing-glyph logs for rulebook punctuation.',
    );
  });
}
