import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character_policies.dart';
import '../../../domain/hero_type_kind.dart';
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

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final picks = List<String>.from(initialPicks);
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 560.0);
          final slotPick = picks[editSlotIndex].isEmpty
              ? null
              : picks[editSlotIndex];
          final theme = Theme.of(context);
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
            return RadioListTile<String>(
              value: a.id,
              groupValue: slotPick,
              onChanged: (v) {
                if (v == null) return;
                setState(() => picks[editSlotIndex] = v);
              },
              title: Row(
                children: [
                  if (ruleViolation != null) ...[
                    RuleViolationTriangle(message: ruleViolation),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text('${a.name} ($stars)')),
                  _archetypeInfoIcon(context, a),
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

          return AlertDialog(
            title: const Text('Choose Archetype'),
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
                onPressed: slotPick == null
                    ? null
                    : () async {
                        final err = policies.validateArchetypeSlotPick(
                          heroType,
                          picks,
                          slotPick,
                          editSlotIndex,
                        );
                        if (err != null) {
                          onValidationError?.call(err);
                          return;
                        }
                        await onApply(List<String>.from(picks));
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

Widget _archetypeInfoIcon(BuildContext context, RuleArchetype a) {
  final text = _archetypeTooltipDescription(a);
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
    child: const Icon(Icons.info_outline, size: 18),
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
