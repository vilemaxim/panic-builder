import 'package:flutter/material.dart';

import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/character_policies.dart';
import '../../domain/skills_state.dart';
import 'widgets/picker_dialog_chrome.dart';
import 'widgets/picker_presentation.dart';

/// Unique skills referenced by any form’s `skillIds` (the in-play form skill pool).
List<RuleSkill> skillsGrantedByForms(MergedRules rules) {
  final seen = <String>{};
  final out = <RuleSkill>[];
  for (final f in rules.forms) {
    for (final raw in f.skillIds) {
      final id = raw.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      final sk = rules.skillById(id);
      if (sk != null) out.add(sk);
    }
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

/// First differing cell between [state] and [draft], or null if identical.
({int si, int sj})? firstSkillDiff(SkillsState state, SkillsStateDraft draft) {
  for (var i = 0; i < 3; i++) {
    final a = state.skillsByStance[i];
    final b = draft.skillsByStance[i];
    for (var j = 0; j < 3; j++) {
      if (a[j] != b[j]) return (si: i, sj: j);
    }
  }
  return null;
}

/// Returns [SkillsState] from [c] or defaults from stances (no swap metadata).
SkillsState ensureSkillsState(Character c, MergedRules rules) {
  if (c.skillsState != null) return c.skillsState!;
  final d = CharacterPolicies(rules).defaultSkillsFromStances(c.stances);
  return SkillsState(skillsByStance: d.skillsByStance);
}

SkillsState buildSlot0Replacement(
  Character c,
  MergedRules rules,
  int stanceIndex,
  String newSkillId,
) {
  final draft = CharacterPolicies(rules).defaultSkillsFromStances(c.stances);
  final rows = <List<String>>[];
  for (var i = 0; i < 3; i++) {
    rows.add(List<String>.from(draft.skillsByStance[i]));
  }
  rows[stanceIndex][0] = newSkillId;
  final priorNotes = c.skillsState?.skillPlayerNotes ?? const {};
  final pruned = SkillsState.pruneSkillPlayerNotesToGrid(priorNotes, rows);
  return SkillsState(
    skillsByStance: rows,
    swappedStanceIndex: stanceIndex,
    swappedSlotIndex: 0,
    replacementSkillId: newSkillId,
    twoWordSkill: c.skillsState?.twoWordSkill ?? '',
    skillPlayerNotes: pruned,
  );
}

/// True if the user already changed a different slot than `(stanceIndex, 0)`.
bool shouldWarnBeforeSlot0Edit(
  Character c,
  MergedRules rules,
  int stanceIndex,
) {
  final draft = CharacterPolicies(rules).defaultSkillsFromStances(c.stances);
  final state = c.skillsState;
  if (state == null) return false;
  final diff = firstSkillDiff(state, draft);
  if (diff == null) return false;
  return diff.si != stanceIndex || diff.sj != 0;
}

Future<bool> showSkillSwapRevertWarning(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('Only one skill swap'),
      content: const Text(
        'You can only replace one skill from your form defaults with another '
        'from the full skill list. If you continue, your previous custom skill '
        'will revert to the form default.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> showPickSkillFromRulesDialog(
  BuildContext context,
  MergedRules rules, {
  String? currentSkillId,
}) async {
  final all = skillsGrantedByForms(rules);
  final ctrl = TextEditingController();
  try {
    Widget skillPickerColumn(
      BuildContext popRouteContext,
      BuildContext innerContext,
      StateSetter setState,
    ) {
      final q = ctrl.text.trim().toLowerCase();
      final filtered = q.isEmpty
          ? all
          : all.where((s) {
              final name = s.name.toLowerCase();
              final desc = s.description.toLowerCase();
              final id = s.id.toLowerCase();
              return name.contains(q) ||
                  desc.contains(q) ||
                  id.contains(q);
            }).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Search by name or description…',
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      all.isEmpty
                          ? 'No skills listed on forms in the rules data.'
                          : 'No matches.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      final selected = s.id == currentSkillId;
                      final desc = s.description.trim();
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        selected: selected,
                        title: Text(
                          s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            desc.isEmpty ? '—' : desc,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.pop(popRouteContext, s.id),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    if (!usePickerBottomSheet(context)) {
      return await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              final mq = MediaQuery.sizeOf(ctx);
              final dialogW = (mq.width - 48).clamp(280.0, 560.0);
              final dialogH = (mq.height * 0.62).clamp(280.0, 520.0);
              return withPickerDialogChrome(
                ctx,
                AlertDialog(
                  title: const Text('Choose skill'),
                  content: SizedBox(
                    width: dialogW,
                    height: dialogH,
                    child: skillPickerColumn(dialogContext, ctx, setState),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (routeContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final mq = MediaQuery.of(ctx);
            final sheetH = mq.size.height * 0.88;
            final titleStyle =
                Theme.of(ctx).dialogTheme.titleTextStyle ??
                Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    );
            return withPickerDialogChrome(
              context,
              Padding(
                padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
                child: SizedBox(
                  height: sheetH,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: DefaultTextStyle.merge(
                          style: titleStyle,
                          child: const Text('Choose skill'),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: skillPickerColumn(routeContext, ctx, setState),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(routeContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    ctrl.dispose();
  }
}

/// Skills on the current grid that require a short player-written note (rules JSON).
List<RuleSkill> skillsRequiringPlayerNotes(
  MergedRules rules,
  SkillsState state,
) {
  final seen = <String>{};
  final out = <RuleSkill>[];
  for (var i = 0; i < 3; i++) {
    if (i >= state.skillsByStance.length) continue;
    for (var j = 0; j < 3; j++) {
      if (j >= state.skillsByStance[i].length) continue;
      final id = state.skillsByStance[i][j];
      if (id.isEmpty || id == 'skill_placeholder' || !seen.add(id)) continue;
      final sk = rules.skillById(id);
      final max = sk?.playerNoteMaxChars;
      if (sk != null && max != null && max > 0) {
        out.add(sk);
      }
    }
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

Future<String?> showTwoWordSkillDialog(
  BuildContext context, {
  required String initial,
}) async {
  final ctrl = TextEditingController(text: initial);
  String? error;
  try {
    return await showPickerAdaptive<String>(
      context: context,
      title: const Text('Two-word skill'),
      buildScrollableBody: (innerContext, setState) {
        void trySubmit() {
          final v = ctrl.text.trim();
          if (v.isEmpty) {
            setState(() {
              error = 'Enter a skill name.';
            });
            return;
          }
          if (v.length > kCustomHeroSkillMaxChars) {
            setState(() {
              error = 'At most $kCustomHeroSkillMaxChars characters.';
            });
            return;
          }
          Navigator.pop(innerContext, v);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The rules suggest a two-word name (e.g. Iron Palm). '
              'You can use any label up to $kCustomHeroSkillMaxChars characters.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: kCustomHeroSkillMaxChars,
              decoration: InputDecoration(
                errorText: error,
                hintText: 'e.g. Iron Palm',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => trySubmit(),
            ),
          ],
        );
      },
      buildActions: (routeContext, setState) {
        void trySubmit() {
          final v = ctrl.text.trim();
          if (v.isEmpty) {
            setState(() {
              error = 'Enter a skill name.';
            });
            return;
          }
          if (v.length > kCustomHeroSkillMaxChars) {
            setState(() {
              error = 'At most $kCustomHeroSkillMaxChars characters.';
            });
            return;
          }
          Navigator.pop(routeContext, v);
        }

        return [
          TextButton(
            onPressed: () => Navigator.pop(routeContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: trySubmit,
            child: const Text('Save'),
          ),
        ];
      },
    );
  } finally {
    ctrl.dispose();
  }
}
