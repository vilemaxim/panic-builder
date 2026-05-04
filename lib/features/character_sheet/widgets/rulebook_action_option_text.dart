import 'package:flutter/material.dart';

/// Option lines in style/form/stance actions use `2+:`, `10+:`, etc. This pattern
/// marks the start of an option; the digits and `+` are emphasized in print.
final RegExp _kActionOptionPrefix = RegExp(r'(\d+\+)(:)');

/// Builds [TextSpan]s for one paragraph, bolding each `\d+\+` that is immediately
/// followed by `:` (the colon stays regular weight).
List<InlineSpan> rulebookActionOptionInlineSpans(
  String text,
  TextStyle baseStyle,
) {
  final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
  final spans = <InlineSpan>[];
  var start = 0;
  for (final m in _kActionOptionPrefix.allMatches(text)) {
    if (m.start > start) {
      spans.add(TextSpan(text: text.substring(start, m.start)));
    }
    spans.add(TextSpan(text: m.group(1)!, style: boldStyle));
    spans.add(TextSpan(text: m.group(2)!));
    start = m.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }
  return spans;
}

Widget rulebookActionOptionParagraph(String text, TextStyle baseStyle) {
  return Text.rich(
    TextSpan(
      style: baseStyle,
      children: rulebookActionOptionInlineSpans(text, baseStyle),
    ),
  );
}
