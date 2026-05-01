// Reads Cards/html/cards_skills.html (sibling of webapp/) and updates assets/data/rules.json:
// - Removes fabricated form mechanic skills (*_core / *_tempo / *_finisher).
// - Adds one rulebook skill per form (name + description + associatedForm).
//
// Run from webapp/: dart run tool/sync_form_skills_from_cards_html.dart

import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  final rulesFile = File('${root.path}/assets/data/rules.json');
  final skillsHtml = File('${root.parent.path}/Cards/html/cards_skills.html');

  if (!skillsHtml.existsSync()) {
    stderr.writeln('Missing ${skillsHtml.path}');
    exitCode = 1;
    return;
  }

  const formNameToId = <String, String>{
    'Blaster Form': 'form_blaster',
    'Control Form': 'form_control',
    'Dance Form': 'form_dance',
    'Iron Form': 'form_iron',
    'One-Two Form': 'form_one_two',
    'Power Form': 'form_power',
    'Reversal Form': 'form_reversal',
    'Shadow Form': 'form_shadow',
    'Song Form': 'form_song',
    'Vigilance Form': 'form_vigilance',
    'Wild Form': 'form_wild',
    'Zen Form': 'form_zen',
  };

  String stripTags(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  final html = skillsHtml.readAsStringSync();
  final cards = html.split('<div class="skill-card">').skip(1);

  final byFormId = <String, ({String name, String description})>{};
  for (final chunk in cards) {
    if (chunk.contains('_ _ _ _')) continue;

    final nameMatch =
        RegExp(r'<div class="skill-name">([^<]+)</div>').firstMatch(chunk);
    final ruleMatch =
        RegExp(r'<div class="skill-rule">([^<]*)</div>', dotAll: true)
            .firstMatch(chunk);
    final srcMatch =
        RegExp(r'<div class="skill-source">From:\s*([^<]+)</div>')
            .firstMatch(chunk);

    if (nameMatch == null || ruleMatch == null || srcMatch == null) continue;

    final skillName = stripTags(nameMatch.group(1)!);
    final description = stripTags(ruleMatch.group(1)!);
    var formLine = stripTags(srcMatch.group(1)!);
    formLine = formLine.replaceFirst(RegExp(r'^From:\s*'), '').trim();

    final formId = formNameToId[formLine];
    if (formId == null) {
      stderr.writeln('Unknown form on skill card: "$formLine"');
      continue;
    }
    byFormId[formId] = (name: skillName, description: description);
  }

  final rules = jsonDecode(rulesFile.readAsStringSync()) as Map<String, dynamic>;
  final skills = (rules['skills'] as List).cast<Map<String, dynamic>>();
  final forms = (rules['forms'] as List).cast<Map<String, dynamic>>();

  final removeIds = <String>{};
  for (final fid in formNameToId.values) {
    final slug = fid.replaceFirst('form_', '');
    for (final sfx in ['core', 'tempo', 'finisher']) {
      removeIds.add('skill_${slug}_$sfx');
    }
  }

  skills.removeWhere((s) => removeIds.contains(s['id'] as String));

  for (final entry in byFormId.entries) {
    final formId = entry.key;
    final skillId = 'skill_$formId';
    final data = entry.value;

    skills.removeWhere((s) => s['id'] == skillId);
    skills.add({
      'id': skillId,
      'name': data.name,
      'description': data.description,
      'associatedForm': formId,
    });

    for (final f in forms) {
      if (f['id'] == formId) {
        f['skillIds'] = [skillId];
        break;
      }
    }
  }

  skills.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  const encoder = JsonEncoder.withIndent('  ');
  rulesFile.writeAsStringSync('${encoder.convert(rules)}\n');
  stdout.writeln(
    'Updated ${byFormId.length} form skills in ${rulesFile.path}; '
    'removed ${removeIds.length} fabricated ids.',
  );
}
