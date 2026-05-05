import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panic_at_the_dojo/app/providers.dart';
import 'package:panic_at_the_dojo/app/router.dart';
import 'package:panic_at_the_dojo/domain/character.dart';

import 'test_infra/test_asset_scope.dart';
import 'test_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'pressing Create new character navigates to the builder without throwing',
    (tester) async {
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

      await tester.tap(find.textContaining('Create new character'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Character Sheet Builder'), findsOneWidget);
    },
  );
}
