import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panic_at_the_dojo/app/providers.dart';
import 'package:panic_at_the_dojo/app/router.dart';
import 'package:panic_at_the_dojo/domain/character.dart';

import 'test_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows entry actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // FutureProvider overrides may return [FutureOr]: sync values resolve in the same
          // turn as sync (see Riverpod handleFuture), avoiding CI-only microtask ordering.
          mergedRulesProvider.overrideWith((ref) => minimalMergedRulesForTests()),
          charactersListProvider.overrideWith((ref) => const <Character>[]),
        ],
        child: const RoutedApp(),
      ),
    );

    // Wait for overridden [FutureProvider]s (same pattern as create_character_button_test).
    await tester.pumpAndSettle();
    // At least one visible label (avoid findsOneWidget: some Flutter builds expose an extra
    // semantics/text match for the same control on Linux CI).
    expect(find.textContaining('Create new character'), findsWidgets);
    expect(find.textContaining('Upload character JSON'), findsWidgets);
  });
}
