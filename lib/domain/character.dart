import 'package:uuid/uuid.dart';

import 'advancement.dart';
import 'computed_stats.dart';
import 'hero_type_kind.dart';
import 'skills_state.dart';
import 'stance.dart';
import 'super_unlock.dart';

const int kCharacterSchemaVersion = 1;

/// Full saved character for creation, advancement, and export.
class Character {
  Character({
    required this.id,
    required this.schemaVersion,
    required this.updatedAt,
    this.playerName = '',
    this.characterName = '',
    this.gender = '',
    this.description = '',
    this.heroType,
    this.buildId,
    this.archetypeIds = const [],
    this.stances = const [],
    this.skillsState,
    this.computed,
    this.xpEarned = 0,
    this.xpSpent = 0,
    this.advancements = const [],
    this.superUnlock,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? updatedAt;

  factory Character.blank() {
    final now = DateTime.now();
    return Character(
      id: const Uuid().v4(),
      schemaVersion: kCharacterSchemaVersion,
      updatedAt: now,
      createdAt: now,
    );
  }

  final String id;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String playerName;
  final String characterName;
  final String gender;
  final String description;

  final HeroTypeKind? heroType;
  final String? buildId;

  /// Ordered archetypes: length 1 (Focused), 2 (Fused), 3 (Frantic).
  final List<String> archetypeIds;

  final List<Stance> stances;
  final SkillsState? skillsState;
  final ComputedStats? computed;

  final int xpEarned;
  final int xpSpent;
  final List<Advancement> advancements;
  final SuperUnlock? superUnlock;

  int get availableXp => xpEarned - xpSpent;

  Character copyWith({
    String? id,
    int? schemaVersion,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? playerName,
    String? characterName,
    String? gender,
    String? description,
    HeroTypeKind? heroType,
    bool clearHeroType = false,
    String? buildId,
    bool clearBuildId = false,
    List<String>? archetypeIds,
    List<Stance>? stances,
    SkillsState? skillsState,
    bool clearSkillsState = false,
    ComputedStats? computed,
    bool clearComputed = false,
    int? xpEarned,
    int? xpSpent,
    List<Advancement>? advancements,
    SuperUnlock? superUnlock,
    bool clearSuper = false,
  }) => Character(
    id: id ?? this.id,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
    playerName: playerName ?? this.playerName,
    characterName: characterName ?? this.characterName,
    gender: gender ?? this.gender,
    description: description ?? this.description,
    heroType: clearHeroType ? null : (heroType ?? this.heroType),
    buildId: clearBuildId ? null : (buildId ?? this.buildId),
    archetypeIds: archetypeIds ?? List<String>.from(this.archetypeIds),
    stances: stances ?? List<Stance>.from(this.stances),
    skillsState: clearSkillsState ? null : (skillsState ?? this.skillsState),
    computed: clearComputed ? null : (computed ?? this.computed),
    xpEarned: xpEarned ?? this.xpEarned,
    xpSpent: xpSpent ?? this.xpSpent,
    advancements: advancements ?? List<Advancement>.from(this.advancements),
    superUnlock: clearSuper ? null : (superUnlock ?? this.superUnlock),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'playerName': playerName,
    'characterName': characterName,
    'gender': gender,
    'description': description,
    if (heroType != null) 'heroType': heroType!.name,
    if (buildId != null) 'buildId': buildId,
    'archetypeIds': archetypeIds,
    'stances': stances.map((e) => e.toJson()).toList(),
    if (skillsState != null) 'skills': skillsState!.toJson(),
    if (computed != null) 'computed': computed!.toJson(),
    'xpEarned': xpEarned,
    'xpSpent': xpSpent,
    'advancements': advancements.map((e) => e.toJson()).toList(),
    if (superUnlock != null) 'super': superUnlock!.toJson(),
  };

  static Character fromJson(Map<String, dynamic> json) {
    final stancesRaw = json['stances'] as List<dynamic>? ?? [];
    final advRaw = json['advancements'] as List<dynamic>? ?? [];
    return Character(
      id: json['id'] as String,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      playerName: json['playerName'] as String? ?? '',
      characterName: json['characterName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      description: json['description'] as String? ?? '',
      heroType: HeroTypeKindX.tryParse(json['heroType'] as String?),
      buildId: json['buildId'] as String?,
      archetypeIds: (json['archetypeIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      stances: stancesRaw
          .map((e) => Stance.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      skillsState: json['skills'] != null
          ? SkillsState.fromJson(
              (json['skills'] as Map).cast<String, dynamic>(),
            )
          : null,
      computed: ComputedStats.fromJson(
        json['computed'] != null
            ? (json['computed'] as Map).cast<String, dynamic>()
            : null,
      ),
      xpEarned: json['xpEarned'] as int? ?? 0,
      xpSpent: json['xpSpent'] as int? ?? 0,
      advancements: advRaw
          .map((e) => Advancement.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      superUnlock: SuperUnlock.fromJson(
        json['super'] != null
            ? (json['super'] as Map).cast<String, dynamic>()
            : null,
      ),
    );
  }
}
