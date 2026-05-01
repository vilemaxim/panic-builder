import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/features/character_sheet/widgets/form_dice_catalog.dart';

/// Why earlier tests missed Chrome 404s:
/// - [form_dice_assets_test] only checks **source tree** files under `assets/...`.
/// - [bundled_data_assets_test] checks **pubspec strings** + loose JSON on disk.
/// Neither ran `flutter build web`, so **missing outputs under `build/web/assets/`**
/// (wrong AssetManifest / omitted raster assets) never failed CI.

/// Canonical on-disk layout after `flutter build web`:
/// `build/web/assets/` + asset manifest key `assets/icons/dice/d10.png`
/// → `build/web/assets/assets/icons/dice/d10.png`
File _bundledAssetFile(String projectRoot, String assetManifestKey) {
  return File('$projectRoot/build/web/assets/$assetManifestKey');
}

void main() {
  const kPdfFontAssetPaths = <String>[
    'assets/fonts/DejaVuSerif.ttf',
    'assets/fonts/DejaVuSerif-Bold.ttf',
    'assets/fonts/DejaVuSerif-Italic.ttf',
    'assets/fonts/DejaVuSerif-BoldItalic.ttf',
  ];

  final skipBundleIntegration = !(
      Platform.environment['CI'] == 'true' ||
      Platform.environment['RUN_WEB_BUILD_BUNDLE_TEST'] == 'true');

  test(
    'flutter build web places stance dice PNGs, rules.json, and PDF fonts in build/web/assets/',
    () async {
      final root = Directory.current.path;
      const flutter = 'flutter';

      final clean = await Process.run(flutter, ['clean'], workingDirectory: root);
      expect(clean.exitCode, 0, reason: '${clean.stderr}\n${clean.stdout}');

      final build = await Process.run(
        flutter,
        ['build', 'web', '--no-tree-shake-icons'],
        workingDirectory: root,
        environment: Platform.environment,
      );
      expect(build.exitCode, 0, reason: '${build.stderr}\n${build.stdout}');

      for (final key in kBundledDiceIconAssetPaths) {
        final f = _bundledAssetFile(root, key);
        expect(
          f.existsSync(),
          isTrue,
          reason:
              'Chrome requested asset key "$key" but it was not emitted next to '
              'AssetManifest under build/web/assets/. Typical symptom: '
              '`assets/assets/icons/dice/d10.png` HTTP 404.',
        );
        expect(f.lengthSync(), greaterThan(0));
      }

      final rulesBundle = _bundledAssetFile(root, 'assets/data/rules.json');
      expect(
        rulesBundle.existsSync(),
        isTrue,
        reason:
            'RulesRepository loads assets/data/rules.json — '
            'missing from web bundle yields fetch 404.',
      );
      expect(rulesBundle.lengthSync(), greaterThan(0));

      for (final key in kPdfFontAssetPaths) {
        final f = _bundledAssetFile(root, key);
        expect(
          f.existsSync(),
          isTrue,
          reason:
              'PDF export loads "$key" via rootBundle; missing web output causes '
              '`assets/assets/fonts/DejaVuSerif.ttf` HTTP 404 at save-time.',
        );
        expect(f.lengthSync(), greaterThan(0));
      }
    },
    skip: skipBundleIntegration
        ? 'Runs on CI (CI=true) or when RUN_WEB_BUILD_BUNDLE_TEST=true (~2 min: flutter clean + build web).'
        : false,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
