import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';

Future<void> showBuildPickerSheet(
  BuildContext context, {
  required MergedRules rules,
  required String? initialBuildId,
  required Future<void> Function(String? buildId) onApply,
}) async {
  String? selected = initialBuildId;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final screenW = MediaQuery.sizeOf(context).width;
        final contentWidth = (screenW - 48).clamp(280.0, 560.0);
        return AlertDialog(
          title: const Text('Choose Build'),
          content: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...rules.builds.map(
                    (b) => RadioListTile<String>(
                      value: b.id,
                      groupValue: selected,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selected = v);
                      },
                      title: Row(
                        children: [
                          Expanded(child: Text(b.name)),
                          Tooltip(
                            message: b.description,
                            child: const Icon(Icons.info_outline, size: 18),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Max HP ${b.maxHp} · Bars ${b.hpBars}/${b.totalBars}',
                      ),
                    ),
                  ),
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
