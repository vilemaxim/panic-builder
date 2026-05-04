import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character_policies.dart';
import '../../../domain/hero_type_kind.dart';
import 'picker_presentation.dart';
import 'rule_violation_marker.dart';

Future<void> showArchetypePickerSheet(
  BuildContext context, {
  required MergedRules rules,
  required CharacterPolicies policies,
  required HeroTypeKind? heroType,
  required int editSlotIndex,
  required List<String> initialArchetypeIds,
  required Future<void> Function(List<String> ids) onApply,
  void Function(String message)? onValidationError,
}) async {
  if (heroType == null) {
    onValidationError?.call('Pick hero type first.');
    return;
  }
  final slots = policies.archetypeSlotCount(heroType);
  if (slots == 0) {
    onValidationError?.call('No archetype slots for this hero type.');
    return;
  }
  if (editSlotIndex < 0 || editSlotIndex >= slots) {
    onValidationError?.call('Invalid archetype slot.');
    return;
  }

  final initialPicks = policies.paddedArchetypeIds(
    heroType,
    initialArchetypeIds,
  );

  final picks = List<String>.from(initialPicks);
  await showPickerAdaptive<void>(
    context: context,
    title: const Text('Choose Archetype'),
    buildScrollableBody: (innerContext, setState) {
      final slotPick = picks[editSlotIndex].isEmpty
          ? null
          : picks[editSlotIndex];
      final theme = Theme.of(innerContext);
          final allowed = <RuleArchetype>[];
          final disallowed = <RuleArchetype>[];
          for (final a in rules.archetypes) {
            var takenElsewhere = false;
            for (var i = 0; i < picks.length; i++) {
              if (i == editSlotIndex) continue;
              if (picks[i].isNotEmpty && picks[i] == a.id) {
                takenElsewhere = true;
                break;
              }
            }
            if (takenElsewhere) {
              disallowed.add(a);
            } else {
              allowed.add(a);
            }
          }
          allowed.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          disallowed.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          Widget archetypeTile(RuleArchetype a, String? ruleViolation) {
            final complexity = a.complexity.clamp(1, 3);
            final stars = '${'★' * complexity}${'☆' * (3 - complexity)}';
            final line = '${a.name} ($stars)';
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<String>(
                value: a.id,
                groupValue: slotPick,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => picks[editSlotIndex] = v);
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
                            line,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: _archetypeInfoIcon(innerContext, a),
              onTap: () => setState(() => picks[editSlotIndex] = a.id),
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
                  'No archetypes left that are not already chosen in another slot.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ...allowed.map((a) => archetypeTile(a, null)),
            if (disallowed.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Archetypes already chosen elsewhere (hover the red marker — you may still pick)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...disallowed.map((a) {
                final msg = policies.explainArchetypeDuplicateForSlot(
                  heroType,
                  picks,
                  editSlotIndex,
                  a.id,
                );
                return archetypeTile(a, msg ?? 'Archetypes must be distinct.');
              }),
            ],
          ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: columnChildren,
      );
    },
    buildActions: (routeContext, setState) {
      final slot = picks[editSlotIndex].isEmpty ? null : picks[editSlotIndex];
      return [
        TextButton(
          onPressed: () => Navigator.pop(routeContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: slot == null
              ? null
              : () async {
                  final err = policies.validateArchetypeSlotPick(
                    heroType,
                    picks,
                    slot,
                    editSlotIndex,
                  );
                  if (err != null) {
                    onValidationError?.call(err);
                    return;
                  }
                  await onApply(List<String>.from(picks));
                  if (routeContext.mounted) {
                    Navigator.pop(routeContext);
                  }
                },
          child: const Text('Apply'),
        ),
      ];
    },
  );
}

Widget _archetypeInfoIcon(BuildContext context, RuleArchetype a) {
  final text = _archetypeTooltipDescription(a);
  final scheme = Theme.of(context).colorScheme;
  return Tooltip(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: const EdgeInsets.all(10),
    preferBelow: true,
    waitDuration: const Duration(milliseconds: 200),
    showDuration: const Duration(seconds: 30),
    richMessage: WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 400),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ),
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1B16),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Semantics(
      label: 'Archetype details',
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    ),
  );
}

String _archetypeTooltipDescription(RuleArchetype a) {
  final description = a.description.trim();
  final lower = description.toLowerCase();
  final looksPlaceholder =
      description.isEmpty ||
      lower == a.name.trim().toLowerCase() ||
      lower == '${a.name.trim().toLowerCase()} archetype.' ||
      lower == 'archetype.';

  if (!looksPlaceholder) return description;

  final summary = a.abilitiesSummary.trim();
  if (summary.isNotEmpty) return summary;

  for (final key in const ['focused', 'fused', 'frantic']) {
    final ability = (a.abilitiesByHeroType[key] ?? '').trim();
    if (ability.isNotEmpty) return ability;
  }
  return 'No description provided.';
}
