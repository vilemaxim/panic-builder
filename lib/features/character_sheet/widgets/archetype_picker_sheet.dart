import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/character_policies.dart';
import '../../../domain/hero_type_kind.dart';

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

  final picks = policies.paddedArchetypeIds(heroType, initialArchetypeIds);

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Choose Archetype'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...rules.archetypes.where((a) {
                  // For multi-slot heroes (Fused/Frantic), hide archetypes already
                  // selected in other slots so each remaining picker only shows valid options.
                  for (var i = 0; i < picks.length; i++) {
                    if (i == editSlotIndex) continue;
                    if (picks[i].isNotEmpty && picks[i] == a.id) return false;
                  }
                  return true;
                }).map((a) {
                  final current =
                      picks[editSlotIndex].isEmpty ? null : picks[editSlotIndex];
                  final complexity = a.complexity.clamp(1, 3);
                  final stars = '${'★' * complexity}${'☆' * (3 - complexity)}';
                  return RadioListTile<String>(
                    value: a.id,
                    groupValue: current,
                    onChanged: (v) async {
                      if (v == null) return;
                      picks[editSlotIndex] = v;
                      setState(() {});
                      final err = policies.validateArchetypeSlotPick(
                        heroType,
                        picks,
                        v,
                        editSlotIndex,
                      );
                      if (err != null) {
                        onValidationError?.call(err);
                        return;
                      }
                      await onApply(List<String>.from(picks));
                      if (context.mounted) Navigator.pop(context);
                    },
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${a.name} ($stars)',
                          ),
                        ),
                        _archetypeInfoIcon(context, a),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    ),
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
