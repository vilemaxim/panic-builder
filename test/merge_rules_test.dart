import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/data/merge_rules.dart';
import 'package:panic_at_the_dojo/data/rules_models.dart';

void main() {
  test('patch overrides build and adds supers', () {
    final base = jsonDecode('''
    {
      "version": 1,
      "builds": [
        {"id": "balanced", "name": "Balanced", "description": "base", "maxHp": 12, "hpBars": 3, "totalBars": 6}
      ],
      "supers": []
    }
    ''') as Map<String, dynamic>;

    final patch = jsonDecode('''
    {
      "builds": [
        {"id": "balanced", "name": "Balanced", "description": "patched", "maxHp": 11, "hpBars": 3, "totalBars": 6}
      ],
      "supers": [
        {"id": "super_a", "name": "Super A", "description": "d", "sourceBook": "Patch", "sourcePage": "1"}
      ]
    }
    ''') as Map<String, dynamic>;

    final merged = mergeRulesJson(base, patch);
    final rules = MergedRules.fromJson(merged);

    expect(rules.buildById('balanced')?.maxHp, 11);
    expect(rules.buildById('balanced')?.description, 'patched');
    expect(rules.supers.length, 1);
    expect(rules.superById('super_a')?.name, 'Super A');
  });

  test('patch merges style skillId and append-only skills', () {
    final base = jsonDecode('''
    {
      "version": 1,
      "styles": [
        {"id": "s1", "archetypeId": "a", "name": "Alpha Style", "basicInfo": "x"}
      ],
      "skills": [
        {"id": "skill_existing", "name": "Existing", "description": ""}
      ]
    }
    ''') as Map<String, dynamic>;

    final patch = jsonDecode('''
    {
      "styles": [
        {"id": "s1", "skillId": "skill_style_s1"}
      ],
      "skills": [
        {"id": "skill_style_s1", "name": "Strike", "description": "Full rules."}
      ]
    }
    ''') as Map<String, dynamic>;

    final merged = mergeRulesJson(base, patch);
    final rules = MergedRules.fromJson(merged);

    expect(rules.styleById('s1')?.skillId, 'skill_style_s1');
    expect(rules.skillById('skill_style_s1')?.name, 'Strike');
    expect(rules.skillById('skill_existing')?.name, 'Existing');
  });

  test('RuleStyle and RuleSkill strip carriage returns when parsed', () {
    final rules = MergedRules.fromJson({
      'version': 1,
      'heroTypes': <dynamic>[],
      'builds': <dynamic>[],
      'archetypes': <dynamic>[],
      'styles': [
        {
          'id': 's1',
          'archetypeId': 'a',
          'name': 'Name\r',
          'description': 'sum\r\nmary\r',
          'basicInfo': 'a\r\nb\rc',
          'marginNotes': 'm\r',
        },
      ],
      'forms': <dynamic>[],
      'skills': [
        {'id': 'k1', 'name': 'N\r', 'description': 'd\r\ne'},
      ],
      'supers': <dynamic>[],
    });
    final s = rules.styleById('s1')!;
    expect(s.name, 'Name');
    expect(s.description, 'sum\nmary');
    expect(s.basicInfo, 'a\nbc');
    expect(s.marginNotes, 'm');
    final k = rules.skillById('k1')!;
    expect(k.name, 'N');
    expect(k.description, 'd\ne');
  });
}
