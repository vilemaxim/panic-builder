// Auto-loaded by `flutter test`: flutter.dev/to/flutter-test-config
//
// On some CI runners (e.g. GitHub Actions) the flutter_tester engine doesn't
// wire up the `flutter/assets` platform channel, so `rootBundle.load(...)`
// fails with "Unable to load asset: AssetManifest.bin" even though the same
// tests pass locally. Detecting that exact embedder bug from inside the Dart
// VM is unreliable, so instead we install a global mock handler for the asset
// channel that resolves keys directly from disk:
//
//   1. <project>/build/unit_test_assets/<key>   (built by `flutter test`)
//   2. <project>/<key>                          (raw source tree)
//   3. for AssetManifest.bin specifically, an empty manifest as a last resort
//      so `AssetImage.obtainKey` falls back to the original key (which we
//      then resolve via #2).
//
// `<project>` is discovered via env vars and pubspec.yaml lookup so we work
// regardless of the test isolate's `Directory.current`.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const String _kFlutterWidgetTestProjectRootEnv =
    'FLUTTER_WIDGET_TEST_PROJECT_ROOT';
const String _kAssetManifestKey = 'AssetManifest.bin';
const String _kAssetChannel = 'flutter/assets';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMessageHandler(_kAssetChannel, _handleAssetChannel);
  }

  await testMain();
}

Future<ByteData?> _handleAssetChannel(ByteData? message) async {
  if (message == null) return null;
  final raw = utf8.decode(message.buffer.asUint8List());
  // PlatformAssetBundle URL-encodes the key before sending; decode here.
  final key = Uri.decodeFull(raw);
  return _loadAssetFromDisk(key);
}

ByteData? _loadAssetFromDisk(String key) {
  for (final root in _projectRootCandidates()) {
    final fromBundle = File(p.join(root.path, 'build', 'unit_test_assets', key));
    if (fromBundle.existsSync()) {
      return ByteData.sublistView(fromBundle.readAsBytesSync());
    }
    final fromSource = File(p.join(root.path, key));
    if (fromSource.existsSync()) {
      return ByteData.sublistView(fromSource.readAsBytesSync());
    }
  }
  if (key == _kAssetManifestKey) {
    return _emptyAssetManifest;
  }
  return null;
}

/// `StandardMessageCodec.encodeMessage(<Object?, Object?>{})` — an asset
/// manifest with no entries. `AssetImage._chooseVariant` treats a missing key
/// as "no variants" and uses the original asset key directly, which our
/// source-tree fallback can serve.
final ByteData _emptyAssetManifest = const StandardMessageCodec()
    .encodeMessage(<Object?, Object?>{})!;

Iterable<Directory> _projectRootCandidates() sync* {
  final seen = <String>{};

  Directory? promote(Directory? dir) {
    if (dir == null) return null;
    final canonical = dir.path;
    if (!seen.add(canonical)) return null;
    return dir;
  }

  for (final envName in const <String>[
    _kFlutterWidgetTestProjectRootEnv,
    'GITHUB_WORKSPACE',
    'CI_PROJECT_DIR',
  ]) {
    final envPath = Platform.environment[envName];
    if (envPath == null || envPath.isEmpty) continue;
    final envDir = Directory(envPath);
    if (_hasPubspec(envDir)) {
      final yielded = promote(envDir);
      if (yielded != null) yield yielded;
    }
  }

  final fromCwd = promote(_walkUpToPubspec(Directory.current));
  if (fromCwd != null) yield fromCwd;

  try {
    final scriptFile = File.fromUri(Platform.script);
    final fromScript = promote(_walkUpToPubspec(scriptFile.parent));
    if (fromScript != null) yield fromScript;
  } catch (_) {
    // Platform.script unavailable in some embedders; ignore.
  }
}

bool _hasPubspec(Directory dir) =>
    File(p.join(dir.path, 'pubspec.yaml')).existsSync();

Directory? _walkUpToPubspec(Directory start) {
  var dir = start;
  for (var i = 0; i < 48; i++) {
    if (_hasPubspec(dir)) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
  return null;
}
