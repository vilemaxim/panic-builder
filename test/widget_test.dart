import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panic_at_the_dojo/app/providers.dart';
import 'package:panic_at_the_dojo/app/router.dart';

import 'test_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows entry actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mergedRulesProvider.overrideWith((ref) async => minimalMergedRulesForTests()),
          charactersListProvider.overrideWith((ref) async => const []),
        ],
        child: const RoutedApp(),
      ),
    );

    // Wait for overridden [FutureProvider]s (same pattern as create_character_button_test).
    await tester.pumpAndSettle();
    expect(find.textContaining('Create new character'), findsOneWidget);
    expect(find.textContaining('Upload character JSON'), findsOneWidget);
  });
}
