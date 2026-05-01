import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/features/print/character_pdf.dart';

/// Terminal regression (Chrome / `printing` PDF): default PDF fonts are
/// Helvetica-family and cannot render common punctuation from rulebook text
/// (em dash U+2014, bullet U+2022), which spams the console and can destabilize
/// the web tooling session.
///
/// This file-level guard fails if those characters are reintroduced as literals
/// in [character_pdf.dart]. Dynamic rule/character strings are normalized in code.
void main() {
  test(
    'character_pdf.dart must not embed U+2014 / U+2022 (Helvetica-unsafe literals)',
    () {
      final path = '${Directory.current.path}/lib/features/print/character_pdf.dart';
      final src = File(path).readAsStringSync();
      expect(
        src.contains('\u2014'),
        isFalse,
        reason: 'Remove em dashes from PDF literals or route text through '
            'normalizePdfTextForHelvetica.',
      );
      expect(
        src.contains('\u2022'),
        isFalse,
        reason: 'Remove bullet characters from PDF literals or route text through '
            'normalizePdfTextForHelvetica.',
      );
    },
  );

  test('normalizePdfTextForHelvetica maps rulebook punctuation to ASCII', () {
    expect(
      normalizePdfTextForHelvetica('a${String.fromCharCode(0x2014)}b'),
      'a--b',
    );
    expect(
      normalizePdfTextForHelvetica('x${String.fromCharCode(0x2022)}y'),
      'x* y',
    );
    expect(
      normalizePdfTextForHelvetica('n${String.fromCharCode(0x2212)}1'),
      'n-1',
    );
    expect(
      normalizePdfTextForHelvetica('wait${String.fromCharCode(0x2026)}'),
      'wait...',
    );
    expect(
      normalizePdfTextForHelvetica("it${String.fromCharCode(0x2019)}s"),
      "it's",
    );
  });
}
