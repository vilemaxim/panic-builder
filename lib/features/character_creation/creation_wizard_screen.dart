import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../widgets/app_async_feedback.dart';
import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/character_policies.dart';
import '../../domain/character_rule_overlay.dart';
import '../../domain/hero_type_kind.dart';
import '../../domain/stance.dart';
import '../character_sheet/character_skills_ui.dart';
import '../character_sheet/widgets/archetype_picker_sheet.dart';
import '../character_sheet/widgets/build_picker_sheet.dart';
import '../character_sheet/widgets/hero_type_picker_sheet.dart';
import '../character_sheet/widgets/rulebook_character_sheet_panel.dart';
import '../character_sheet/widgets/frantic_form_section.dart';
import '../character_sheet/widgets/rulebook_stance_chrome.dart';
import '../character_sheet/widgets/form_choice_dialog.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _confirmExitToHome() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave builder?'),
        content: const Text(
          'Your work-in-progress stays on this device when you leave. '
          'Opening Create new character from Home clears that draft and starts a blank sheet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.go('/');
  }

  /// Returns true if the user chooses to save despite [validationMessage].
  Future<bool> _confirmSaveDespiteIncompleteRules(
    String validationMessage,
  ) async {
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100)),
        title: const Text('Does not match printed rules'),
        content: SingleChildScrollView(
          child: Text(
            'The builder reports:\n\n'
            '$validationMessage\n\n'
            'You can go back and fix this, or save anyway to keep a draft or '
            'homebrew sheet on this device.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  String? _stanceTabPrerequisiteMessage(
    Character c,
    CharacterPolicies policies,
  ) {
    if (c.heroType == null) {
      return 'Choose a hero type on the Character tab before configuring stances.';
    }
    return policies.validateArchetypes(c.heroType, c.archetypeIds);
  }

  String? _formsTabPrerequisiteMessage(
    Character c,
    CharacterPolicies policies,
  ) {
    final base = _stanceTabPrerequisiteMessage(c, policies);
    if (base != null) return base;
    final padded = _stancesPadded(c);
    for (var i = 0; i < 3; i++) {
      if (padded[i].styleId.isEmpty) {
        return 'Pick all three styles on the Style tab before choosing forms.';
      }
    }
    return null;
  }

  Widget _infoBanner({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFFF4E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF3B2B1E), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(mergedRulesProvider);
    final c = ref.watch(creationSessionProvider);

    return rulesAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: AppAsyncLoading(message: 'Loading rules…'),
        ),
      ),
      error: (e, _) => Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: AppAsyncError(error: e, title: 'Could not load rules'),
        ),
      ),
      data: (rules) {
        final policies = CharacterPolicies(rules);
        final completionHint = policies.validateCreationComplete(c);
        final frantic = c.heroType == HeroTypeKind.frantic;
        final tabCount = frantic ? 3 : 4;
        return DefaultTabController(
          key: ValueKey<int>(tabCount),
          length: tabCount,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Character Sheet Builder'),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: frantic
                    ? const [
                        Tab(text: 'Character'),
                        Tab(text: 'Style'),
                        Tab(text: 'Forms'),
                      ]
                    : const [
                        Tab(text: 'Character'),
                        Tab(text: 'Stance 1'),
                        Tab(text: 'Stance 2'),
                        Tab(text: 'Stance 3'),
                      ],
              ),
              actions: [
                TextButton(
                  onPressed: _confirmExitToHome,
                  child: const Text('Exit'),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (completionHint != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _infoBanner(
                      icon: Icons.flag_outlined,
                      message: completionHint,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: frantic
                        ? [
                            _characterTab(c, rules, policies),
                            _franticStylesTab(c, rules, policies),
                            _franticFormsTab(c, rules, policies),
                          ]
                        : [
                            _characterTab(c, rules, policies),
                            _stanceTab(c, rules, policies, 0),
                            _stanceTab(c, rules, policies, 1),
                            _stanceTab(c, rules, policies, 2),
                          ],
                  ),
                ),
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
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
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
            onSkillPlayerNote: (skillId, value) {
              final cur = ref.read(creationSessionProvider);
              final base = ensureSkillsState(cur, rules);
              final m = Map<String, String>.from(base.skillPlayerNotes);
              final t = value.trim();
              if (t.isEmpty) {
                m.remove(skillId);
              } else {
                m[skillId] = t;
              }
              ref
                  .read(creationSessionProvider.notifier)
                  .setSkills(base.copyWith(skillPlayerNotes: m));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final session = ref.read(creationSessionProvider);
                  final err = policies.validateCreationComplete(session);
                  if (err != null) {
                    final saveAnyway = await _confirmSaveDespiteIncompleteRules(
                      err,
                    );
                    if (!saveAnyway || !mounted) return;
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
          ),
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
    final stanceHint = _stanceTabPrerequisiteMessage(c, policies);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (stanceHint != null)
          _infoBanner(icon: Icons.info_outline, message: stanceHint),
        RulebookStancePanel(
          style: style,
          form: form,
          rules: rules,
          formDisplayLabel: s != null && s.formDisplayName.trim().isNotEmpty
              ? s.formDisplayName
              : null,
          formChoiceId: s?.formChoiceId,
          heroType: c.heroType,
          onPickStyle: () => _openStanceStylePick(rules, policies, idx),
          onPickForm: () => _openStanceFormPick(rules, policies, idx),
          ruleViolationHint: CharacterRuleOverlay.stanceRowViolation(
            policies,
            c,
            idx,
          ),
        ),
      ],
    );
  }

  Widget _franticStylesTab(
    Character c,
    MergedRules rules,
    CharacterPolicies policies,
  ) {
    final stanceHint = _stanceTabPrerequisiteMessage(c, policies);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (stanceHint != null)
          _infoBanner(icon: Icons.info_outline, message: stanceHint),
        for (var idx = 0; idx < 3; idx++) ...[
          if (idx > 0) const SizedBox(height: 20),
          _franticStyleSlotHeading(c, rules, idx),
          const SizedBox(height: 8),
          _franticStyleSlotPanel(c, rules, policies, idx),
        ],
      ],
    );
  }

  Widget _franticStyleSlotHeading(Character c, MergedRules rules, int idx) {
    final archId = idx < c.archetypeIds.length ? c.archetypeIds[idx] : '';
    final arch = archId.isNotEmpty ? rules.archetypeById(archId) : null;
    final subtitle = arch?.name.trim();
    final t = Theme.of(context);
    return Text(
      subtitle != null && subtitle.isNotEmpty
          ? 'Style ${idx + 1} · $subtitle'
          : 'Style ${idx + 1}',
      style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _franticStyleSlotPanel(
    Character c,
    MergedRules rules,
    CharacterPolicies policies,
    int idx,
  ) {
    final s = c.stances.length > idx ? c.stances[idx] : null;
    final style = s == null ? null : rules.styleById(s.styleId);
    return RulebookStancePanel(
      chrome: RulebookStanceChrome.franticStyle,
      styleOnly: true,
      style: style,
      form: null,
      rules: rules,
      heroType: c.heroType,
      onPickStyle: () => _openStanceStylePick(rules, policies, idx),
      onPickForm: null,
      ruleViolationHint: CharacterRuleOverlay.stanceRowViolation(
        policies,
        c,
        idx,
      ),
    );
  }

  Widget _franticFormsTab(
    Character c,
    MergedRules rules,
    CharacterPolicies policies,
  ) {
    final hint = _formsTabPrerequisiteMessage(c, policies);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hint != null) _infoBanner(icon: Icons.info_outline, message: hint),
        for (var idx = 0; idx < 3; idx++) ...[
          if (idx > 0) const SizedBox(height: 20),
          _franticFormSlotHeading(c, rules, idx),
          const SizedBox(height: 8),
          _franticFormSlotPanel(c, rules, policies, idx),
        ],
      ],
    );
  }

  Widget _franticFormSlotHeading(Character c, MergedRules rules, int idx) {
    final archId = idx < c.archetypeIds.length ? c.archetypeIds[idx] : '';
    final arch = archId.isNotEmpty ? rules.archetypeById(archId) : null;
    final subtitle = arch?.name.trim();
    final t = Theme.of(context);
    return Text(
      subtitle != null && subtitle.isNotEmpty
          ? 'Form ${idx + 1} · $subtitle'
          : 'Form ${idx + 1}',
      style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _franticFormSlotPanel(
    Character c,
    MergedRules rules,
    CharacterPolicies policies,
    int idx,
  ) {
    final s = c.stances.length > idx ? c.stances[idx] : null;
    final form = s == null ? null : rules.formById(s.formId);
    return FranticFormSection(
      form: form,
      rules: rules,
      formDisplayLabel: s != null && s.formDisplayName.trim().isNotEmpty
          ? s.formDisplayName
          : null,
      formChoiceId: s?.formChoiceId,
      onPickForm: () => _openStanceFormPick(rules, policies, idx),
      ruleViolationHint: CharacterRuleOverlay.stanceRowViolation(
        policies,
        c,
        idx,
      ),
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
      (i) => i < c.stances.length
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
    final cur = idx < c.stances.length ? c.stances[idx] : null;

    await showStanceStylePickDialog(
      context,
      rules: rules,
      policies: policies,
      hero: c.heroType!,
      archetypeIds: c.archetypeIds,
      stanceIndex: idx,
      partialStances: padded,
      initialStyleId: cur?.styleId,
      onApply: (styleId) async {
        final draft = _stancesPadded(c);
        draft[idx] = Stance(
          styleId: styleId,
          formId: '',
          formDisplayName: '',
          formChoiceId: null,
        );
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
      _snack(
        c.heroType == HeroTypeKind.frantic
            ? 'Pick a style on the Style tab first.'
            : 'Pick a style first.',
      );
      return;
    }

    final padded = _stancesPadded(c);

    final formId = await showStanceFormPickDialog(
      context,
      rules: rules,
      policies: policies,
      stancesPadded: padded,
      stanceIndex: idx,
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

    String? choiceId;
    if (pickedForm.choices.isNotEmpty) {
      choiceId = await showFormRuleChoicesDialog(
        context,
        form: pickedForm,
        initialChoiceId: cur.formId == formId ? cur.formChoiceId : null,
      );
      if (choiceId == null || !mounted) return;
    }

    final draft = _stancesPadded(ref.read(creationSessionProvider));
    draft[idx] = Stance(
      styleId: cur.styleId,
      formId: formId,
      formDisplayName: pickedLabel.trim(),
      formChoiceId: choiceId,
    );
    ref.read(creationSessionProvider.notifier).setStances(draft);
  }

  Future<void> _openReplaceStanceSkill(
    MergedRules rules,
    int stanceIndex,
  ) async {
    if (!mounted) return;
    var c = ref.read(creationSessionProvider);
    if (stanceIndex >= c.stances.length) {
      _snack('Configure this stance first.');
      return;
    }
    final st = c.stances[stanceIndex];
    if (st.formId.isEmpty) {
      _snack(
        c.heroType == HeroTypeKind.frantic
            ? 'Pick a form on the Forms tab first.'
            : 'Pick a form for this stance on the Stance tab first.',
      );
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
    final v = await showTwoWordSkillDialog(context, initial: base.twoWordSkill);
    if (v == null || !mounted) return;
    ref
        .read(creationSessionProvider.notifier)
        .setSkills(base.copyWith(twoWordSkill: v));
  }
}
