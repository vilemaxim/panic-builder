import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/character.dart';

const _kBoxName = 'pad_characters_v1';

/// Offline multi-character storage (Hive; IndexedDB on web).
class CharacterStorage {
  CharacterStorage();

  Box<String>? _box;

  /// On non-web platforms, [hivePath] overrides the directory passed to [Hive.init]
  /// (defaults to [getTemporaryDirectory]). Tests should pass a temp dir from `dart:io`
  /// so storage works without plugin message channels.
  Future<void> init({String? hivePath}) async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final path = hivePath ?? (await getTemporaryDirectory()).path;
      Hive.init(path);
    }
    _box = await Hive.openBox<String>(_kBoxName);
  }

  Box<String> get _b {
    final box = _box;
    if (box == null) {
      throw StateError('CharacterStorage.init() must be called first.');
    }
    return box;
  }

  List<Character> listAll() {
    final out = <Character>[];
    for (final key in _b.keys) {
      final id = key as String;
      final raw = _b.get(id);
      if (raw == null || raw.isEmpty) continue;
      try {
        out.add(Character.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // skip corrupt entries
      }
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  Character? getById(String id) {
    final raw = _b.get(id);
    if (raw == null) return null;
    return Character.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> upsert(Character c) async {
    final json = jsonEncode(c.toJson());
    await _b.put(c.id, json);
  }

  Future<void> delete(String id) async {
    await _b.delete(id);
  }
}
