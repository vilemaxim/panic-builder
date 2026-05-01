import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import 'stance_rules_tooltip.dart';

/// Matches stance sheet / PDF trimming of trailing ` Style`.
String _trimStyleSuffixForPicker(String value) {
  final v = value.trim();
  if (v.toLowerCase().endsWith(' style')) {
    return v.substring(0, v.length - 6).trim();
  }
  return v;
}

/// Canonical form name plus distinct alternate names (trimmed, non-empty, case-insensitive dedupe).
List<String> formDisplayNameChoices(RuleForm form) {
  final out = <String>[];
  final seen = <String>{};
  void tryAdd(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return;
    final key = s.toLowerCase();
    if (seen.contains(key)) return;
    seen.add(key);
    out.add(s);
  }

  tryAdd(form.name);
  for (final a in form.altNames) {
    tryAdd(a);
  }
  return out;
}

Future<void> showStanceStylePickDialog(
  BuildContext context, {
  required MergedRules rules,
  required List<String> allowedStyleIds,
  required String? initialStyleId,
  required Future<void> Function(String styleId) onApply,
}) async {
  final selected =
      (initialStyleId != null && initialStyleId.isNotEmpty) ? initialStyleId : null;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: const Text('Choose Style'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allowedStyleIds.isEmpty)
                const Text('No styles available for this stance.')
              else
                ...allowedStyleIds.map((id) {
                  final s = rules.styleById(id);
                  if (s == null) return const SizedBox.shrink();
                  final arch = rules.archetypeById(s.archetypeId);
                  final archetypeLabel =
                      (arch?.name ?? s.archetypeId).trim();
                  final styleLine =
                      '$archetypeLabel: ${_trimStyleSuffixForPicker(s.name)}';
                  return RadioListTile<String>(
                    value: id,
                    groupValue: selected,
                    onChanged: (v) async {
                      if (v == null) return;
                      await onApply(v);
                      if (context.mounted) Navigator.pop(context);
                    },
                    title: Row(
                      children: [
                        Expanded(child: Text(styleLine)),
                        Tooltip(
                          message: stanceStyleRulesBody(s, rules),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(10),
                          preferBelow: true,
                          waitDuration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.info_outline, size: 18),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Returns selected form id, or null if dismissed without picking.
Future<String?> showStanceFormPickDialog(
  BuildContext context, {
  required MergedRules rules,
  required List<RuleForm> forms,
  required String? initialFormId,
}) async {
  final selected =
      (initialFormId != null && initialFormId.isNotEmpty) ? initialFormId : null;
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Choose Form'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (forms.isEmpty)
                const Text('No forms available.')
              else
                ...forms.map(
                  (f) => RadioListTile<String>(
                    value: f.id,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v == null) return;
                      Navigator.pop(dialogContext, v);
                    },
                    title: Row(
                      children: [
                        Expanded(child: Text(f.name)),
                        Tooltip(
                          message: stanceFormRulesBody(f, rules),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(10),
                          preferBelow: true,
                          waitDuration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.info_outline, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// How this form appears on the sheet: rulebook name plus alternates.
Future<String?> showFormDisplayNamePickDialog(
  BuildContext context, {
  required RuleForm form,
  required List<String> choices,
}) async {
  if (choices.isEmpty) return form.name.trim();
  final canonical = form.name.trim();
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Form name on sheet'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how this form appears on your character sheet.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...choices.map((label) {
                final isCanonical =
                    label.toLowerCase() == canonical.toLowerCase();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  subtitle: Text(
                    isCanonical ? 'Rulebook name' : 'Alternate name',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                  onTap: () => Navigator.pop(dialogContext, label),
                );
              }),
            ],
          ),
        ),
      ),
    ),
  );
}
