import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../app/providers.dart';
import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../util/download.dart';
import '../print/character_pdf.dart';
import 'character_skills_ui.dart';
import 'widgets/archetype_picker_sheet.dart';
import 'widgets/build_picker_sheet.dart';
import 'widgets/hero_type_picker_sheet.dart';
import 'widgets/rulebook_character_sheet_panel.dart';
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
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
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Rules: $e'))),
          data: (rules) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  c.characterName.isEmpty ? 'Character' : c.characterName,
                ),
                actions: [
                  IconButton(
                    tooltip: 'Print / PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () => context.push('/print/${c.id}'),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RulebookCharacterSheetPanel(
                    character: c,
                    rules: rules,
                    identityHandlers: RulebookSheetIdentityHandlers(
                      onCharacterName: (v) => _persist(
                        c.copyWith(
                          characterName: v,
                          updatedAt: DateTime.now(),
                        ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stances',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(c.stances.length, (i) {
                    final st = c.stances[i];
                    final style = rules.styleById(st.styleId);
                    final form = rules.formById(st.formId);
                    if (style != null && form != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RulebookStancePanel(
                          style: style,
                          form: form,
                          rules: rules,
                          formDisplayLabel:
                              st.formDisplayName.trim().isEmpty
                                  ? null
                                  : st.formDisplayName,
                        ),
                      );
                    }
                    return Card(
                      child: ListTile(
                        title: Text('Stance ${i + 1}: ${st.formDisplayName}'),
                        subtitle: Text(
                          '${style?.name ?? st.styleId} · ${form?.name ?? st.formId}',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          final updated =
                              c.copyWith(updatedAt: DateTime.now());
                          await _persist(updated);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved.')),
                          );
                        },
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final current = c.copyWith(updatedAt: DateTime.now());
                          try {
                            final bytes =
                                await buildCharacterPdfBytes(current, rules);
                            if (!context.mounted) return;
                            await Printing.sharePdf(
                              bytes: bytes,
                              filename: _pdfFileName(current),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('PDF export failed: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save PDF'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _exportJson(c),
                        child: const Text('Export JSON'),
                      ),
                    ],
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
            );
          },
        );
      },
    );
  }

  Character? _currentCharacter() =>
      ref.read(characterByIdProvider(widget.characterId)).value;

  Future<void> _openReplaceStanceSkill(
    MergedRules rules,
    int stanceIndex,
  ) async {
    if (!mounted) return;
    var char = _currentCharacter();
    if (char == null) return;
    if (stanceIndex >= char.stances.length ||
        char.stances[stanceIndex].formId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a form for this stance in the stance section.'),
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
    final v = await showTwoWordSkillDialog(
      context,
      initial: base.twoWordSkill,
    );
    if (v == null || !mounted) return;
    await _persist(
      char.copyWith(
        skillsState: base.copyWith(twoWordSkill: v),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
