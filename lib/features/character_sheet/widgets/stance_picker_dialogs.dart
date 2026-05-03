import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character_policies.dart';
import '../../../domain/hero_type_kind.dart';
import '../../../domain/stance.dart';
import 'rule_violation_marker.dart';
import 'stance_rules_tooltip.dart';

/// Matches stance sheet / PDF trimming of trailing ` Style`.
String _trimStyleSuffixForPicker(String value) {
  final v = value.trim();
  if (v.toLowerCase().endsWith(' style')) {
    return v.substring(0, v.length - 6).trim();
  }
  return v;
}

/// Canonical form name plus distinct alternate names (trimmed, non-empty, case-insensitive dedupe).
List<String> formDisplayNameChoices(RuleForm form) {
  final out = <String>[];
  final seen = <String>{};
  void tryAdd(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return;
    final key = s.toLowerCase();
    if (seen.contains(key)) return;
    seen.add(key);
    out.add(s);
  }

  tryAdd(form.name);
  for (final a in form.altNames) {
    tryAdd(a);
  }
  return out;
}

List<String> _sortedStyleIds(MergedRules rules, Iterable<String> ids) {
  final list = ids.toList();
  list.sort((a, b) {
    final na = (rules.styleById(a)?.name ?? a).toLowerCase();
    final nb = (rules.styleById(b)?.name ?? b).toLowerCase();
    return na.compareTo(nb);
  });
  return list;
}

