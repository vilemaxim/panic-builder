import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';

/// Picks a [RuleFormChoice.id] when [form.choices] is non-empty.
Future<String?> showFormRuleChoicesDialog(
  BuildContext context, {
  required RuleForm form,
  String? initialChoiceId,
}) async {
  if (form.choices.isEmpty) return null;
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return _FormChoiceDialogBody(
        form: form,
        initialChoiceId: initialChoiceId,
      );
    },
  );
}

class _FormChoiceDialogBody extends StatefulWidget {
  const _FormChoiceDialogBody({
    required this.form,
    this.initialChoiceId,
  });

  final RuleForm form;
  final String? initialChoiceId;

  @override
  State<_FormChoiceDialogBody> createState() => _FormChoiceDialogBodyState();
}

class _FormChoiceDialogBodyState extends State<_FormChoiceDialogBody> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialChoiceId?.trim();
    if (initial != null &&
        widget.form.choices.any((c) => c.id == initial)) {
      _selected = initial;
    } else {
      _selected = widget.form.choices.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;
    return AlertDialog(
      title: Text('${f.name.trim()}: choose a rule'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in f.choices)
                RadioListTile<String>(
                  value: c.id,
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v),
                  title: Text(
                    c.text.trim().isEmpty ? c.id : c.text.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      c.helpText != null && c.helpText!.trim().isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                c.helpText!.trim(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
