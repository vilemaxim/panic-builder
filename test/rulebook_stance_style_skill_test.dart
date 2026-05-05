import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panic_at_the_dojo/data/rules_models.dart';
import 'package:panic_at_the_dojo/features/character_sheet/widgets/rulebook_stance_panel.dart';

import 'test_infra/test_asset_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RulebookStancePanel uses style skill for action heading and style name on citation badge',
    (WidgetTester tester) async {
      final rules = MergedRules.fromJson({
        'version': 1,
        'heroTypes': [],
        'builds': [],
        'archetypes': [],
        'styles': [
          {
            'id': 'test_style_1',
            'archetypeId': 'arch',
            'name': 'Halcyon Style',
            'basicInfo': 'placeholder',
            'marginNotes': '',
            'skillId': 'skill_style_test_style_1',
          },
        ],
        'forms': [
          {
            'id': 'form_blaster',
            'name': 'Blaster Form',
            'altNames': <String>[],
            'skillIds': ['skill_form_blaster'],
          },
        ],
        'skills': [
          {
            'id': 'skill_style_test_style_1',
            'name': 'Purify',
            'description':
                'Range: 1-2\n\nWhen you purify, remove tokens.\n\nExtra paragraph.',
          },
          {
            'id': 'skill_form_blaster',
            'name': 'Basically Magic',
            'description': 'Rulebook skill body for Blaster.\r\n',
            'associatedForm': 'form_blaster',
          },
        ],
        'supers': [],
      });

      final st = rules.styleById('test_style_1')!;
      final fm = rules.formById('form_blaster')!;

      final caught = <FlutterErrorDetails>[];
      final prior = FlutterError.onError;
      FlutterError.onError = (details) {
        caught.add(details);
        prior?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = prior;
      });

      // Bounded viewport + pumpAndSettle (matches rulebook_stance_panel_layout_test): avoids
      // unbounded-layout quirks and waits for stance dice [Image.asset] frames on CI.
      await tester.pumpWidget(
        TestAssetScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 1600,
                child: SingleChildScrollView(
                  child: RulebookStancePanel(style: st, form: fm, rules: rules),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final layoutProblems = caught.where((d) {
        final o = d.exceptionAsString();
        return o.contains('RenderFlex overflowed') ||
            o.contains('overflowed') ||
            o.contains('Unable to load asset');
      }).toList();

      expect(
        layoutProblems,
        isEmpty,
        reason: layoutProblems
            .map((e) => e.exceptionAsString())
            .join('\n---\n'),
      );

      expect(tester.takeException(), isNull);

      expect(find.textContaining('Purify Action'), findsWidgets);
      expect(find.textContaining('Range: 1-2'), findsWidgets);
      expect(find.textContaining('purify'), findsWidgets);
      expect(find.textContaining('Halcyon'), findsWidgets);
      expect(find.textContaining('Blaster'), findsWidgets);
      expect(
        find.textContaining('Rulebook skill body for Blaster'),
        findsWidgets,
      );
    },
  );
}
