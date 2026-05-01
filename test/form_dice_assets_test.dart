import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/features/character_sheet/widgets/form_dice_catalog.dart';

void main() {
  test(
    'every bundled stance dice icon exists as a non-empty file',
    () {
      final root = Directory.current.path;
      final missing = <String>[];
      for (final relative in kBundledDiceIconAssetPaths) {
        final f = File('$root/$relative');
        if (!f.existsSync()) {
          missing.add('missing: $relative');
          continue;
        }
        if (f.lengthSync() == 0) {
          missing.add('empty: $relative');
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'Keep optional dice PNGs on disk for branding/web tooling; stance dice '
            'render as painted silhouettes via formDieChip.\n${missing.join('\n')}',
      );
    },
  );
}
