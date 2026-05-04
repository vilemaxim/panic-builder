import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character_policies.dart';
import '../../../domain/hero_type_kind.dart';
import '../../../domain/stance.dart';
import 'rule_violation_marker.dart';
import 'picker_presentation.dart';
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
  var selected = (initialStyleId != null && initialStyleId.isNotEmpty)
      ? initialStyleId
      : null;
  await showPickerAdaptive<void>(
    context: context,
    title: const Text('Choose Style'),
    buildScrollableBody: (innerContext, setState) {
      final theme = Theme.of(innerContext);
          final allowed = policies.allowedStyleIdsForStance(
            hero: hero,
            archetypeIds: archetypeIds,
            stanceIndex: stanceIndex,
            partialStances: partialStances,
          );
          final allowedSet = allowed.toSet();
          final allIds = rules.styles.map((s) => s.id).toList();
          final disallowed = allIds
              .where((id) => !allowedSet.contains(id))
              .toList();
          final allowedSorted = _sortedStyleIds(rules, allowed);
          final disallowedSorted = _sortedStyleIds(rules, disallowed);

          Widget styleTile(String id, String? ruleViolation) {
            final s = rules.styleById(id);
            if (s == null) return const SizedBox.shrink();
            final arch = rules.archetypeById(s.archetypeId);
            final archetypeLabel = (arch?.name ?? s.archetypeId).trim();
            final styleLine =
                '$archetypeLabel: ${_trimStyleSuffixForPicker(s.name)}';
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<String>(
                value: id,
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selected = v);
                },
              ),
              title: ruleViolation != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RuleViolationTriangle(message: ruleViolation),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            styleLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      styleLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: Tooltip(
                message: stanceStyleRulesBody(s, rules),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(10),
                preferBelow: true,
                waitDuration: const Duration(milliseconds: 200),
                child: Semantics(
                  label: 'Style rules details',
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ),
              ),
              onTap: () => setState(() => selected = id),
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: columnChildren,
      );
    },
    buildActions: (routeContext, setState) => [
      TextButton(
        onPressed: () => Navigator.pop(routeContext),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: selected == null
            ? null
            : () async {
                await onApply(selected!);
                if (routeContext.mounted) {
                  Navigator.pop(routeContext);
                }
              },
        child: const Text('Apply'),
      ),
    ],
  );
}

List<RuleForm> _sortedFormsByName(List<RuleForm> forms) {
  final out = List<RuleForm>.from(forms);
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
  final allFormsSorted = _sortedFormsByName(List<RuleForm>.from(rules.forms));
  var selected = (initialFormId != null && initialFormId.isNotEmpty)
      ? initialFormId
      : null;
  return showPickerAdaptive<String>(
    context: context,
    title: const Text('Choose Form'),
    buildScrollableBody: (innerContext, setState) {
      final theme = Theme.of(innerContext);
          final cur = stanceIndex < stancesPadded.length
              ? stancesPadded[stanceIndex].formId
              : '';
          final usedElsewhere = <String>{};
          for (var i = 0; i < stancesPadded.length; i++) {
            if (i == stanceIndex) continue;
            final fid = stancesPadded[i].formId;
            if (fid.isNotEmpty) usedElsewhere.add(fid);
          }
          final allowed = allFormsSorted
              .where((f) => !usedElsewhere.contains(f.id) || f.id == cur)
              .toList();
          final disallowed = allFormsSorted
              .where((f) => usedElsewhere.contains(f.id) && f.id != cur)
              .toList();

          Widget formTile(RuleForm f, String? ruleViolation) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<String>(
                value: f.id,
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selected = v);
                },
              ),
              title: ruleViolation != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RuleViolationTriangle(message: ruleViolation),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Tooltip(
                message: stanceFormRulesBody(f, rules),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(10),
                preferBelow: true,
                waitDuration: const Duration(milliseconds: 200),
                child: Semantics(
                  label: 'Form rules details',
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ),
              ),
              onTap: () => setState(() => selected = f.id),
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
                return formTile(
                  f,
                  msg ?? 'Each stance must use a different form.',
                );
              }),
            ],
          ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: columnChildren,
      );
    },
    buildActions: (routeContext, setState) => [
      TextButton(
        onPressed: () => Navigator.pop(routeContext),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: selected == null || allFormsSorted.isEmpty
            ? null
            : () => Navigator.pop(routeContext, selected),
        child: const Text('Apply'),
      ),
    ],
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
  String? selected;
  return showPickerAdaptive<String>(
    context: context,
    title: const Text('Form name on sheet'),
    buildScrollableBody: (innerContext, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose how this form appears on your character sheet.',
            style: Theme.of(innerContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...choices.map((label) {
            final isCanonical =
                label.toLowerCase() == canonical.toLowerCase();
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<String>(
                value: label,
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selected = v);
                },
              ),
              title: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                isCanonical ? 'Rulebook name' : 'Alternate name',
                style: Theme.of(innerContext).textTheme.bodySmall,
              ),
              onTap: () => setState(() => selected = label),
            );
          }),
        ],
      );
    },
    buildActions: (routeContext, setState) => [
      TextButton(
        onPressed: () => Navigator.pop(routeContext),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: selected == null
            ? null
            : () => Navigator.pop(routeContext, selected),
        child: const Text('Apply'),
      ),
    ],
  );
}
