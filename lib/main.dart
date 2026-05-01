import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'data/character_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    setUrlStrategy(const HashUrlStrategy());
  }

  final storage = CharacterStorage();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [characterStorageProvider.overrideWithValue(storage)],
      child: const RoutedApp(),
    ),
  );
}
