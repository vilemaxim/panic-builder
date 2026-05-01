import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/features/print/character_pdf.dart';

/// Walks JSON string leaves (no cycles in decoded JSON).
Iterable<String> _allJsonStrings(dynamic node) sync* {
  if (node is String) {
    yield node;
    return;
  }
  if (node is Map) {
    for (final v in node.values) {
      yield* _allJsonStrings(v);
    }
    return;
  }
  if (node is List) {
    for (final e in node) {
      yield* _allJsonStrings(e);
    }
  }
}

void main() {
  /// Code points that caused `Unable to find a font to draw` for built-in PDF
  /// fonts in Chrome when printing preview laid out rulebook text (terminal).
  const terminalGlyphErrors = <int>[0x2014, 0x2022];

  test(
    'bundled rules.json: normalizePdfTextForHelvetica removes PDF glyph errors',
    () {
      final path = '${Directory.current.path}/assets/data/rules.json';
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: 'Run tests from project root.');

      final raw = f.readAsStringSync();
      final hasTerminalChars = terminalGlyphErrors.any(
        (cp) => raw.contains(String.fromCharCode(cp)),
      );
      expect(
        hasTerminalChars,
        isTrue,
        reason: 'rules.json should contain unicode punctuation so this test '
            'actually guards the normalizer.',
      );

      final decoded = jsonDecode(raw) as Object;
      final strings = _allJsonStrings(decoded).toList();
      expect(strings, isNotEmpty);

      for (var i = 0; i < strings.length; i++) {
        final out = normalizePdfTextForHelvetica(strings[i]);
        for (final cp in terminalGlyphErrors) {
          expect(
            out.contains(String.fromCharCode(cp)),
            isFalse,
            reason: 'After normalization, string leaf index $i still contains '
                'U+${cp.toRadixString(16).toUpperCase()} (see terminal PDF errors).',
          );
        }
      }
    },
  );
}
