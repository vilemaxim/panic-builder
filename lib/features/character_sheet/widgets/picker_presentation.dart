import 'package:flutter/material.dart';

import 'picker_dialog_chrome.dart';

/// Viewports narrower than this use a full-width bottom sheet instead of a
/// centered dialog for long list pickers (better thumb reach and scanability).
const double kPickerBottomSheetBreakpoint = 600;

bool usePickerBottomSheet(BuildContext context) {
  return MediaQuery.sizeOf(context).width < kPickerBottomSheetBreakpoint;
}

/// List-style picker: [AlertDialog] on wide screens, modal bottom sheet on
/// narrow screens. [buildScrollableBody] is placed inside a [SingleChildScrollView].
///
/// [buildActions] receives the route [BuildContext] to pass to [Navigator.pop].
Future<T?> showPickerAdaptive<T>({
  required BuildContext context,
  required Widget title,
  required Widget Function(BuildContext innerContext, StateSetter setState)
      buildScrollableBody,
  required List<Widget> Function(
    BuildContext routeContext,
    StateSetter setState,
  ) buildActions,
}) {
  if (!context.mounted) {
    return Future<T?>.value(null);
  }
  if (!usePickerBottomSheet(context)) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (routeContext) {
        return StatefulBuilder(
          builder: (innerContext, setState) {
            final screenW = MediaQuery.sizeOf(innerContext).width;
            final contentWidth = (screenW - 48).clamp(280.0, 560.0);
            return withPickerDialogChrome(
              context,
              AlertDialog(
                title: title,
                content: SizedBox(
                  width: contentWidth,
                  child: SingleChildScrollView(
                    child: buildScrollableBody(innerContext, setState),
                  ),
                ),
                actions: buildActions(routeContext, setState),
              ),
            );
          },
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (routeContext) {
      return StatefulBuilder(
        builder: (innerContext, setState) {
          final mq = MediaQuery.of(innerContext);
          final maxH = mq.size.height * 0.92;
          final titleStyle =
              Theme.of(innerContext).dialogTheme.titleTextStyle ??
              Theme.of(innerContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  );
          return withPickerDialogChrome(
            context,
            Padding(
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: SizedBox(
                height: maxH,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: DefaultTextStyle.merge(
                        style: titleStyle,
                        child: title,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: buildScrollableBody(innerContext, setState),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: buildActions(routeContext, setState),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
