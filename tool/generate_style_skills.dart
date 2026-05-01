// Merges style stance skills into assets/data/rules.json from the prose extract +
// styles already in rules.json (deep merge by id).
// Run from webapp/: dart run tool/generate_style_skills.dart
//
// The PDF paste file assets/data/_archetypes_styles_extract.txt is NOT loaded by the app at
// runtime. It exists only as an offline source for this generator (full stance mechanics per
// style) and for tool/sync_rules_from_sources.dart (short “{Style} is …” summaries patched into
// rules.json when that sentence appears in the extract).

import 'dart:convert';
import 'dart:io';

import 'package:panic_at_the_dojo/data/merge_rules.dart';

void main() {
  final root = Directory.current;
  final extractFile = File('${root.path}/assets/data/_archetypes_styles_extract.txt');
  final rulesFile = File('${root.path}/assets/data/rules.json');

  final extractRaw = extractFile.readAsStringSync().replaceAll('\r\n', '\n');
  final extract = extractRaw.replaceAll('\x0c', '\n');

  String clipSectionNoise(String body) {
    var b = body.trim();
    final archetypeCut =
        RegExp(r'\n\s*\n\s*\d*\s*\n\s*Archetype\s*:').firstMatch(b);
    if (archetypeCut != null) {
      b = b.substring(0, archetypeCut.start).trimRight();
    }
    b = b.replaceAll(RegExp(r'\n+\d+\s*$'), '').trimRight();
    return b.trim();
  }

  final rulesRoot =
      jsonDecode(rulesFile.readAsStringSync()) as Map<String, dynamic>;
  final styles = (rulesRoot['styles'] as List).cast<Map<String, dynamic>>();

  final sections = <String, String>{};
  final headerRe = RegExp(r'(^|\n)([^\n]{2,72} Style)\s*\n', multiLine: true);
  final ms = headerRe.allMatches(extract).toList();
  for (var i = 0; i < ms.length; i++) {
    final title = ms[i].group(2)!;
    final start = ms[i].end;
    final end = i + 1 < ms.length ? ms[i + 1].start : extract.length;
    var body = extract.substring(start, end).trim();
    body = body.replaceFirst(RegExp(r'^\d+\s*\n'), '');
    sections[title] = clipSectionNoise(body);
  }

  final tieredActionRe = RegExp(r'(?:^|\n)(\d+\+[^\n]*:\s*)([^\n]+)');
  final symphonyRe =
      RegExp(r'^[^\n:]+:\s*Symphony\s*$', multiLine: true);

  final newSkills = <Map<String, dynamic>>[];
  final stylePatches = <Map<String, dynamic>>[];
  final missing = <String>[];

  for (final st in styles) {
    final id = st['id'] as String;
    final name = st['name'] as String;
    final body = sections[name];
    if (body == null || body.trim().isEmpty) {
      missing.add('$name ($id)');
      continue;
    }

    final tiered = tieredActionRe.firstMatch(body);
    final symphony = symphonyRe.firstMatch(body);
    final skillName = symphony != null
        ? 'Symphony'
        : tiered != null
            ? tiered.group(2)!.trim()
            : name.replaceAll(RegExp(r'\s+Style$'), '').trim();

    final skillId = 'skill_style_$id';
    newSkills.add({
      'id': skillId,
      'name': skillName,
      'description': body,
    });
    stylePatches.add({'id': id, 'skillId': skillId});
  }

  if (missing.isNotEmpty) {
    stderr.writeln(
      'generate_style_skills: missing extract sections (${missing.length}):\n'
      '${missing.join('\n')}',
    );
  }

  final delta = <String, dynamic>{
    'skills': newSkills,
    'styles': stylePatches,
  };
  final merged = mergeRulesJson(rulesRoot, delta);
  const encoder = JsonEncoder.withIndent('  ');
  rulesFile.writeAsStringSync('${encoder.convert(merged)}\n');
  stdout.writeln(
    'Merged ${newSkills.length} style skills + skillId patches → ${rulesFile.path}',
  );
}
