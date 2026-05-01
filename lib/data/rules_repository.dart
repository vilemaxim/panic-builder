import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rules_models.dart';

/// Loads bundled [MergedRules] from assets/data/rules.json.
///
/// Edit that file directly (or run `tool/sync_rules_from_sources.dart` /
/// `tool/generate_style_skills.dart` to merge stance skill text from the extract).
class RulesRepository {
  MergedRules? _cached;

  Future<MergedRules> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/data/rules.json');
    final merged = jsonDecode(raw) as Map<String, dynamic>;
    _cached = MergedRules.fromJson(merged);
    return _cached!;
  }

  /// For tests: inject merged map without assets.
  @visibleForTesting
  void setMergedForTest(MergedRules rules) {
    _cached = rules;
  }

  @visibleForTesting
  Future<void> clearCache() async {
    _cached = null;
  }
}
