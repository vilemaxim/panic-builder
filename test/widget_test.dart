import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panic_at_the_dojo/app/providers.dart';
import 'package:panic_at_the_dojo/app/router.dart';
import 'package:panic_at_the_dojo/domain/character.dart';

import 'test_infra/test_asset_scope.dart';
import 'test_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// No widgets: validates overrides alone (rules + empty character list).
  test(
    'Home dependencies: merged rules + character list providers resolve',
    () {
      final container = ProviderContainer(
        overrides: [
          mergedRulesProvider.overrideWith(
            (ref) => minimalMergedRulesForTests(),
          ),
          charactersListProvider.overrideWith((ref) => const <Character>[]),
        ],
      );
      addTearDown(container.dispose);

      final rules = container.read(mergedRulesProvider);
      final list = container.read(charactersListProvider);
      expect(rules.hasValue, isTrue, reason: '$rules');
      expect(list.hasValue, isTrue, reason: '$list');
      expect(list.requireValue, isEmpty);
    },
  );

  /// Same shell + overrides + [pumpAndSettle] as [create_character_button_test] before the tap.
  /// CI already proves that path works; do not use a separate MaterialApp/home harness.
  testWidgets('Home shows entry actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mergedRulesProvider.overrideWith(
            (ref) => minimalMergedRulesForTests(),
          ),
          charactersListProvider.overrideWith((ref) => const <Character>[]),
        ],
        child: const TestAssetScope(child: RoutedApp()),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Create new character'), findsWidgets);
    expect(find.textContaining('Upload character JSON'), findsWidgets);
  });
}
