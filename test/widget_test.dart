import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:panic_at_the_dojo/app/providers.dart';
import 'package:panic_at_the_dojo/app/router.dart';
import 'package:panic_at_the_dojo/domain/character.dart';
import 'package:panic_at_the_dojo/features/home/home_screen.dart';

import 'test_rules.dart';

/// Avoids [GoRouter] + [MaterialApp.router]: router-driven frames can prevent
/// [pumpAndSettle] from completing on headless Linux CI.
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

  /// No assets, no router, no layout: if this fails on CI, overrides are wrong.
  test('Home dependencies: merged rules + character list providers resolve', () {
    final container = ProviderContainer(
      overrides: [
        mergedRulesProvider.overrideWith((ref) => minimalMergedRulesForTests()),
        charactersListProvider.overrideWith((ref) => const <Character>[]),
      ],
    );
    addTearDown(container.dispose);

    final rules = container.read(mergedRulesProvider);
    final list = container.read(charactersListProvider);
    expect(rules.hasValue, isTrue, reason: '$rules');
    expect(list.hasValue, isTrue, reason: '$list');
    expect(list.requireValue, isEmpty);
  });

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

    // FutureProvider may emit loading then data across frames; image decode can schedule
    // extra frames. Avoid pumpAndSettle (never completes on some headless CI setups).
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('home_create_character')).evaluate().isNotEmpty &&
          find.byKey(const Key('home_upload_character_json')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(tester.takeException(), isNull);

    expect(
      find.byKey(const Key('home_create_character')),
      findsOneWidget,
      reason: 'Home data branch not shown (still loading?) or Key missing from '
          'lib/features/home/home_screen.dart on this commit.',
    );
    expect(
      find.byKey(const Key('home_upload_character_json')),
      findsOneWidget,
      reason: 'Home data branch not shown (still loading?) or Key missing from '
          'lib/features/home/home_screen.dart on this commit.',
    );
    expect(find.textContaining('Create new character'), findsWidgets);
    expect(find.textContaining('Upload character JSON'), findsWidgets);
  });
}
