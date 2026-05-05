import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// [rootBundle] may not resolve keys via the test embedder on some CI runners.
/// `flutter test` still writes the bundle under `<project>/build/unit_test_assets/`,
/// but the isolate [Directory.current] is not always the package root — resolve
/// roots explicitly (including [GITHUB_WORKSPACE]).
class UnitTestAssetsFallbackBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (e, st) {
      if (kIsWeb) {
        Error.throwWithStackTrace(e, st);
      }
      final fromDisk = _tryLoadFromUnitTestAssetsDir(key);
      if (fromDisk != null) {
        return fromDisk;
      }
      Error.throwWithStackTrace(e, st);
    }
  }
}

ByteData? _tryLoadFromUnitTestAssetsDir(String key) {
  final seen = <String>{};
  for (final root in _projectRootCandidates()) {
    final marker = root.path;
    if (!seen.add(marker)) continue;

    final file = File(p.join(marker, 'build', 'unit_test_assets', key));
    if (file.existsSync()) {
      return ByteData.sublistView(file.readAsBytesSync());
    }
  }
  return null;
}

/// Yields directories that contain this project's [pubspec.yaml].
Iterable<Directory> _projectRootCandidates() sync* {
  for (final envPath in <String?>[
    Platform.environment['GITHUB_WORKSPACE'],
    Platform.environment['CI_PROJECT_DIR'],
  ]) {
    if (envPath == null || envPath.isEmpty) continue;
    final envDir = Directory(envPath);
    if (_hasPubspec(envDir)) {
      yield envDir;
    }
  }

  final fromCwd = _walkUpToPubspec(Directory.current);
  if (fromCwd != null) {
    yield fromCwd;
  }

  try {
    final scriptDir = File.fromUri(Platform.script).parent;
    final fromScript = _walkUpToPubspec(scriptDir);
    if (fromScript != null) {
      yield fromScript;
    }
  } catch (_) {
    // Platform.script unavailable in some embedders.
  }
}

bool _hasPubspec(Directory dir) =>
    File(p.join(dir.path, 'pubspec.yaml')).existsSync();

Directory? _walkUpToPubspec(Directory start) {
  var dir = start;
  for (var i = 0; i < 48; i++) {
    if (_hasPubspec(dir)) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return null;
    }
    dir = parent;
  }
  return null;
}

/// Single bundle instance so [AssetManifest] caching stays hot across pumps.
final AssetBundle kWidgetTestAssetBundle = UnitTestAssetsFallbackBundle();

/// Pumps [Image.asset] with a [DefaultAssetBundle] that can load the unit-test
/// asset directory when the default test [rootBundle] is missing a key.
class TestAssetScope extends StatelessWidget {
  const TestAssetScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultAssetBundle(bundle: kWidgetTestAssetBundle, child: child);
  }
}
