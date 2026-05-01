import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panic_at_the_dojo/data/rules_models.dart';
import 'package:panic_at_the_dojo/features/character_sheet/widgets/rulebook_stance_panel.dart';

void main() {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RulebookStancePanel(
                style: st,
                form: fm,
                rules: rules,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Purify Action'), findsOneWidget);
      final plainRich = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((r) => r.text.toPlainText(includeSemanticsLabels: false))
          .join('\n');
      final plainText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      final blob = '$plainRich\n$plainText';
      expect(blob, contains('Range: 1-2'));
      expect(blob, contains('purify'));
      expect(blob, contains('Halcyon'));
      expect(blob, contains('Blaster'));
      expect(blob, contains('Rulebook skill body for Blaster'));
      expect(blob, isNot(contains('Basically Magic')));
    },
  );
}
