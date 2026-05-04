import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/data/rulebook_style_range.dart';
import 'package:panic_at_the_dojo/data/rules_models.dart';

void main() {
  test('tryParseNumericStyleRangeToken parses single and span', () {
    expect(tryParseNumericStyleRangeToken('3')?.min, 3);
    expect(tryParseNumericStyleRangeToken('3')?.max, 3);
    expect(tryParseNumericStyleRangeToken('1-2')?.min, 1);
    expect(tryParseNumericStyleRangeToken('1-2')?.max, 2);
    expect(tryParseNumericStyleRangeToken('4 \u2013 1')?.min, 1);
    expect(tryParseNumericStyleRangeToken('4 \u2013 1')?.max, 4);
    expect(tryParseNumericStyleRangeToken('Melee'), isNull);
  });

  test('Blaster maxRange +1 updates stance subtitle with tag', () {
    final style = RuleStyle(
      id: 'st',
      archetypeId: 'a',
      name: 'Test Style',
      basicInfo: '',
      range: '1-2',
    );
    final form = RuleForm(
      id: 'form_blaster',
      name: 'Blaster Form',
      altNames: const [],
      skillIds: const ['s1'],
      maxRange: 1,
      choices: const [],
    );
    expect(
      formatStanceRangeSubtitle(style, null, form, 'Dragon'),
      'Range: 1-3 (1-2 + Dragon)',
    );
  });

  test('single-number style range with max delta becomes span', () {
    final style = RuleStyle(
      id: 'st',
      archetypeId: 'a',
      name: 'S',
      basicInfo: '',
      range: '2',
    );
    final form = RuleForm(
      id: 'form_blaster',
      name: 'Blaster Form',
      altNames: const [],
      skillIds: const [],
      maxRange: 1,
      choices: const [],
    );
    expect(
      formatStanceRangeSubtitle(style, null, form, 'Blaster'),
      'Range: 2-3 (2 + Blaster)',
    );
  });

  test('no form modifiers keeps style token only', () {
    final style = RuleStyle(
      id: 'st',
      archetypeId: 'a',
      name: 'S',
      basicInfo: '',
      range: '1',
    );
    final form = RuleForm(
      id: 'form_dance',
      name: 'Dance Form',
      altNames: const [],
      skillIds: const [],
      choices: const [],
    );
    expect(formatStanceRangeSubtitle(style, null, form, 'Circle'), 'Range: 1');
  });

  test('Control form choice +3 max uses choice deltas not form defaults', () {
    final style = RuleStyle(
      id: 'st',
      archetypeId: 'a',
      name: 'S',
      basicInfo: '',
      range: '1-2',
    );
    const choice = RuleFormChoice(
      id: 'control_max_plus_3',
      text: 'Increase max by 3',
      maxRange: 3,
    );
    final form = RuleForm(
      id: 'form_control',
      name: 'Control Form',
      altNames: const [],
      skillIds: const [],
      choices: const [choice],
    );
    expect(
      formatStanceRangeSubtitle(
        style,
        null,
        form,
        'Watcher',
        selectedFormChoice: choice,
      ),
      'Range: 1-5 (1-2 + Watcher)',
    );
  });

  test('Control form choice sets absolute min to 1', () {
    final style = RuleStyle(
      id: 'st',
      archetypeId: 'a',
      name: 'S',
      basicInfo: '',
      range: '2-4',
    );
    const choice = RuleFormChoice(
      id: 'control_min_to_1',
      text: 'Set min to 1',
      absoluteMin: 1,
    );
    final form = RuleForm(
      id: 'form_control',
      name: 'Control Form',
      altNames: const [],
      skillIds: const [],
      choices: const [choice],
    );
    expect(
      formatStanceRangeSubtitle(
        style,
        null,
        form,
        'Control',
        selectedFormChoice: choice,
      ),
      'Range: 1-4 (2-4 + Control)',
    );
  });
}
