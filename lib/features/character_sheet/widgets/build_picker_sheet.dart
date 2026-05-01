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
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Choose Build'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...rules.builds.map(
                  (b) => RadioListTile<String>(
                    value: b.id,
                    groupValue: selected,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => selected = v);
                      await onApply(v);
                      if (context.mounted) Navigator.pop(context);
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
      ),
    ),
  );
}
