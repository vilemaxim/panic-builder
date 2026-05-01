import 'package:flutter/material.dart';

import '../../data/rules_models.dart';
import '../../domain/character.dart';
import '../../domain/character_policies.dart';
import '../../domain/skills_state.dart';

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
  out.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return out;
}

/// First differing cell between [state] and [draft], or null if identical.
({int si, int sj})? firstSkillDiff(
  SkillsState state,
  SkillsStateDraft draft,
) {
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
  return SkillsState(
    skillsByStance: rows,
    swappedStanceIndex: stanceIndex,
    swappedSlotIndex: 0,
    replacementSkillId: newSkillId,
    twoWordSkill: c.skillsState?.twoWordSkill ?? '',
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
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
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
          return AlertDialog(
            title: const Text('Choose skill'),
            content: SizedBox(
              width: 520,
              height: 420,
              child: Column(
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
                                selected: selected,
                                title: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    desc.isEmpty ? '—' : desc,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                isThreeLine: true,
                                onTap: () =>
                                    Navigator.pop(dialogContext, s.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> showTwoWordSkillDialog(
  BuildContext context, {
  required String initial,
}) async {
  final ctrl = TextEditingController(text: initial);
  String? error;
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Two-word skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter exactly two words for your custom skill name.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  errorText: error,
                  hintText: 'e.g. Iron Palm',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final v = ctrl.text.trim();
                  final words = v.split(RegExp(r'\s+'));
                  if (words.length != 2 || words.any((w) => w.isEmpty)) {
                    setState(() {
                      error = 'Use exactly two words.';
                    });
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final v = ctrl.text.trim();
                final words = v.split(RegExp(r'\s+'));
                if (words.length != 2 || words.any((w) => w.isEmpty)) {
                  setState(() {
                    error = 'Use exactly two words.';
                  });
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
