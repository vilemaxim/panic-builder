import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import '../../../domain/hero_type_kind.dart';
import 'picker_presentation.dart';

/// Same hero-type picker used from the creation wizard and the rulebook banner.
Future<void> showHeroTypePickerSheet(
  BuildContext context, {
  required MergedRules rules,
  required HeroTypeKind? initial,
  required Future<void> Function(HeroTypeKind? selected) onApply,
}) async {
  var selected = initial;
  await showPickerAdaptive<void>(
    context: context,
    title: const Text('Choose Hero Type'),
    buildScrollableBody: (innerContext, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rules.heroTypes.map((h) {
            final k = HeroTypeKindX.tryParse(h.id);
            if (k == null) return const SizedBox.shrink();
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<HeroTypeKind>(
                value: k,
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selected = v);
                },
              ),
              title: Text(
                h.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                h.restrictions,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => setState(() => selected = k),
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
            : () async {
                await onApply(selected);
                if (routeContext.mounted) {
                  Navigator.pop(routeContext);
                }
              },
        child: const Text('Apply'),
      ),
    ],
  );
}
