/// Responsive type for the identity banner (character name + hero type line) and
/// the matching rulebook ribbons (stance style/form row + range subtitle, frantic
/// form title, edit affordances).
///
/// [titleFontSize] / [rangeFontSize] / [editIconSize] use the same breakpoints and
/// sizes as [RulebookCharacterSheetPanel] banner typography so those lines match
/// when stacked vertically on the sheet.
///
/// [actionRibbonTitleFontSize] matches skill / build / archetype orange–purple ribbon
/// labels ([RulebookCharacterSheetPanel] skill line).
///
/// [stanceWellBodyFontSize] matches secondary body copy on the character sheet (e.g.
/// archetype well, rules blurbs at 13.5).
class RulebookRibbonHeaderTypography {
  const RulebookRibbonHeaderTypography({
    required this.titleFontSize,
    required this.rangeFontSize,
    required this.editIconSize,
    required this.actionRibbonTitleFontSize,
    required this.stanceWellBodyFontSize,
  });

  /// Primary line: character name on the banner, or style + form names in stance.
  final double titleFontSize;

  /// Secondary line: hero type on the banner, or stance range / form metadata.
  final double rangeFontSize;

  /// Edit / affordance icon on tappable headers.
  final double editIconSize;

  /// Green (stance) or default sub-ribbon action titles — same class as skill pills.
  final double actionRibbonTitleFontSize;

  /// Passive paragraphs, action descriptions, margin notes in stance / form wells.
  final double stanceWellBodyFontSize;

  static RulebookRibbonHeaderTypography forWidth(double layoutWidth) {
    final w = layoutWidth;
    if (w >= 520) {
      return const RulebookRibbonHeaderTypography(
        titleFontSize: 28,
        rangeFontSize: 20,
        editIconSize: 22,
        actionRibbonTitleFontSize: 15,
        stanceWellBodyFontSize: 13.5,
      );
    }
    if (w >= 440) {
      return const RulebookRibbonHeaderTypography(
        titleFontSize: 23,
        rangeFontSize: 17,
        editIconSize: 21,
        actionRibbonTitleFontSize: 15,
        stanceWellBodyFontSize: 13.5,
      );
    }
    if (w >= 380) {
      return const RulebookRibbonHeaderTypography(
        titleFontSize: 20,
        rangeFontSize: 15,
        editIconSize: 20,
        actionRibbonTitleFontSize: 15,
        stanceWellBodyFontSize: 13.5,
      );
    }
    return const RulebookRibbonHeaderTypography(
      titleFontSize: 18,
      rangeFontSize: 14,
      editIconSize: 18,
      actionRibbonTitleFontSize: 15,
      stanceWellBodyFontSize: 13.5,
    );
  }
}
