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
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final screenW = MediaQuery.sizeOf(context).width;
        final contentWidth = (screenW - 48).clamp(280.0, 520.0);
        return AlertDialog(
          title: const Text('Choose Hero Type'),
          content: SizedBox(
            width: contentWidth,
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
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selected = v);
                      },
                      title: Text(h.name),
                      subtitle: Text(h.restrictions),
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
              onPressed: selected == null
                  ? null
                  : () async {
                      await onApply(selected);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    ),
  );
}
