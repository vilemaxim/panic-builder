import 'rules_models.dart';

RuleFormChoice? ruleFormChoiceById(RuleForm form, String? choiceId) {
  if (choiceId == null || choiceId.trim().isEmpty) return null;
  final t = choiceId.trim();
  for (final c in form.choices) {
    if (c.id == t) return c;
  }
  return null;
}

bool ruleFormChoiceModifiesRange(RuleFormChoice c) {
  return (c.minRange != null && c.minRange != 0) ||
      (c.maxRange != null && c.maxRange != 0) ||
      c.absoluteMin != null ||
      c.absoluteMax != null;
}

/// Paragraph splits matching stance / form panels (blank-line separated).
List<String> splitRuleParagraphs(String text) {
  final t = text.replaceAll('\r', '').trim();
  if (t.isEmpty) return const [];
  return t
      .split(RegExp(r'\n\s*\n+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Everything after the first blank-line-separated block (used to drop the
/// “choose one …” intro when a [RuleFormChoice] is selected).
String passiveTailAfterFirstParagraphBlock(String passive) {
  final parts = passive.split(RegExp(r'\n\s*\n+'));
  if (parts.length < 2) return '';
  return parts.sublist(1).join('\n\n').trim();
}

String abbreviateFormChoiceForSheet(String text) {
  const maxLen = 140;
  final t = text.trim();
  if (t.length <= maxLen) return t;
  return '${t.substring(0, maxLen - 1)}…';
}

/// Passive copy for the stance / form card: when [formChoiceId] resolves to a
/// choice, the first paragraph becomes that choice’s text (full when
/// [fullChoiceText] is true, otherwise abbreviated for sheet density).
List<String> formPassiveParagraphsForDisplay(
  RuleForm form,
  String? formChoiceId, {
  required bool fullChoiceText,
}) {
  final passiveLine =
      form.passive.trim().isNotEmpty
          ? form.passive.trim()
          : (form.actions.isNotEmpty ? form.description.trim() : '');
  if (form.choices.isEmpty) {
    return passiveLine.isEmpty ? const [] : splitRuleParagraphs(passiveLine);
  }
  final ch = ruleFormChoiceById(form, formChoiceId);
  if (ch == null) {
    return passiveLine.isEmpty ? const [] : splitRuleParagraphs(passiveLine);
  }
  final head =
      fullChoiceText
          ? (ch.helpText != null && ch.helpText!.trim().isNotEmpty
              ? ch.helpText!.trim()
              : ch.text.trim())
          : abbreviateFormChoiceForSheet(ch.text.trim());
  final tail = passiveTailAfterFirstParagraphBlock(
    form.passive.trim().isNotEmpty ? form.passive : form.description,
  );
  final out = <String>[];
  if (head.isNotEmpty) out.add(head);
  if (tail.isNotEmpty) {
    out.addAll(splitRuleParagraphs(tail));
  }
  return out;
}
