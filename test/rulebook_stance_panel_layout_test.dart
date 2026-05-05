import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panic_at_the_dojo/data/rules_models.dart';
import 'package:panic_at_the_dojo/features/character_sheet/widgets/rulebook_stance_panel.dart';

import 'test_infra/test_asset_scope.dart';

/// Minimal rules with Shadow Form (six d4 icons — widest dice row).
MergedRules _rulesWithShadowForm() {
  return MergedRules.fromJson({
    'version': 1,
    'heroTypes': [],
    'builds': [],
    'archetypes': [],
    'styles': [
      {
        'id': 'style_test',
        'archetypeId': 'arch_test',
        'name': 'Test Style',
        'basicInfo': 'Range: Close\nLine one.',
        'marginNotes': '',
      },
    ],
    'forms': [
      {
        'id': 'form_shadow',
        'name': 'Shadow Form',
        'altNames': <String>[],
        'skillIds': ['sk_a', 'sk_b', 'sk_c'],
      },
    ],
    'skills': [
      {'id': 'sk_a', 'name': 'A', 'description': ''},
      {'id': 'sk_b', 'name': 'B', 'description': ''},
      {'id': 'sk_c', 'name': 'C', 'description': ''},
    ],
    'supers': [],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RulebookStancePanel: narrow width + six dice does not overflow horizontally',
    (WidgetTester tester) async {
      final rules = _rulesWithShadowForm();
      final style = rules.styleById('style_test')!;
      final form = rules.formById('form_shadow')!;

      final caught = <FlutterErrorDetails>[];
      final prior = FlutterError.onError;
      FlutterError.onError = (details) {
        caught.add(details);
        prior?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = prior;
      });

      await tester.pumpWidget(
        TestAssetScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 900,
                child: SingleChildScrollView(
                  child: RulebookStancePanel(
                    style: style,
                    form: form,
                    rules: rules,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final problems = caught.where((d) {
        final o = d.exceptionAsString();
        return o.contains('A RenderFlex overflowed') ||
            o.contains('overflowed') ||
            o.contains('Unable to load asset');
      }).toList();

      expect(
        problems,
        isEmpty,
        reason:
            'Stance title bar must wrap dice within panel width; raster dice '
            'paths must resolve via pubspec assets.\n'
            '${problems.map((e) => e.exceptionAsString()).join('\n---\n')}',
      );
    },
  );
}
