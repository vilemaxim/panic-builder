import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/character_storage.dart';
import '../data/rules_models.dart';
import '../data/rules_repository.dart';
import '../domain/character.dart';
import '../domain/character_policies.dart';
import '../domain/computed_stats.dart';
import '../domain/hero_type_kind.dart';
import '../domain/skills_state.dart';
import '../domain/stance.dart';

final rulesRepositoryProvider = Provider<RulesRepository>((ref) {
  return RulesRepository();
});

final mergedRulesProvider = FutureProvider<MergedRules>((ref) async {
  return ref.watch(rulesRepositoryProvider).load();
});

final characterStorageProvider = Provider<CharacterStorage>((ref) {
  throw UnimplementedError('Override in ProviderScope overrides');
});

final charactersListProvider = FutureProvider<List<Character>>((ref) async {
  final store = ref.watch(characterStorageProvider);
  return store.listAll();
});

final characterByIdProvider = FutureProvider.family<Character?, String>((
  ref,
  id,
) async {
  return ref.watch(characterStorageProvider).getById(id);
});

CharacterPolicies policiesFor(MergedRules rules) => CharacterPolicies(rules);

ComputedStats computeStats(MergedRules rules, String? buildId) {
  final b = rules.buildById(buildId);
  if (b == null) {
    return const ComputedStats(maxHp: 0, hpBars: 0, totalBars: 0);
  }
  return ComputedStats(
    maxHp: b.maxHp,
    hpBars: b.hpBars,
    totalBars: b.totalBars,
  );
}

/// Live draft while creating a new character.
final creationSessionProvider =
    NotifierProvider<CreationSessionNotifier, Character>(
      CreationSessionNotifier.new,
    );

class CreationSessionNotifier extends Notifier<Character> {
  @override
  Character build() => Character.blank();

  void reset() => state = Character.blank();

  void setIdentity({
    String? playerName,
    String? characterName,
    String? gender,
    String? description,
  }) {
    state = state.copyWith(
      playerName: playerName,
      characterName: characterName,
      gender: gender,
      description: description,
      updatedAt: DateTime.now(),
    );
  }

  void setHeroType(HeroTypeKind? hero) {
    state = state.copyWith(
      heroType: hero,
      clearHeroType: hero == null,
      archetypeIds: const [],
      stances: const [],
      clearSkillsState: true,
      clearBuildId: true,
      clearComputed: true,
      updatedAt: DateTime.now(),
    );
  }

  void setBuild(String? buildId) {
    state = state.copyWith(
      buildId: buildId,
      clearBuildId: buildId == null,
      updatedAt: DateTime.now(),
    );
    final rules = ref.read(mergedRulesProvider).valueOrNull;
    if (rules != null && buildId != null) {
      state = state.copyWith(computed: computeStats(rules, buildId));
    } else if (buildId == null) {
      state = state.copyWith(clearComputed: true);
    }
  }

  void setArchetypes(List<String> ids) {
    state = state.copyWith(
      archetypeIds: List<String>.from(ids),
      stances: const [],
      clearSkillsState: true,
      updatedAt: DateTime.now(),
    );
  }

  void setStances(List<Stance> stances) {
    state = state.copyWith(
      stances: List<Stance>.from(stances),
      clearSkillsState: true,
      updatedAt: DateTime.now(),
    );
    _recomputeComputed();
  }

  void setSkills(SkillsState skills) {
    state = state.copyWith(skillsState: skills, updatedAt: DateTime.now());
  }

  void _recomputeComputed() {
    final rules = ref.read(mergedRulesProvider).valueOrNull;
    if (rules != null && state.buildId != null) {
      state = state.copyWith(computed: computeStats(rules, state.buildId));
    }
  }

  /// Call after async rules/build are known to refresh HP block.
  void refreshComputedFromRules() {
    final rules = ref.read(mergedRulesProvider).valueOrNull;
    if (rules == null) return;
    state = state.copyWith(
      computed: computeStats(rules, state.buildId),
      updatedAt: DateTime.now(),
    );
  }
}
