import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import 'picker_presentation.dart';

/// Picks a [RuleFormChoice.id] when [form.choices] is non-empty.
Future<String?> showFormRuleChoicesDialog(
  BuildContext context, {
  required RuleForm form,
  String? initialChoiceId,
}) async {
  if (form.choices.isEmpty) return null;
  final initial = initialChoiceId?.trim();
  late String selected;
  if (initial != null && form.choices.any((c) => c.id == initial)) {
    selected = initial;
  } else {
    selected = form.choices.first.id;
  }
  return showPickerAdaptive<String>(
    context: context,
    title: Text(
      '${form.name.trim()}: choose a rule',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    buildScrollableBody: (innerContext, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in form.choices)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              visualDensity: VisualDensity.compact,
              leading: Radio<String>(
                value: c.id,
                groupValue: selected,
                onChanged: (v) {
                  if (v != null) setState(() => selected = v);
                },
              ),
              title: Text(
                c.text.trim().isEmpty ? c.id : c.text.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: c.helpText != null && c.helpText!.trim().isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        c.helpText!.trim(),
                        style: Theme.of(innerContext).textTheme.bodySmall,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
              onTap: () => setState(() => selected = c.id),
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
        onPressed: () => Navigator.pop(routeContext, selected),
        child: const Text('OK'),
      ),
    ],
  );
}
