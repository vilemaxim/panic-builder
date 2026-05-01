import 'package:flutter_test/flutter_test.dart';

import 'package:panic_at_the_dojo/data/rules_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merged rules load from bundled assets without throwing', () async {
    final repo = RulesRepository();
    final rules = await repo.load();
    expect(rules.archetypes, isNotEmpty);
    expect(rules.heroTypes, isNotEmpty);
    expect(rules.buildById('bulky')?.name, 'Bulky');
  });
}
