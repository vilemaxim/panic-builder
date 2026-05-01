/// Deep-merge rules maps: patch overrides base. Lists of `{id: ...}` merge by `id`.
Map<String, dynamic> mergeRulesJson(
  Map<String, dynamic> base,
  Map<String, dynamic> patch,
) {
  final out = Map<String, dynamic>.from(base);
  for (final entry in patch.entries) {
    final key = entry.key;
    final pv = entry.value;
    final bv = out[key];
    if (bv == null) {
      out[key] = pv;
      continue;
    }
    if (pv is Map<String, dynamic> && bv is Map<String, dynamic>) {
      out[key] = mergeRulesJson(bv, pv);
    } else if (pv is List && bv is List && _looksLikeIdObjects(bv)) {
      out[key] = _mergeIdObjectLists(bv, pv);
    } else {
      out[key] = pv;
    }
  }
  return out;
}

bool _looksLikeIdObjects(List list) {
  if (list.isEmpty) return false;
  final first = list.first;
  if (first is! Map) return false;
  return first.containsKey('id');
}

List<dynamic> _mergeIdObjectLists(
  List<dynamic> baseList,
  List<dynamic> patchList,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final e in baseList) {
    if (e is Map && e['id'] != null) {
      byId[e['id']! as String] = e.cast<String, dynamic>();
    }
  }
  for (final e in patchList) {
    if (e is Map && e['id'] != null) {
      final id = e['id']! as String;
      final patchMap = e.cast<String, dynamic>();
      if (byId.containsKey(id)) {
        byId[id] = mergeRulesJson(byId[id]!, patchMap);
      } else {
        byId[id] = patchMap;
      }
    }
  }
  return byId.values.toList();
}
