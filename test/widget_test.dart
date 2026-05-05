import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panic_at_the_dojo/app/providers.dart';
import 'package:panic_at_the_dojo/app/router.dart';
import 'package:panic_at_the_dojo/domain/character.dart';
import 'package:panic_at_the_dojo/features/home/home_screen.dart';

import 'test_rules.dart';

/// Avoids [GoRouter] + [MaterialApp.router]: on Linux CI, route transition / shell
/// scheduling can keep [WidgetTester.pumpAndSettle] from finishing before timeout,
/// even when [HomeScreen] itself is fine (same overrides pass in create_character).
class _HomeTestHarness extends ConsumerWidget {
  const _HomeTestHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: ref.watch(appThemeProvider),
      home: const HomeScreen(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows entry actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mergedRulesProvider.overrideWith((ref) => minimalMergedRulesForTests()),
          charactersListProvider.overrideWith((ref) => const <Character>[]),
        ],
        child: const _HomeTestHarness(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(const Key('home_create_character')), findsOneWidget);
    expect(find.byKey(const Key('home_upload_character_json')), findsOneWidget);
    expect(find.textContaining('Create new character'), findsWidgets);
    expect(find.textContaining('Upload character JSON'), findsWidgets);
  });
}
