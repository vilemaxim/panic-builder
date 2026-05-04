import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/features/character_sheet/widgets/form_dice_catalog.dart';

/// Guards against Flutter Web 404s / missing assets when serving the app:
/// - bundled rules loaded by [RulesRepository]
/// - dice PNGs referenced from [form_dice_catalog]
void main() {
  test(
    'pubspec.yaml explicitly lists each stance dice PNG (web bundle regression)',
    () {
      final pubspec = File('${Directory.current.path}/pubspec.yaml').readAsStringSync();
      for (final path in kBundledDiceIconAssetPaths) {
        expect(
          pubspec.contains('- $path'),
          isTrue,
          reason:
              'Add explicit `- $path` under flutter.assets so `flutter build web` '
              'ships raster dice (directory-only registration omitted them).',
        );
      }
      expect(
        pubspec.contains('- assets/images/branding/panic_at_the_dojo_logo.png'),
        isTrue,
        reason:
            'Home screen shows the wordmark; list it explicitly under flutter.assets.',
      );
    },
  );

  test(
    'pubspec.yaml explicitly lists bundled rules.json (web bundle regression)',
    () {
      final pubspec =
          File('${Directory.current.path}/pubspec.yaml').readAsStringSync();
      expect(
        pubspec.contains('- assets/data/rules.json'),
        isTrue,
        reason:
            'Add `- assets/data/rules.json` under flutter.assets so '
            '`flutter build web` ships merged rules.',
      );
    },
  );

  test('rules.json exists and includes merged stance/skills payload', () {
    final root = Directory.current.path;
    final f = File('$root/assets/data/rules.json');
    expect(
      f.existsSync(),
      isTrue,
      reason: 'Add assets/data/rules.json (see tool/generate_style_skills.dart)',
    );
    final decoded = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final skillList = decoded['skills'] as List<dynamic>;
    final styleList = decoded['styles'] as List<dynamic>;
    expect(skillList.length, greaterThanOrEqualTo(55));
    expect(styleList.length, greaterThanOrEqualTo(55));
  });
}
