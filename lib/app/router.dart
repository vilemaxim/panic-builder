import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/character_creation/creation_wizard_screen.dart';
import '../features/character_sheet/character_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/print/print_character_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreationWizardScreen(),
      ),
      GoRoute(
        path: '/character/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CharacterDetailScreen(characterId: id);
        },
      ),
      GoRoute(
        path: '/print/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PrintCharacterScreen(characterId: id);
        },
      ),
    ],
  );
}

/// Root [ConsumerStatefulWidget] holding [GoRouter] for hot reload stability.
class RoutedApp extends ConsumerStatefulWidget {
  const RoutedApp({super.key});

  @override
  ConsumerState<RoutedApp> createState() => _RoutedAppState();
}

class _RoutedAppState extends ConsumerState<RoutedApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Panic at the Dojo — Character Builder',
      theme: ref.watch(appThemeProvider),
      routerConfig: _router,
    );
  }
}

final appThemeProvider = Provider<ThemeData>((ref) {
  const paper = Color(0xFFF6EED6);
  const ink = Color(0xFF2F2418);
  const accent = Color(0xFF8B2C2B);
  const frame = Color(0xFF3B2B1E);
  const gold = Color(0xFFB48A3B);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: paper,
  );
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      surface: paper,
      onSurface: ink,
      primary: accent,
      onPrimary: Colors.white,
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'serif',
        color: ink,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'serif',
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: 'serif',
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: ink),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: ink),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: ink,
        letterSpacing: 0.3,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        color: ink,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFAEC),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: frame, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: accent,
      textColor: ink,
      subtitleTextStyle: TextStyle(color: Color(0xFF4B3B2A)),
    ),
    dividerTheme: const DividerThemeData(color: frame, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFAEC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: frame),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: frame),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
      labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
    ),
  );
});
