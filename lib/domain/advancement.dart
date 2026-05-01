/// Logged XP spend or unlock (post-MVP UI; stored from day one).
enum AdvancementKind { gainSuper, addSkill, swapForm, boostStat, custom }

class Advancement {
  const Advancement({
    required this.kind,
    required this.costXp,
    required this.at,
    this.note,
    this.payload,
  });

  final AdvancementKind kind;
  final int costXp;
  final DateTime at;
  final String? note;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'costXp': costXp,
    'at': at.toIso8601String(),
    if (note != null) 'note': note,
    if (payload != null) 'payload': payload,
  };

  static Advancement fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String? ?? 'custom';
    AdvancementKind kind = AdvancementKind.custom;
    for (final v in AdvancementKind.values) {
      if (v.name == kindStr) {
        kind = v;
        break;
      }
    }
    return Advancement(
      kind: kind,
      costXp: json['costXp'] as int? ?? 0,
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
