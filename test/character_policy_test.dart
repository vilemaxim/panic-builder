import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/data/rules_models.dart';
import 'package:panic_at_the_dojo/domain/character.dart';
import 'package:panic_at_the_dojo/domain/character_policies.dart';
import 'package:panic_at_the_dojo/domain/hero_type_kind.dart';
import 'package:panic_at_the_dojo/domain/skills_state.dart';
import 'package:panic_at_the_dojo/domain/stance.dart';

MergedRules _minimalRules() {
  return MergedRules.fromJson({
    'version': 1,
    'heroTypes': [
      {
        'id': 'focused',
        'name': 'Focused',
        'description': '',
        'restrictions': '',
        'archetypeSlots': 1,
      },
      {
        'id': 'fused',
        'name': 'Fused',
        'description': '',
        'restrictions': '',
        'archetypeSlots': 2,
      },
      {
        'id': 'frantic',
        'name': 'Frantic',
        'description': '',
        'restrictions': '',
        'archetypeSlots': 3,
      },
    ],
    'builds': [
      {'id': 'b1', 'name': 'B1', 'description': '', 'maxHp': 10, 'hpBars': 2, 'totalBars': 5},
    ],
    'archetypes': [
      {'id': 'a1', 'name': 'A1', 'description': '', 'abilitiesSummary': ''},
      {'id': 'a2', 'name': 'A2', 'description': '', 'abilitiesSummary': ''},
      {'id': 'a3', 'name': 'A3', 'description': '', 'abilitiesSummary': ''},
    ],
    'styles': [
      {'id': 's1', 'archetypeId': 'a1', 'name': 'S1', 'basicInfo': '', 'marginNotes': ''},
      {'id': 's2', 'archetypeId': 'a1', 'name': 'S2', 'basicInfo': '', 'marginNotes': ''},
      {'id': 's3', 'archetypeId': 'a1', 'name': 'S3', 'basicInfo': '', 'marginNotes': ''},
      {'id': 't1', 'archetypeId': 'a2', 'name': 'T1', 'basicInfo': '', 'marginNotes': ''},
      {'id': 't2', 'archetypeId': 'a2', 'name': 'T2', 'basicInfo': '', 'marginNotes': ''},
      {'id': 'u1', 'archetypeId': 'a3', 'name': 'U1', 'basicInfo': '', 'marginNotes': ''},
    ],
    'forms': [
      {
        'id': 'f1',
        'name': 'F1',
        'altNames': ['F1a'],
        'skillIds': ['k1', 'k2', 'k3'],
      },
      {
        'id': 'f2',
        'name': 'F2',
        'altNames': [],
        'skillIds': ['k4', 'k5', 'k6'],
      },
      {
        'id': 'f3',
        'name': 'F3',
        'altNames': [],
        'skillIds': ['k7', 'k8', 'k9'],
      },
    ],
    'skills': List.generate(
      12,
      (i) => {
        'id': 'k${i + 1}',
        'name': 'K${i + 1}',
        'description': '',
      },
    ),
    'supers': [],
  });
}

void main() {
  test('Fused archetypes incomplete until both slots filled', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    expect(
      p.validateArchetypes(HeroTypeKind.fused, const ['a1']),
      isNotNull,
    );
    expect(
      p.validateArchetypes(HeroTypeKind.fused, const ['a1', 'a2']),
      isNull,
    );
  });

  test('validateArchetypeSlotPick rejects duplicate in other slot', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    final err = p.validateArchetypeSlotPick(
      HeroTypeKind.fused,
      const ['a1', ''],
      'a1',
      1,
    );
    expect(err, isNotNull);
  });

  test('Focused requires all styles from one archetype', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    final err = p.validateStances(
      HeroTypeKind.focused,
      const ['a1'],
      const [
        Stance(styleId: 's1', formId: 'f1', formDisplayName: 'F1'),
        Stance(styleId: 't1', formId: 'f2', formDisplayName: 'F2'),
        Stance(styleId: 's3', formId: 'f3', formDisplayName: 'F3'),
      ],
    );
    expect(err, isNotNull);
  });

  test('validateStances rejects duplicate styles across stances', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    final err = p.validateStances(
      HeroTypeKind.focused,
      const ['a1'],
      const [
        Stance(styleId: 's1', formId: 'f1', formDisplayName: 'F1'),
        Stance(styleId: 's1', formId: 'f2', formDisplayName: 'F2'),
        Stance(styleId: 's3', formId: 'f3', formDisplayName: 'F3'),
      ],
    );
    expect(err, isNotNull);
    expect(err, contains('different style'));
  });

  test('allowedStyleIdsForStance hides styles picked on other stances', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    const partial = [
      Stance(styleId: 's1', formId: 'f1', formDisplayName: 'F1'),
      Stance(styleId: '', formId: '', formDisplayName: ''),
      Stance(styleId: '', formId: '', formDisplayName: ''),
    ];
    final forStance1 = p.allowedStyleIdsForStance(
      hero: HeroTypeKind.focused,
      archetypeIds: const ['a1'],
      stanceIndex: 1,
      partialStances: partial,
    );
    expect(forStance1, contains('s2'));
    expect(forStance1, contains('s3'));
    expect(forStance1, isNot(contains('s1')));
  });

  test('allowedStyleIdsForStance still lists current stance style', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    const partial = [
      Stance(styleId: 's1', formId: 'f1', formDisplayName: 'F1'),
      Stance(styleId: 's2', formId: 'f2', formDisplayName: 'F2'),
      Stance(styleId: 's3', formId: 'f3', formDisplayName: 'F3'),
    ];
    final forStance1 = p.allowedStyleIdsForStance(
      hero: HeroTypeKind.focused,
      archetypeIds: const ['a1'],
      stanceIndex: 1,
      partialStances: partial,
    );
    expect(forStance1, contains('s2'));
    expect(forStance1, isNot(contains('s1')));
    expect(forStance1, isNot(contains('s3')));
  });

  test('Frantic maps stance index to archetype styles', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    final err = p.validateStances(
      HeroTypeKind.frantic,
      const ['a1', 'a2', 'a3'],
      const [
        Stance(styleId: 's1', formId: 'f1', formDisplayName: 'F1'),
        Stance(styleId: 't1', formId: 'f2', formDisplayName: 'F2'),
        Stance(styleId: 'u1', formId: 'f3', formDisplayName: 'F3'),
      ],
    );
    expect(err, isNull);
  });

  test('skills allow one swap', () {
    final rules = _minimalRules();
    final p = CharacterPolicies(rules);
    const stances = [
      Stance(styleId: 's1', formId: 'f1', formDisplayName: 'F1'),
      Stance(styleId: 's2', formId: 'f2', formDisplayName: 'F2'),
      Stance(styleId: 's3', formId: 'f3', formDisplayName: 'F3'),
    ];
    final c = Character.blank().copyWith(
      heroType: HeroTypeKind.focused,
      buildId: 'b1',
      archetypeIds: const ['a1'],
      stances: stances,
      skillsState: const SkillsState(
        skillsByStance: [
          ['k1', 'k2', 'k3'],
          ['k4', 'k5', 'k6'],
          ['k7', 'k8', 'k10'],
        ],
        replacementSkillId: 'k10',
        twoWordSkill: 'Iron Palm',
      ),
    );
    expect(p.validateSkills(c), isNull);
  });
}
