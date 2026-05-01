import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';
import 'die_silhouette_painter.dart';

/// Fallback dice when [RuleForm.dice] is empty (e.g. tests); matches printed form cards.
const Map<String, List<int>> kFormDicePoolByFormId = {
  'form_blaster': [8, 8, 8],
  'form_control': [10, 8, 6, 4],
  'form_dance': [10, 8, 6],
  'form_iron': [8, 6, 6],
  'form_one_two': [6, 6, 4, 4],
  'form_power': [10, 10, 4],
  'form_reversal': [8, 8, 6, 4],
  'form_shadow': [4, 4, 4, 4, 4, 4],
  'form_song': [8, 6, 6, 4],
  'form_vigilance': [6, 6, 6, 6],
  'form_wild': [10, 6, 6],
  'form_zen': [7, 5, 3, 1],
};

/// Raster dice icons under `assets/icons/dice/` (optional branding); stance UI paints vectors instead.
const List<String> kBundledDiceIconAssetPaths = [
  'assets/icons/dice/d4.png',
  'assets/icons/dice/d6.png',
  'assets/icons/dice/d8.png',
  'assets/icons/dice/d10.png',
];

/// PNG asset path when present (legacy / tooling); UI uses [formDieChip] painter paths.
String? dieIconAssetPathForSides(int sides) {
  switch (sides) {
    case 4:
      return 'assets/icons/dice/d4.png';
    case 6:
      return 'assets/icons/dice/d6.png';
    case 8:
      return 'assets/icons/dice/d8.png';
    case 10:
      return 'assets/icons/dice/d10.png';
    default:
      return null;
  }
}

/// Nearest bundled die family (4 / 6 / 8 / 10) used as silhouette for non-standard face counts.
int canonicalDiceSidesForProxy(int sides) {
  if (sides <= 4) return 4;
  if (sides <= 6) return 6;
  if (sides <= 8) return 8;
  return 10;
}

List<int> formDicePoolForFormId(String formId) =>
    kFormDicePoolByFormId[formId] ?? const [];

/// Prefer dice from merged rules; fall back to [kFormDicePoolByFormId] by form id.
List<int> formDicePoolForForm(RuleForm? form) {
  if (form != null && form.dice.isNotEmpty) return form.dice;
  final id = form?.id;
  if (id != null && kFormDicePoolByFormId.containsKey(id)) {
    return kFormDicePoolByFormId[id]!;
  }
  return const [];
}

/// Stance-sheet die: painted silhouette for d4/d6/d8/d10 families; odd sizes use nearest shape + label.
Widget formDieChip(int sides, {double size = 44}) {
  final silhouette = ({4, 6, 8, 10}.contains(sides))
      ? sides
      : canonicalDiceSidesForProxy(sides);
  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: DieSilhouettePainter(
        silhouetteSides: silhouette,
        label: '$sides',
      ),
    ),
  );
}