Future<void> showStanceStylePickDialog(
  BuildContext context, {
  required MergedRules rules,
  required CharacterPolicies policies,
  required HeroTypeKind hero,
  required List<String> archetypeIds,
  required int stanceIndex,
  required List<Stance> partialStances,
  required String? initialStyleId,
  required Future<void> Function(String styleId) onApply,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String? selected =
          (initialStyleId != null && initialStyleId.isNotEmpty)
              ? initialStyleId
              : null;
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 560.0);
          final theme = Theme.of(context);
          final allowed = policies.allowedStyleIdsForStance(
            hero: hero,
            archetypeIds: archetypeIds,
            stanceIndex: stanceIndex,
            partialStances: partialStances,
          );
          final allowedSet = allowed.toSet();
          final allIds = rules.styles.map((s) => s.id).toList();
          final disallowed = allIds.where((id) => !allowedSet.contains(id)).toList();
          final allowedSorted = _sortedStyleIds(rules, allowed);
          final disallowedSorted = _sortedStyleIds(rules, disallowed);

          Widget styleTile(String id, String? ruleViolation) {
            final s = rules.styleById(id);
            if (s == null) return const SizedBox.shrink();
            final arch = rules.archetypeById(s.archetypeId);
            final archetypeLabel = (arch?.name ?? s.archetypeId).trim();
            final styleLine =
                '$archetypeLabel: ${_trimStyleSuffixForPicker(s.name)}';
            return RadioListTile<String>(
              value: id,
              groupValue: selected,
              onChanged: (v) {
                if (v == null) return;
                setState(() => selected = v);
              },
              title: Row(
                children: [
                  if (ruleViolation != null) ...[
                    RuleViolationTriangle(message: ruleViolation),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text(styleLine)),
                  Tooltip(
                    message: stanceStyleRulesBody(s, rules),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(10),
                    preferBelow: true,
                    waitDuration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.info_outline, size: 18),
                  ),
                ],
              ),
            );
          }

          final columnChildren = <Widget>[
            Text(
              'Matches printed rules',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (allowedSorted.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No styles satisfy the printed rules for this stance with your current picks.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ...allowedSorted.map((id) => styleTile(id, null)),
            if (disallowedSorted.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Other styles (hover the red marker for the rule — you may still pick)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...disallowedSorted.map((id) {
                final msg = policies.explainWhyStyleNotAllowed(
                  hero: hero,
                  archetypeIds: archetypeIds,
                  stanceIndex: stanceIndex,
                  partialStances: partialStances,
                  styleId: id,
                );
                return styleTile(id, msg ?? 'Does not match printed rules.');
              }),
            ],
          ];

          return AlertDialog(
            title: const Text('Choose Style'),
            content: SizedBox(
              width: contentWidth,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: columnChildren,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        await onApply(selected!);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

List<RuleForm> _sortedFormsByName(List<RuleForm> forms) {
  final out = List<RuleForm>.from(forms);
  out.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return out;
}

/// Returns selected form id, or null if dismissed without applying.
Future<String?> showStanceFormPickDialog(
  BuildContext context, {
  required MergedRules rules,
  required CharacterPolicies policies,
  required List<Stance> stancesPadded,
  required int stanceIndex,
  required String? initialFormId,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String? selected =
          (initialFormId != null && initialFormId.isNotEmpty)
              ? initialFormId
              : null;
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 560.0);
          final theme = Theme.of(context);
          final cur = stanceIndex < stancesPadded.length
              ? stancesPadded[stanceIndex].formId
              : '';
          final usedElsewhere = <String>{};
          for (var i = 0; i < stancesPadded.length; i++) {
            if (i == stanceIndex) continue;
            final fid = stancesPadded[i].formId;
            if (fid.isNotEmpty) usedElsewhere.add(fid);
          }
          final allForms = _sortedFormsByName(List<RuleForm>.from(rules.forms));
          final allowed = allForms
              .where((f) => !usedElsewhere.contains(f.id) || f.id == cur)
              .toList();
          final disallowed = allForms
              .where((f) => usedElsewhere.contains(f.id) && f.id != cur)
              .toList();

          Widget formTile(RuleForm f, String? ruleViolation) {
            return RadioListTile<String>(
              value: f.id,
              groupValue: selected,
              onChanged: (v) {
                if (v == null) return;
                setState(() => selected = v);
              },
              title: Row(
                children: [
                  if (ruleViolation != null) ...[
                    RuleViolationTriangle(message: ruleViolation),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text(f.name)),
                  Tooltip(
                    message: stanceFormRulesBody(f, rules),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(10),
                    preferBelow: true,
                    waitDuration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.info_outline, size: 18),
                  ),
                ],
              ),
            );
          }

          final columnChildren = <Widget>[
            Text(
              'Matches printed rules',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (allowed.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No forms left that avoid reusing a form from another stance.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ...allowed.map((f) => formTile(f, null)),
            if (disallowed.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Forms already used on another stance (hover the red marker — you may still pick)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...disallowed.map((f) {
                final msg = policies.explainFormUsedOnAnotherStance(
                  stances: stancesPadded,
                  stanceIndex: stanceIndex,
                  formId: f.id,
                );
                return formTile(f, msg ?? 'Each stance must use a different form.');
              }),
            ],
          ];

          return AlertDialog(
            title: const Text('Choose Form'),
            content: SizedBox(
              width: contentWidth,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: columnChildren,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selected == null || allForms.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// How this form appears on the sheet: rulebook name plus alternates.
Future<String?> showFormDisplayNamePickDialog(
  BuildContext context, {
  required RuleForm form,
  required List<String> choices,
}) async {
  if (choices.isEmpty) return form.name.trim();
  final canonical = form.name.trim();
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String? selected;
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 520.0);
          return AlertDialog(
            title: const Text('Form name on sheet'),
            content: SizedBox(
              width: contentWidth,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Choose how this form appears on your character sheet.',
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ...choices.map((label) {
                      final isCanonical =
                          label.toLowerCase() == canonical.toLowerCase();
                      return RadioListTile<String>(
                        value: label,
                        groupValue: selected,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selected = v);
                        },
                        title: Text(label),
                        subtitle: Text(
                          isCanonical ? 'Rulebook name' : 'Alternate name',
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    selected == null ? null : () => Navigator.pop(dialogContext, selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}
