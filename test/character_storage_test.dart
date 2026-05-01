import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panic_at_the_dojo/data/character_storage.dart';
import 'package:panic_at_the_dojo/domain/character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adding a character via CharacterStorage.upsert completes without error', () async {
    final tmp = Directory.systemTemp.createTempSync(
      'pad_test_storage_${DateTime.now().microsecondsSinceEpoch}',
    );

    final storage = CharacterStorage();
    await storage.init(hivePath: tmp.path);

    final character = Character.blank();
    await expectLater(storage.upsert(character), completes);

    final loaded = storage.getById(character.id);
    expect(loaded, isNotNull);
    expect(loaded!.id, character.id);
  });
}
