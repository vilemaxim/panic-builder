import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/hero_type_kind.dart';

/// Same hero-type picker used from the creation wizard and the rulebook banner.
Future<void> showHeroTypePickerSheet(
  BuildContext context, {
  required MergedRules rules,
  required HeroTypeKind? initial,
  required Future<void> Function(HeroTypeKind? selected) onApply,
}) async {
  HeroTypeKind? selected = initial;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Choose Hero Type'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...rules.heroTypes.map((h) {
                  final k = HeroTypeKindX.tryParse(h.id);
                  if (k == null) return const SizedBox.shrink();
                  return RadioListTile<HeroTypeKind>(
                    value: k,
                    groupValue: selected,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => selected = v);
                      await onApply(v);
                      if (context.mounted) Navigator.pop(context);
                    },
                    title: Text(h.name),
                    subtitle: Text(h.restrictions),
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
