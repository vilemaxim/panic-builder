import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/data/rules_models.dart';
import 'package:panic_at_the_dojo/domain/character.dart';
import 'package:panic_at_the_dojo/features/print/character_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('source-material character can be saved to styled PDF without glyph errors', () async {
    final root = Directory.current.path;
    final characterFile = File(
      '$root/test/fixtures/character_from_source_material.json',
    );
    final rulesFile = File('$root/assets/data/rules.json');

    expect(characterFile.existsSync(), isTrue);
    expect(rulesFile.existsSync(), isTrue);

    final characterJson =
        jsonDecode(characterFile.readAsStringSync()) as Map<String, dynamic>;
    final rulesJson = jsonDecode(rulesFile.readAsStringSync()) as Map<String, dynamic>;

    final character = Character.fromJson(characterJson);
    final rules = MergedRules.fromJson(rulesJson);

    final logs = <String>[];
    final bytes = await runZoned(
      () => buildCharacterPdfBytes(character, rules),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) => logs.add(message),
      ),
    );

    expect(bytes, isNotEmpty);
    // New first-pass layout intentionally renders one filled half + one blank half.
    expect(bytes.length, greaterThan(8 * 1024));

    final joinedLogs = logs.join('\n');
    expect(
      joinedLogs.contains('Unable to find a font to draw'),
      isFalse,
      reason: 'Terminal glyph error detected while generating PDF from fixture.',
    );

    final pdfText = latin1.decode(bytes, allowInvalid: true);
    expect(
      pdfText.contains('DejaVuSerif'),
      isTrue,
      reason: 'Expected embedded DejaVuSerif fonts for styled output.',
    );
  });
}
