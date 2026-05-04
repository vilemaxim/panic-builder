import 'rules_models.dart';
import 'stance_form_display.dart';

/// Raw range token from the style card or skill text (e.g. `1`, `1-2`), before
/// form / choice deltas.
String styleRangeToken(RuleStyle? style, RuleSkill? skill) {
  if (style == null) return '';
  final r = style.range.trim();
  if (r.isNotEmpty) return r;
  final merged = skill != null && skill.description.trim().isNotEmpty
      ? skill.description
      : '${style.basicInfo}\n${style.marginNotes}';
  final m = RegExp(
    r'Range:\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(merged);
  return m?.group(1)?.trim() ?? '';
}

/// Parses a simple numeric style range (`4`, `1-2`). Returns null if [token] is
/// not two integers (or one integer) only.
({int min, int max, String token})? tryParseNumericStyleRangeToken(
  String token,
) {
  final t = token.trim();
  if (t.isEmpty) return null;
  final dash = RegExp(r'\s*[-–]\s*');
  if (dash.hasMatch(t)) {
    final parts = t.split(dash);
    if (parts.length >= 2) {
      final a = int.tryParse(parts[0].trim());
      final b = int.tryParse(parts[1].trim());
      if (a != null && b != null) {
        final lo = a <= b ? a : b;
        final hi = a <= b ? b : a;
        return (min: lo, max: hi, token: t);
      }
    }
  }
  final single = int.tryParse(t);
  if (single != null) {
    return (min: single, max: single, token: t);
  }
  return null;
}

bool _formDeclaresRangeModifiers(RuleForm? form) {
  if (form == null) return false;
  return form.choices.isEmpty &&
      (form.minRange != null || form.maxRange != null);
}

/// Stance subtitle: `Range: …` with optional `(original + FormTag)` when deltas
/// apply from a **choice** (forms with [RuleForm.choices]) or from [RuleForm]
/// directly when there are no choices (e.g. Blaster).
String formatStanceRangeSubtitle(
  RuleStyle? style,
  RuleSkill? skill,
  RuleForm? form,
  String formTagForParen, {
  RuleFormChoice? selectedFormChoice,
}) {
  if (style == null) return 'Range: —';
  final token = styleRangeToken(style, skill);
  if (token.isEmpty) return 'Range: —';

  final parsed = tryParseNumericStyleRangeToken(token);
  if (parsed == null) {
    return 'Range: $token';
  }

  var dMin = 0;
  var dMax = 0;
  int? absMin;
  int? absMax;
  var useModifiers = false;

  if (form != null && form.choices.isNotEmpty) {
    final ch = selectedFormChoice;
    if (ch == null || !ruleFormChoiceModifiesRange(ch)) {
      return 'Range: $token';
    }
    dMin = ch.minRange ?? 0;
    dMax = ch.maxRange ?? 0;
    absMin = ch.absoluteMin;
    absMax = ch.absoluteMax;
    useModifiers = true;
  } else if (form != null && _formDeclaresRangeModifiers(form)) {
    dMin = form.minRange ?? 0;
    dMax = form.maxRange ?? 0;
    useModifiers = true;
  }

  if (!useModifiers) {
    return 'Range: $token';
  }

  var newMin = parsed.min + dMin;
  var newMax = parsed.max + dMax;
  final aMin = absMin;
  if (aMin != null) {
    newMin = aMin;
  }
  final aMax = absMax;
  if (aMax != null) {
    newMax = aMax;
  }
  if (newMin < 0 || newMax < 0 || newMax < newMin) {
    return 'Range: $token';
  }

  final newTok = newMin == newMax ? '$newMin' : '$newMin-$newMax';
  final tag = formTagForParen.trim();
  final orig = parsed.token;
  if (tag.isEmpty || tag == 'Form') {
    return 'Range: $newTok ($orig)';
  }
  return 'Range: $newTok ($orig + $tag)';
}
