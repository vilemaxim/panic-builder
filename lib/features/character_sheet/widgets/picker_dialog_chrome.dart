import 'package:flutter/material.dart';

/// Tighter [Radio] hit targets and a calmer dialog title for list-style pickers
/// (Material 3 default radios + dialog titles read oversized on phones).
Widget withPickerDialogChrome(BuildContext context, Widget child) {
  final t = Theme.of(context);
  return Theme(
    data: t.copyWith(
      visualDensity: VisualDensity.compact,
      radioTheme: const RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: t.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    child: child,
  );
}
