import 'package:panic_at_the_dojo/data/rules_models.dart';

/// Minimal merged rules for widget tests (avoids rootBundle + spinner hang).
MergedRules minimalMergedRulesForTests() {
  return MergedRules.fromJson({
    'version': 1,
    'heroTypes': [
      {
        'id': 'focused',
        'name': 'Focused',
        'description': 'd',
        'restrictions': 'r',
        'archetypeSlots': 1,
      },
    ],
    'builds': [
      {'id': 'b1', 'name': 'B1', 'description': '', 'maxHp': 10, 'hpBars': 2, 'totalBars': 5},
    ],
    'archetypes': [
      {'id': 'a1', 'name': 'A1', 'description': '', 'abilitiesSummary': ''},
    ],
    'styles': [
      {'id': 's1', 'archetypeId': 'a1', 'name': 'S1', 'basicInfo': '', 'marginNotes': ''},
    ],
    'forms': [
      {'id': 'f1', 'name': 'F1', 'altNames': [], 'skillIds': ['k1', 'k2', 'k3']},
    ],
    'skills': [
      {'id': 'k1', 'name': 'K1', 'description': ''},
      {'id': 'k2', 'name': 'K2', 'description': ''},
      {'id': 'k3', 'name': 'K3', 'description': ''},
    ],
    'supers': [],
  });
}
