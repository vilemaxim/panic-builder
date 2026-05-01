/// Hero type from the core rules (p.121+). Drives archetype and stance style rules.
enum HeroTypeKind { focused, fused, frantic }

extension HeroTypeKindX on HeroTypeKind {
  String get id => name;

  static HeroTypeKind? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in HeroTypeKind.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
