import '../../../data/rules_models.dart';

/// Full rules copy for style tooltips: linked style skill when [rules] is set,
/// else basic info + margin notes.
String stanceStyleRulesBody(RuleStyle s, [MergedRules? rules]) {
  final sk = rules?.skillById(s.skillId);
  final hasPrintedFields = s.range.trim().isNotEmpty ||
      s.passive.trim().isNotEmpty ||
      s.actions.isNotEmpty;

  if (hasPrintedFields) {
    final buf = StringBuffer();
    buf.writeln(s.name.trim());
    if (s.range.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln('Range: ${s.range.trim()}');
    }
    if (s.passive.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln(s.passive.trim());
    }
    if (s.actions.isNotEmpty) {
      buf.writeln();
      for (final a in s.actions) {
        buf.writeln('• ${a.heading.trim()}');
        final ad = a.description.trim();
        if (ad.isNotEmpty) buf.writeln(ad);
        buf.writeln();
      }
    }
    if (sk != null && sk.description.trim().isNotEmpty) {
      buf.writeln('Pairings & notes:');
      buf.writeln(sk.description.trim());
    } else {
      final desc = s.description.trim();
      final bi = s.basicInfo.trim();
      final mn = s.marginNotes.trim();
      final tail = <String>[];
      if (desc.isNotEmpty) tail.add(desc);
      if (bi.isNotEmpty) tail.add(bi);
      if (mn.isNotEmpty) tail.add(mn);
      if (tail.isNotEmpty) {
        buf.writeln();
        buf.writeln(tail.join('\n\n'));
      }
    }
    return buf.toString().trim();
  }

  if (sk != null && sk.description.trim().isNotEmpty) {
    final n = sk.name.trim();
    final d = sk.description.trim();
    if (n.isEmpty) return d;
    return '$n\n\n$d';
  }
  final desc = s.description.trim();
  final bi = s.basicInfo.trim();
  final mn = s.marginNotes.trim();
  final buf = <String>[];
  if (desc.isNotEmpty) buf.add(desc);
  if (bi.isNotEmpty) buf.add(bi);
  if (mn.isNotEmpty) buf.add(mn);
  if (buf.isEmpty) return 'No description.';
  return buf.join('\n\n');
}

/// Form name, alt names, and granted skills with descriptions from [rules].
String stanceFormRulesBody(RuleForm f, MergedRules rules) {
  final buf = StringBuffer();
  buf.writeln(f.name.trim());
  if (f.dice.isNotEmpty) {
    buf.writeln();
    buf.writeln('Dice: ${f.dice.join(', ')}');
  }
  final passive =
      f.passive.trim().isNotEmpty ? f.passive.trim() : f.description.trim();
  if (passive.isNotEmpty) {
    buf.writeln();
    buf.writeln(passive);
  }
  if (f.actions.isNotEmpty) {
    buf.writeln();
    for (final a in f.actions) {
      buf.writeln('• ${a.heading.trim()}');
      final ad = a.description.trim();
      if (ad.isNotEmpty) buf.writeln(ad);
      buf.writeln();
    }
  }
  if (f.altNames.isNotEmpty) {
    buf.writeln(
      'Also known as: ${f.altNames.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ')}.',
    );
  }
  buf.writeln();
  buf.writeln('Skills:');
  for (final id in f.skillIds) {
    final sk = rules.skillById(id);
    if (sk != null) {
      final d = sk.description.trim();
      buf.writeln(d.isEmpty ? '• ${sk.name}' : '• ${sk.name}: $d');
    } else {
      buf.writeln('• $id');
    }
  }
  return buf.toString().trim();
}
