import 'package:flutter/material.dart';

import '../../../data/rules_models.dart';

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

/// Raster dice icons under `assets/icons/dice/` (used by [formDieChip] on form / stance cards).
const List<String> kBundledDiceIconAssetPaths = [
  'assets/icons/dice/d4.png',
  'assets/icons/dice/d6.png',
  'assets/icons/dice/d8.png',
  'assets/icons/dice/d10.png',
];

/// Nearest bundled die family (4 / 6 / 8 / 10) used as silhouette for non-standard face counts.
int canonicalDiceSidesForProxy(int sides) {
  if (sides <= 4) return 4;
  if (sides <= 6) return 6;
  if (sides <= 8) return 8;
  return 10;
}

/// Prefer dice from merged rules; fall back to [kFormDicePoolByFormId] by form id.
List<int> formDicePoolForForm(RuleForm? form) {
  if (form != null && form.dice.isNotEmpty) return form.dice;
  final id = form?.id;
  if (id != null && kFormDicePoolByFormId.containsKey(id)) {
    return kFormDicePoolByFormId[id]!;
  }
  return const [];
}

/// Asset path for the bundled d4 / d6 / d8 / d10 icon matching [sides] (must be 4, 6, 8, or 10).
String bundledDiceIconAsset(int sides) {
  assert({4, 6, 8, 10}.contains(sides), 'bundled icons only cover d4–d10');
  return 'assets/icons/dice/d$sides.png';
}

/// Stance / form die: [assets/icons/dice] PNG; odd face counts use the nearest shape and show [sides] on top.
Widget formDieChip(int sides, {double size = 44}) {
  final canonical = ({4, 6, 8, 10}.contains(sides))
      ? sides
      : canonicalDiceSidesForProxy(sides);
  final needsFaceLabel = sides != canonical;
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: Image.asset(
            bundledDiceIconAsset(canonical),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'd$sides',
          ),
        ),
        if (needsFaceLabel)
          Text(
            '$sides',
            style: TextStyle(
              color: const Color(0xE6000000),
              fontSize: size * (sides >= 10 ? 0.24 : 0.3),
              fontWeight: FontWeight.w800,
              height: 1,
              shadows: const [
                Shadow(color: Color(0xCCFFFFFF), blurRadius: 3),
                Shadow(color: Color(0x66FFFFFF), blurRadius: 1),
              ],
            ),
          ),
      ],
    ),
  );
}
