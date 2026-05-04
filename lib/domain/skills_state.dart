/// Skills per stance (3 each) plus one global swap and the two-word skill.
class SkillsState {
  const SkillsState({
    required this.skillsByStance,
    this.swappedStanceIndex,
    this.swappedSlotIndex,
    this.replacementSkillId,
    this.twoWordSkill = '',
    this.skillPlayerNotes = const {},
  });

  /// Length 3; each inner list length 3 (skill ids).
  final List<List<String>> skillsByStance;

  /// Which stance (0–2) had one skill replaced, if any.
  final int? swappedStanceIndex;

  /// Which slot within that stance (0–2).
  final int? swappedSlotIndex;

  final String? replacementSkillId;
  final String twoWordSkill;

  /// Optional short notes keyed by skill id (e.g. what “Basically Magic” covers).
  final Map<String, String> skillPlayerNotes;

  SkillsState copyWith({
    List<List<String>>? skillsByStance,
    int? swappedStanceIndex,
    int? swappedSlotIndex,
    String? replacementSkillId,
    String? twoWordSkill,
    Map<String, String>? skillPlayerNotes,
    bool clearSwap = false,
  }) => SkillsState(
    skillsByStance: skillsByStance ?? this.skillsByStance,
    swappedStanceIndex: clearSwap
        ? null
        : (swappedStanceIndex ?? this.swappedStanceIndex),
    swappedSlotIndex: clearSwap
        ? null
        : (swappedSlotIndex ?? this.swappedSlotIndex),
    replacementSkillId: clearSwap
        ? null
        : (replacementSkillId ?? this.replacementSkillId),
    twoWordSkill: twoWordSkill ?? this.twoWordSkill,
    skillPlayerNotes: skillPlayerNotes ?? this.skillPlayerNotes,
  );

  /// Drops entries for skill ids not present on the current [skillsByStance] grid.
  static Map<String, String> pruneSkillPlayerNotesToGrid(
    Map<String, String> notes,
    List<List<String>> grid,
  ) {
    final used = <String>{};
    for (final row in grid) {
      for (final id in row) {
        used.add(id);
      }
    }
    return Map<String, String>.fromEntries(
      notes.entries.where((e) => used.contains(e.key)),
    );
  }

  Map<String, dynamic> toJson() => {
    'skillsByStance': skillsByStance,
    if (swappedStanceIndex != null) 'swappedStanceIndex': swappedStanceIndex,
    if (swappedSlotIndex != null) 'swappedSlotIndex': swappedSlotIndex,
    if (replacementSkillId != null) 'replacementSkillId': replacementSkillId,
    'twoWordSkill': twoWordSkill,
    if (skillPlayerNotes.isNotEmpty) 'skillPlayerNotes': skillPlayerNotes,
  };

  static SkillsState fromJson(Map<String, dynamic> json) {
    final raw = json['skillsByStance'] as List<dynamic>? ?? [];
    final byStance = raw
        .map((e) => (e as List<dynamic>).map((s) => s as String).toList())
        .toList();
    final notesRaw = json['skillPlayerNotes'];
    final notes = <String, String>{};
    if (notesRaw is Map) {
      for (final e in notesRaw.entries) {
        notes[e.key.toString()] = e.value.toString();
      }
    }
    return SkillsState(
      skillsByStance: byStance,
      swappedStanceIndex: json['swappedStanceIndex'] as int?,
      swappedSlotIndex: json['swappedSlotIndex'] as int?,
      replacementSkillId: json['replacementSkillId'] as String?,
      twoWordSkill: json['twoWordSkill'] as String? ?? '',
      skillPlayerNotes: notes,
    );
  }
}
