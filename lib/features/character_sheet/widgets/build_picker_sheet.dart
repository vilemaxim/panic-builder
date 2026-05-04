import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import 'picker_presentation.dart';

String _buildTooltipMessage(RuleBuild b) {
  final desc = b.description.trim();
  final stats = 'Max HP ${b.maxHp} · Bars ${b.hpBars}/${b.totalBars}';
  if (desc.isEmpty) return stats;
  return '$desc\n\n$stats';
}

Future<void> showBuildPickerSheet(
  BuildContext context, {
  required MergedRules rules,
  required String? initialBuildId,
  required Future<void> Function(String? buildId) onApply,
}) async {
  var selected = initialBuildId;
  await showPickerAdaptive<void>(
    context: context,
    title: const Text('Choose Build'),
    buildScrollableBody: (innerContext, setState) {
      final theme = Theme.of(innerContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rules.builds.map(
            (b) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<String>(
                value: b.id,
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selected = v);
                },
              ),
              title: Text(
                b.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Tooltip(
                message: _buildTooltipMessage(b),
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
              onTap: () => setState(() => selected = b.id),
            ),
          ),
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
