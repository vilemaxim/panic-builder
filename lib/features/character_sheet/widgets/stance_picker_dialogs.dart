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
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String? selected =
          (initialStyleId != null && initialStyleId.isNotEmpty)
              ? initialStyleId
              : null;
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 560.0);
          return AlertDialog(
            title: const Text('Choose Style'),
            content: SizedBox(
              width: contentWidth,
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
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => selected = v);
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    selected == null || allowedStyleIds.isEmpty
                        ? null
                        : () async {
                            await onApply(selected!);
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

/// Returns selected form id, or null if dismissed without applying.
Future<String?> showStanceFormPickDialog(
  BuildContext context, {
  required MergedRules rules,
  required List<RuleForm> forms,
  required String? initialFormId,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String? selected =
          (initialFormId != null && initialFormId.isNotEmpty)
              ? initialFormId
              : null;
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 560.0);
          return AlertDialog(
            title: const Text('Choose Form'),
            content: SizedBox(
              width: contentWidth,
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
                            setState(() => selected = v);
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    selected == null || forms.isEmpty
                        ? null
                        : () => Navigator.pop(dialogContext, selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
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
    builder: (dialogContext) {
      String? selected;
      return StatefulBuilder(
        builder: (context, setState) {
          final screenW = MediaQuery.sizeOf(context).width;
          final contentWidth = (screenW - 48).clamp(280.0, 520.0);
          return AlertDialog(
            title: const Text('Form name on sheet'),
            content: SizedBox(
              width: contentWidth,
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
                      return RadioListTile<String>(
                        value: label,
                        groupValue: selected,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selected = v);
                        },
                        title: Text(label),
                        subtitle: Text(
                          isCanonical ? 'Rulebook name' : 'Alternate name',
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
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
                onPressed:
                    selected == null ? null : () => Navigator.pop(dialogContext, selected),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}
