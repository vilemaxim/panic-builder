import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/character_policies.dart';
import '../../domain/stance.dart';
import '../character_sheet/character_skills_ui.dart';
import '../character_sheet/widgets/archetype_picker_sheet.dart';
import '../character_sheet/widgets/build_picker_sheet.dart';
import '../character_sheet/widgets/hero_type_picker_sheet.dart';
import '../character_sheet/widgets/rulebook_character_sheet_panel.dart';
import '../character_sheet/widgets/rulebook_stance_panel.dart';
import '../character_sheet/widgets/stance_picker_dialogs.dart';

class CreationWizardScreen extends ConsumerStatefulWidget {
  const CreationWizardScreen({super.key});

  @override
  ConsumerState<CreationWizardScreen> createState() =>
      _CreationWizardScreenState();
}

class _CreationWizardScreenState extends ConsumerState<CreationWizardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creationSessionProvider.notifier).refreshComputedFromRules();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(mergedRulesProvider);
    final c = ref.watch(creationSessionProvider);

    return rulesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Rules error: $e'))),
      data: (rules) {
        final policies = CharacterPolicies(rules);
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Character Sheet Builder'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Character'),
                  Tab(text: 'Stance 1'),
                  Tab(text: 'Stance 2'),
                  Tab(text: 'Stance 3'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Exit'),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _characterTab(c, rules, policies),
                _stanceTab(c, rules, policies, 0),
                _stanceTab(c, rules, policies, 1),
                _stanceTab(c, rules, policies, 2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _characterTab(
    Character c,
    MergedRules rules,
    CharacterPolicies policies,
  ) {
    final session = ref.read(creationSessionProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RulebookCharacterSheetPanel(
          character: c,
          rules: rules,
          identityHandlers: RulebookSheetIdentityHandlers(
            onCharacterName: (v) => session.setIdentity(characterName: v),
            onHeroType: () {
              _openHeroTypeWizard(rules);
            },
            onPickBuild: () {
              _openBuildWizard(rules);
            },
            onPickArchetype: (slot) {
              _openArchetypeWizard(rules, policies, slot);
            },
          ),
          skillHandlers: RulebookSheetSkillHandlers(
            onReplaceStanceSkill: (stanceIndex) =>
                _openReplaceStanceSkill(rules, stanceIndex),
            onEditTwoWordSkill: _openTwoWordSkill,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final err = policies.validateCreationComplete(
              ref.read(creationSessionProvider),
            );
            if (err != null) {
              _snack(err);
              return;
            }
            final toSave = ref
                .read(creationSessionProvider)
                .copyWith(updatedAt: DateTime.now());
            await ref.read(characterStorageProvider).upsert(toSave);
            ref.invalidate(charactersListProvider);
            if (!mounted) return;
            context.go('/character/${toSave.id}');
          },
          child: const Text('Save Character'),
        ),
      ],
    );
  }

  Widget _stanceTab(
    Character c,
    MergedRules rules,
    CharacterPolicies policies,
    int idx,
  ) {
    final s = c.stances.length > idx ? c.stances[idx] : null;
    final style = s == null ? null : rules.styleById(s.styleId);
    final form = s == null ? null : rules.formById(s.formId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RulebookStancePanel(
          style: style,
          form: form,
          rules: rules,
          formDisplayLabel:
              s != null && s.formDisplayName.trim().isNotEmpty
                  ? s.formDisplayName
                  : null,
          onPickStyle: () => _openStanceStylePick(rules, policies, idx),
          onPickForm: () => _openStanceFormPick(rules, policies, idx),
        ),
      ],
    );
  }

  Future<void> _openHeroTypeWizard(MergedRules rules) async {
    await showHeroTypePickerSheet(
      context,
      rules: rules,
      initial: ref.read(creationSessionProvider).heroType,
      onApply: (selected) async {
        ref.read(creationSessionProvider.notifier).setHeroType(selected);
      },
    );
  }

  Future<void> _openBuildWizard(MergedRules rules) async {
    await showBuildPickerSheet(
      context,
      rules: rules,
      initialBuildId: ref.read(creationSessionProvider).buildId,
      onApply: (selected) async {
        ref.read(creationSessionProvider.notifier).setBuild(selected);
      },
    );
  }

  Future<void> _openArchetypeWizard(
    MergedRules rules,
    CharacterPolicies policies,
    int editSlotIndex,
  ) async {
    final c = ref.read(creationSessionProvider);
    await showArchetypePickerSheet(
      context,
      rules: rules,
      policies: policies,
      heroType: c.heroType,
      editSlotIndex: editSlotIndex,
      initialArchetypeIds: c.archetypeIds,
      onValidationError: _snack,
      onApply: (next) async {
        ref.read(creationSessionProvider.notifier).setArchetypes(next);
      },
    );
  }

  List<Stance> _stancesPadded(Character c) {
    return List<Stance>.generate(
      3,
      (i) =>
          i < c.stances.length
              ? c.stances[i]
              : const Stance(styleId: '', formId: '', formDisplayName: ''),
    );
  }

  bool _stancePickPrecheck(Character c, CharacterPolicies policies) {
    if (c.heroType == null) {
      _snack('Pick hero type first.');
      return false;
    }
    final archErr = policies.validateArchetypes(c.heroType, c.archetypeIds);
    if (archErr != null) {
      _snack(archErr);
      return false;
    }
    return true;
  }

  Future<void> _openStanceStylePick(
    MergedRules rules,
    CharacterPolicies policies,
    int idx,
  ) async {
    final c = ref.read(creationSessionProvider);
    if (!_stancePickPrecheck(c, policies)) return;

    final padded = _stancesPadded(c);
    final allowed = policies.allowedStyleIdsForStance(
      hero: c.heroType!,
      archetypeIds: c.archetypeIds,
      stanceIndex: idx,
      partialStances: padded,
    );
    final cur = idx < c.stances.length ? c.stances[idx] : null;

    await showStanceStylePickDialog(
      context,
      rules: rules,
      allowedStyleIds: allowed,
      initialStyleId: cur?.styleId,
      onApply: (styleId) async {
        final draft = _stancesPadded(c);
        draft[idx] = Stance(styleId: styleId, formId: '', formDisplayName: '');
        ref.read(creationSessionProvider.notifier).setStances(draft);
      },
    );
  }

  Future<void> _openStanceFormPick(
    MergedRules rules,
    CharacterPolicies policies,
    int idx,
  ) async {
    final c = ref.read(creationSessionProvider);
    if (!_stancePickPrecheck(c, policies)) return;

    final cur = idx < c.stances.length ? c.stances[idx] : null;
    if (cur == null || cur.styleId.isEmpty) {
      _snack('Pick a style first.');
      return;
    }

    final padded = _stancesPadded(c);
    final usedForms =
        padded.map((s) => s.formId).where((id) => id.isNotEmpty).toSet();

    final forms = rules.forms
        .where((f) => !usedForms.contains(f.id) || f.id == cur.formId)
        .toList();

    final formId = await showStanceFormPickDialog(
      context,
      rules: rules,
      forms: forms,
      initialFormId: cur.formId.isEmpty ? null : cur.formId,
    );
    if (formId == null || !mounted) return;

    final pickedForm = rules.formById(formId);
    if (pickedForm == null) return;

    final choices = formDisplayNameChoices(pickedForm);
    String? pickedLabel;
    if (choices.length <= 1) {
      pickedLabel = choices.isEmpty ? pickedForm.name.trim() : choices.single;
    } else {
      if (!mounted) return;
      pickedLabel = await showFormDisplayNamePickDialog(
        context,
        form: pickedForm,
        choices: choices,
      );
    }

    if (!mounted || pickedLabel == null) return;

    final draft = _stancesPadded(ref.read(creationSessionProvider));
    draft[idx] = Stance(
      styleId: cur.styleId,
      formId: formId,
      formDisplayName: pickedLabel.trim(),
    );
    ref.read(creationSessionProvider.notifier).setStances(draft);
  }

  Future<void> _openReplaceStanceSkill(
    MergedRules rules,
    int stanceIndex,
  ) async {
    if (!mounted) return;
    var c = ref.read(creationSessionProvider);
    if (stanceIndex >= c.stances.length ||
        c.stances[stanceIndex].formId.isEmpty) {
      _snack('Pick a form for this stance on the Stance tab first.');
      return;
    }
    if (shouldWarnBeforeSlot0Edit(c, rules, stanceIndex)) {
      final ok = await showSkillSwapRevertWarning(context);
      if (!mounted || !ok) return;
      c = ref.read(creationSessionProvider);
    }
    final base = ensureSkillsState(c, rules);
    final currentId = base.skillsByStance[stanceIndex][0];
    final pick = await showPickSkillFromRulesDialog(
      context,
      rules,
      currentSkillId: currentId,
    );
    if (pick == null || !mounted) return;
    final next = buildSlot0Replacement(c, rules, stanceIndex, pick);
    ref.read(creationSessionProvider.notifier).setSkills(next);
  }

  Future<void> _openTwoWordSkill() async {
    if (!mounted) return;
    final rules = ref.read(mergedRulesProvider).valueOrNull;
    if (rules == null) return;
    final c = ref.read(creationSessionProvider);
    final base = ensureSkillsState(c, rules);
    final v = await showTwoWordSkillDialog(
      context,
      initial: base.twoWordSkill,
    );
    if (v == null || !mounted) return;
    ref.read(creationSessionProvider.notifier).setSkills(
          base.copyWith(twoWordSkill: v),
        );
  }
}

