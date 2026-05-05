import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [rootBundle] may not resolve [AssetManifest.bin] in some CI / embedder setups;
/// `flutter test` still materializes the same files under [kUnitTestAssetsDir].
class UnitTestAssetsFallbackBundle extends CachingAssetBundle {
  static const kUnitTestAssetsDir = 'build/unit_test_assets';

  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (e, st) {
      if (kIsWeb) {
        Error.throwWithStackTrace(e, st);
      }
      final file = File('$kUnitTestAssetsDir/$key');
      if (file.existsSync()) {
        return ByteData.sublistView(file.readAsBytesSync());
      }
      Error.throwWithStackTrace(e, st);
    }
  }
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
