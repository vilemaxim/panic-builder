/// Font sizes for large rulebook ribbon titles (stance style + form row,
/// frantic form card title, range subtitle under those titles).
///
/// Breakpoints align with [RulebookCharacterSheetPanel] identity banner.
class RulebookRibbonHeaderTypography {
  const RulebookRibbonHeaderTypography({
    required this.titleFontSize,
    required this.rangeFontSize,
    required this.editIconSize,
  });

  final double titleFontSize;
  final double rangeFontSize;
  final double editIconSize;

  static RulebookRibbonHeaderTypography forWidth(double layoutWidth) {
    final w = layoutWidth;
    if (w >= 520) {
      return const RulebookRibbonHeaderTypography(
        titleFontSize: 36,
        rangeFontSize: 20,
        editIconSize: 24,
      );
    }
    if (w >= 440) {
      return const RulebookRibbonHeaderTypography(
        titleFontSize: 30,
        rangeFontSize: 17,
        editIconSize: 22,
      );
    }
    if (w >= 380) {
      return const RulebookRibbonHeaderTypography(
        titleFontSize: 26,
        rangeFontSize: 15,
        editIconSize: 20,
      );
    }
    return const RulebookRibbonHeaderTypography(
      titleFontSize: 22,
      rangeFontSize: 14,
      editIconSize: 18,
    );
  }
}
