import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../app/providers.dart';
import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/character_rule_overlay.dart';
import '../../domain/hero_type_kind.dart';
import '../../domain/stance.dart';
import '../../util/download.dart';
import '../../widgets/app_async_feedback.dart';
import '../print/character_pdf.dart';
import 'character_skills_ui.dart';
import 'widgets/archetype_picker_sheet.dart';
import 'widgets/build_picker_sheet.dart';
import 'widgets/hero_type_picker_sheet.dart';
import 'widgets/form_choice_dialog.dart';
import 'widgets/frantic_form_section.dart';
import 'widgets/rulebook_character_sheet_panel.dart';
import 'widgets/rulebook_stance_chrome.dart';
import 'widgets/rulebook_stance_panel.dart';

class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({super.key, required this.characterId});

  final String characterId;

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
  Future<void> _persist(Character updated) async {
    await ref.read(characterStorageProvider).upsert(updated);
    ref.invalidate(charactersListProvider);
    ref.invalidate(characterByIdProvider(widget.characterId));
  }

  void _exportJson(Character c) {
    final text = const JsonEncoder.withIndent('  ').convert(c.toJson());
    final name = (c.characterName.isEmpty ? 'character' : c.characterName)
        .replaceAll(RegExp(r'[^\w\-]+'), '_');
    downloadTextFile('$name.json', text, mime: 'application/json');
  }

  String _pdfFileName(Character c) {
    final raw = c.characterName.trim();
    final base = raw.isEmpty ? 'character' : raw;
    return '${base.replaceAll(RegExp(r'[^\w\-\s]+'), '_').replaceAll(RegExp(r'\s+'), '_')}.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final asyncChar = ref.watch(characterByIdProvider(widget.characterId));
    final rulesAsync = ref.watch(mergedRulesProvider);

    return asyncChar.when(
      loading: () => const Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: AppAsyncLoading(message: 'Loading character…'),
        ),
      ),
      error: (e, _) => Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: AppAsyncError(
            error: e,
            title: 'Could not load this character',
          ),
        ),
      ),
      data: (c) {
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: Center(
              child: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ),
          );
        }

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
            final pol = policiesFor(rules);
            final franticHero = c.heroType == HeroTypeKind.frantic;
            final stanceRowWidgets = <Widget>[];
            for (var i = 0; i < c.stances.length; i++) {
              final st = c.stances[i];
              final style = rules.styleById(st.styleId);
              final form = rules.formById(st.formId);
              if (franticHero && style != null) {
                final archName = rules
                    .archetypeById(style.archetypeId)
                    ?.name
                    .trim();
                stanceRowWidgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RulebookStancePanel(
                      chrome: RulebookStanceChrome.franticStyle,
                      styleOnly: true,
                      style: style,
                      form: null,
                      rules: rules,
                      heroType: c.heroType,
                      archetypeLabel: archName,
                      ruleViolationHint:
                          CharacterRuleOverlay.stanceRowViolation(pol, c, i),
                    ),
                  ),
                );
              } else if (style != null && form != null) {
                stanceRowWidgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RulebookStancePanel(
                          style: style,
                          form: form,
                          rules: rules,
                          formDisplayLabel: st.formDisplayName.trim().isEmpty
                              ? null
                              : st.formDisplayName,
                          formChoiceId: st.formChoiceId,
                          heroType: c.heroType,
                          ruleViolationHint:
                              CharacterRuleOverlay.stanceRowViolation(
                                pol,
                                c,
                                i,
                              ),
                        ),
                        if (form.choices.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openFormRuleChoiceForStance(rules, c, i),
                              icon: const Icon(Icons.checklist),
                              label: Text('${form.name} rule option…'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              } else {
                stanceRowWidgets.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          'Stance ${i + 1}: ${st.formDisplayName}',
                        ),
                        subtitle: Text(
                          '${style?.name ?? st.styleId} · ${form?.name ?? st.formId}',
                        ),
                      ),
                    ),
                  ),
                );
              }
            }

            final franticFormWidgets = <Widget>[];
            if (franticHero) {
              franticFormWidgets.add(const SizedBox(height: 16));
              franticFormWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Forms',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              );
              franticFormWidgets.add(const SizedBox(height: 8));
              for (var i = 0; i < c.stances.length; i++) {
                final st = c.stances[i];
                final formRule = rules.formById(st.formId);
                final archId = i < c.archetypeIds.length ? c.archetypeIds[i] : '';
                final arch = archId.isNotEmpty
                    ? rules.archetypeById(archId)
                    : null;
                final slotName = arch?.name.trim();
                franticFormWidgets.add(
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i < c.stances.length - 1 ? 16 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            slotName != null && slotName.isNotEmpty
                                ? 'Form ${i + 1} · $slotName'
                                : 'Form ${i + 1}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FranticFormSection(
                          form: formRule,
                          rules: rules,
                          formDisplayLabel: st.formDisplayName.trim().isEmpty
                              ? null
                              : st.formDisplayName,
                          formChoiceId: st.formChoiceId,
                          ruleViolationHint:
                              CharacterRuleOverlay.stanceRowViolation(
                                pol,
                                c,
                                i,
                              ),
                        ),
                        if (!franticHero &&
                            formRule != null &&
                            formRule.choices.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openFormRuleChoiceForStance(rules, c, i),
                              icon: const Icon(Icons.checklist),
                              label: Text('${formRule.name} rule option…'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  c.characterName.isEmpty ? 'Character' : c.characterName,
                ),
                actions: [
                  IconButton(
                    tooltip: 'Preview PDF (print or download from preview)',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () => context.push('/print/${c.id}'),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                children: [
                  RulebookCharacterSheetPanel(
                    character: c,
                    rules: rules,
                    identityHandlers: RulebookSheetIdentityHandlers(
                      onCharacterName: (v) => _persist(
                        c.copyWith(characterName: v, updatedAt: DateTime.now()),
                      ),
                      onHeroType: () {
                        showHeroTypePickerSheet(
                          context,
                          rules: rules,
                          initial: c.heroType,
                          onApply: (selected) async {
                            await _persist(
                              c.copyWith(
                                heroType: selected,
                                clearHeroType: selected == null,
                                archetypeIds: const [],
                                stances: const [],
                                clearSkillsState: true,
                                clearBuildId: true,
                                clearComputed: true,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          },
                        );
                      },
                      onPickBuild: () {
                        showBuildPickerSheet(
                          context,
                          rules: rules,
                          initialBuildId: c.buildId,
                          onApply: (buildId) async {
                            await _persist(
                              c.copyWith(
                                buildId: buildId,
                                clearBuildId: buildId == null,
                                computed: buildId != null
                                    ? computeStats(rules, buildId)
                                    : null,
                                clearComputed: buildId == null,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          },
                        );
                      },
                      onPickArchetype: (slot) {
                        showArchetypePickerSheet(
                          context,
                          rules: rules,
                          policies: policiesFor(rules),
                          heroType: c.heroType,
                          editSlotIndex: slot,
                          initialArchetypeIds: c.archetypeIds,
                          onValidationError: (msg) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(msg)));
                          },
                          onApply: (ids) async {
                            await _persist(
                              c.copyWith(
                                archetypeIds: ids,
                                stances: const [],
                                clearSkillsState: true,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    skillHandlers: RulebookSheetSkillHandlers(
                      onReplaceStanceSkill: (stanceIndex) =>
                          _openReplaceStanceSkill(rules, stanceIndex),
                      onEditTwoWordSkill: _openTwoWordSkill,
                      onSkillPlayerNote: (skillId, value) {
                        final latest = ref
                            .read(characterByIdProvider(widget.characterId))
                            .value;
                        if (latest == null) return;
                        final base = ensureSkillsState(latest, rules);
                        final m = Map<String, String>.from(
                          base.skillPlayerNotes,
                        );
                        final t = value.trim();
                        if (t.isEmpty) {
                          m.remove(skillId);
                        } else {
                          m[skillId] = t;
                        }
                        _persist(
                          latest.copyWith(
                            skillsState: base.copyWith(skillPlayerNotes: m),
                            updatedAt: DateTime.now(),
                          ),
                        );
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
                        Text(
                          franticHero ? 'Styles' : 'Stances',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  ...stanceRowWidgets,
                  ...franticFormWidgets,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Tooltip(
                              message:
                                  'Most edits save as you go. Save records the timestamp of the copy on this device.',
                              child: FilledButton(
                                onPressed: () async {
                                  final updated = c.copyWith(
                                    updatedAt: DateTime.now(),
                                  );
                                  await _persist(updated);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saved.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Save'),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final current = c.copyWith(
                                  updatedAt: DateTime.now(),
                                );
                                try {
                                  final bytes = await buildCharacterPdfBytes(
                                    current,
                                    rules,
                                  );
                                  if (!context.mounted) return;
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename: _pdfFileName(current),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not share PDF. Try Preview PDF in the toolbar. (${e.toString()})',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Share PDF'),
                            ),
                            OutlinedButton(
                              onPressed: () => _exportJson(c),
                              child: const Text('Export JSON'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Most edits save as you go. Save updates the timestamp '
                          'of the copy stored on this device.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.72),
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(creationSessionProvider.notifier).reset();
                            context.go('/create');
                          },
                          child: const Text('Start another character'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Character? _currentCharacter() =>
      ref.read(characterByIdProvider(widget.characterId)).value;

  Future<void> _openFormRuleChoiceForStance(
    MergedRules rules,
    Character char,
    int stanceIndex,
  ) async {
    if (!mounted) return;
    if (stanceIndex >= char.stances.length) return;
    final st = char.stances[stanceIndex];
    final form = rules.formById(st.formId);
    if (form == null || form.choices.isEmpty) return;
    final id = await showFormRuleChoicesDialog(
      context,
      form: form,
      initialChoiceId: st.formChoiceId,
    );
    if (id == null || !mounted) return;
    final latest = _currentCharacter();
    if (latest == null) return;
    final draft = List<Stance>.from(latest.stances);
    draft[stanceIndex] = draft[stanceIndex].copyWith(formChoiceId: id);
    await _persist(latest.copyWith(stances: draft, updatedAt: DateTime.now()));
  }

  Future<void> _openReplaceStanceSkill(
    MergedRules rules,
    int stanceIndex,
  ) async {
    if (!mounted) return;
    var char = _currentCharacter();
    if (char == null) return;
    if (stanceIndex >= char.stances.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure this stance first.')),
      );
      return;
    }
    final stRow = char.stances[stanceIndex];
    if (stRow.formId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            char.heroType == HeroTypeKind.frantic
                ? 'Pick a form in the Forms section first.'
                : 'Pick a form for this stance in the stance section.',
          ),
        ),
      );
      return;
    }
    if (shouldWarnBeforeSlot0Edit(char, rules, stanceIndex)) {
      final ok = await showSkillSwapRevertWarning(context);
      if (!mounted || !ok) return;
      char = _currentCharacter();
      if (char == null) return;
    }
    final base = ensureSkillsState(char, rules);
    final pick = await showPickSkillFromRulesDialog(
      context,
      rules,
      currentSkillId: base.skillsByStance[stanceIndex][0],
    );
    if (pick == null || !mounted) return;
    final char2 = _currentCharacter();
    if (char2 == null) return;
    final next = buildSlot0Replacement(char2, rules, stanceIndex, pick);
    await _persist(
      char2.copyWith(skillsState: next, updatedAt: DateTime.now()),
    );
  }

  Future<void> _openTwoWordSkill() async {
    if (!mounted) return;
    final rules = ref.read(mergedRulesProvider).valueOrNull;
    if (rules == null) return;
    final char = _currentCharacter();
    if (char == null) return;
    final base = ensureSkillsState(char, rules);
    final v = await showTwoWordSkillDialog(context, initial: base.twoWordSkill);
    if (v == null || !mounted) return;
    await _persist(
      char.copyWith(
        skillsState: base.copyWith(twoWordSkill: v),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
