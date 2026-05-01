// Merges canonical prose into assets/data/rules.json:
// - Forms + form skills from ../../Cards/html/cards_forms.html (repo sibling of webapp/)
// - Style cards (range, passive, tiered actions) from ../../Cards/html/cards_styles.html
// - Style short descriptions from assets/data/_archetypes_styles_extract.txt
//
// Run from webapp/: dart run tool/sync_rules_from_sources.dart

import 'dart:convert';
import 'dart:io';

import 'package:panic_at_the_dojo/data/merge_rules.dart';

String decodeCardsInnerHtml(String raw) {
  var t = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&bull;', '\u2022');
  t = t.replaceAll(RegExp(r'<strong>|</strong>'), '');
  t = t.replaceAll(RegExp(r'<span[^>]*>', caseSensitive: false), '');
  t = t.replaceAll('</span>', '');
  t = t.replaceAll(RegExp(r'<[^>]+>'), '');
  t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  t = t.replaceAll(RegExp(r'^ +', multiLine: true), '');
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

List<String> sliceStyleCards(String html) {
  const open = '<div class="style-card">';
  final slices = <String>[];
  var searchStart = 0;
  while (true) {
    final openIdx = html.indexOf(open, searchStart);
    if (openIdx < 0) break;
    var depth = 1;
    var pos = openIdx + open.length;
    while (pos < html.length && depth > 0) {
      final nextOpen = html.indexOf('<div', pos);
      final nextClose = html.indexOf('</div>', pos);
      if (nextClose < 0) break;
      final openBeforeClose = nextOpen >= 0 && nextOpen < nextClose;
      if (openBeforeClose) {
        depth++;
        pos = nextOpen + 4;
      } else {
        depth--;
        pos = nextClose + 6;
      }
    }
    if (depth != 0) break;
    slices.add(html.substring(openIdx, pos));
    searchStart = pos;
  }
  return slices;
}

({
  String name,
  String range,
  String passive,
  List<Map<String, String>> actions,
})? parsePrintedStyleCard(String slice) {
  final nameMatch =
      RegExp(r'<span class="style-name">([^<]*)</span>').firstMatch(slice);
  final styleName = nameMatch?.group(1)?.trim();
  if (styleName == null || styleName.isEmpty) return null;

  final rangeMatch =
      RegExp(r'<span class="style-range">([^<]*)</span>').firstMatch(slice);
  var rangeLine = rangeMatch?.group(1)?.trim() ?? '';
  rangeLine = decodeCardsInnerHtml(rangeLine)
      .replaceFirst(RegExp(r'^Range:\s*', caseSensitive: false), '')
      .trim()
      .replaceAll('–', '-')
      .replaceAll('—', '-');

  final passiveMatch = RegExp(
    r'<div class="passive-text">([\s\S]*?)</div>',
    dotAll: true,
  ).firstMatch(slice);
  final passiveText = decodeCardsInnerHtml(passiveMatch?.group(1) ?? '').trim();

  final actions = <Map<String, String>>[];
  final actionPairRe = RegExp(
    r'<div class="action-header">([\s\S]*?)</div>\s*<div class="action-body">([\s\S]*?)</div>',
    dotAll: true,
  );
  for (final m in actionPairRe.allMatches(slice)) {
    final heading = decodeCardsInnerHtml(m.group(1) ?? '')
        .trim()
        .replaceAll(RegExp(r' +'), ' ');
    final body = decodeCardsInnerHtml(m.group(2) ?? '').trim();
    if (heading.isEmpty && body.isEmpty) continue;
    actions.add({'heading': heading, 'description': body});
  }

  return (
    name: styleName,
    range: rangeLine,
    passive: passiveText,
    actions: actions,
  );
}

void main() {
  final webappDir = Directory.current;
  final rulesFile = File('${webappDir.path}/assets/data/rules.json');
  final extractFile = File('${webappDir.path}/assets/data/_archetypes_styles_extract.txt');
  final cardsFile = File('${webappDir.parent.path}/Cards/html/cards_forms.html');
  final stylesCardsFile =
      File('${webappDir.parent.path}/Cards/html/cards_styles.html');

  if (!cardsFile.existsSync()) {
    stderr.writeln('Missing ${cardsFile.path} (expected Cards repo next to webapp/).');
    exitCode = 1;
    return;
  }
  if (!stylesCardsFile.existsSync()) {
    stderr.writeln(
      'Missing ${stylesCardsFile.path} (expected Cards repo next to webapp/).',
    );
    exitCode = 1;
    return;
  }

  final winterTailFile =
      File('${webappDir.path}/assets/data/_winter_tail.txt');
  final extractCombined = [
    extractFile.readAsStringSync(),
    if (winterTailFile.existsSync()) winterTailFile.readAsStringSync(),
  ].join('\n\n').replaceAll('\r\n', '\n').replaceAll('\x0c', '\n');

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

  /// Same section keys as tool/generate_style_skills.dart (full stance bodies).
  Map<String, String> styleSectionsFromExtract(String extract) {
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
    return sections;
  }

  String? styleDescriptionLine(String sectionBody) {
    final lineMatch = RegExp(
      r'^[^\n]+ Style is .+$',
      multiLine: true,
    ).firstMatch(sectionBody);
    return lineMatch?.group(0)?.trim();
  }

  final styleSections = styleSectionsFromExtract(extractCombined);
  final rulesMap =
      jsonDecode(rulesFile.readAsStringSync()) as Map<String, dynamic>;
  final styles = (rulesMap['styles'] as List).cast<Map<String, dynamic>>();

  final stylesHtml = stylesCardsFile.readAsStringSync();
  final styleCardByName = <String, Map<String, dynamic>>{};
  for (final slice in sliceStyleCards(stylesHtml)) {
    final parsed = parsePrintedStyleCard(slice);
    if (parsed == null) continue;
    styleCardByName[parsed.name] = {
      'range': parsed.range,
      'passive': parsed.passive,
      'actions': parsed.actions,
    };
  }

  final ruleStyleNames = styles.map((s) => s['name'] as String).toSet();
  final missingPrintedCards = ruleStyleNames.difference(styleCardByName.keys.toSet());
  if (missingPrintedCards.isNotEmpty) {
    stderr.writeln(
      'cards_styles.html: missing printed cards for ${missingPrintedCards.length} styles:',
    );
    for (final n in missingPrintedCards) {
      stderr.writeln('  - $n');
    }
    exitCode = 1;
    return;
  }

  final stylePatches = <Map<String, dynamic>>[];
  var stylesMissingDesc = 0;
  for (final st in styles) {
    final id = st['id'] as String;
    final name = st['name'] as String;
    final patch = <String, dynamic>{
      'id': id,
      ...styleCardByName[name]!,
    };
    final body = styleSections[name];
    if (body == null || body.isEmpty) {
      stylesMissingDesc++;
      stylePatches.add(patch);
      continue;
    }
    final desc = styleDescriptionLine(body);
    if (desc == null || desc.isEmpty) {
      stylesMissingDesc++;
      stylePatches.add(patch);
      continue;
    }
    patch['description'] = desc;
    stylePatches.add(patch);
  }

  final cardsHtml = cardsFile.readAsStringSync();

  /// Maps printed card title → bundled rules form id.
  const titleToFormId = <String, String>{
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

  final formPatches = <Map<String, dynamic>>[];

  for (final entry in titleToFormId.entries) {
    final cardTitle = entry.key;
    final formId = entry.value;
    final needle = '<!-- $cardTitle -->';
    final start = cardsHtml.indexOf(needle);
    if (start < 0) {
      stderr.writeln('cards_forms.html: missing card $cardTitle');
      exitCode = 1;
      return;
    }
    final after = cardsHtml.substring(start + needle.length);
    final cardEnd = after.indexOf('<!--');
    final cardSlice =
        cardEnd < 0 ? after : after.substring(0, cardEnd);

    final altMatch =
        RegExp(r'<div class="form-alt">([^<]*)</div>').firstMatch(cardSlice);
    final altLine = altMatch?.group(1)?.trim() ?? '';
    List<String> altNames = [];
    if (altLine.toLowerCase().startsWith('alt:')) {
      final rest = altLine.substring(4).trim();
      altNames = rest
          .split(RegExp(r'\s*/\s*'))
          .map((e) =>
              e.replaceFirst(RegExp(r'\s+Form$', caseSensitive: false), '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final passiveMatch = RegExp(
      r'<div class="form-passive-text">(.*?)</div>',
      dotAll: true,
    ).firstMatch(cardSlice);
    final passiveRaw = passiveMatch?.group(1) ?? '';
    final passiveText = decodeCardsInnerHtml(passiveRaw);

    final diceInts = <int>[];
    final headerDiceMatch = RegExp(
      r'<div class="form-header">([\s\S]*?)</div>\s*<div class="form-passive">',
    ).firstMatch(cardSlice);
    if (headerDiceMatch != null) {
      final inner = headerDiceMatch.group(1)!;
      for (final m in RegExp(r'<div class="die">(\d+)</div>').allMatches(inner)) {
        diceInts.add(int.parse(m.group(1)!));
      }
    }

    final actions = <Map<String, String>>[];
    final actionPairRe = RegExp(
      r'<div class="action-header">([\s\S]*?)</div>\s*<div class="action-body">([\s\S]*?)</div>',
      dotAll: true,
    );
    for (final m in actionPairRe.allMatches(cardSlice)) {
      final heading = decodeCardsInnerHtml(m.group(1) ?? '')
          .trim()
          .replaceAll(RegExp(r' +'), ' ');
      final body = decodeCardsInnerHtml(m.group(2) ?? '').trim();
      if (heading.isEmpty && body.isEmpty) continue;
      actions.add({'heading': heading, 'description': body});
    }

    formPatches.add({
      'id': formId,
      'altNames': altNames,
      'description': passiveText,
      'passive': passiveText,
      'dice': diceInts,
      'actions': actions,
    });
  }

  final delta = <String, dynamic>{
    'forms': formPatches,
    'styles': stylePatches,
  };
  final merged = mergeRulesJson(rulesMap, delta);
  const encoder = JsonEncoder.withIndent('  ');
  rulesFile.writeAsStringSync('${encoder.convert(merged)}\n');

  stdout.writeln(
    'Updated rules.json: ${formPatches.length} forms, '
    '${stylePatches.length} styles '
    '(range/passive/actions from cards + extract descriptions; '
    '$stylesMissingDesc styles had no matching extract section or narrative line).',
  );
  stdout.writeln(
    'Form rulebook skills: dart run tool/sync_form_skills_from_cards_html.dart',
  );
  stdout.writeln(
    'Refresh extract-backed style skills: dart run tool/generate_style_skills.dart',
  );
}
