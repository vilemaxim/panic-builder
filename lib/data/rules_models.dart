/// Typed view over merged rules JSON (Panic at the Dojo 1e + patch).
library;

/// Removes U+000D from exported / pasted rulebook strings so UI text is clean.
String stripRuleTextCarriageReturns(String text) => text.replaceAll('\r', '');

class RuleHeroType {
  const RuleHeroType({
    required this.id,
    required this.name,
    required this.description,
    required this.restrictions,
    required this.archetypeSlots,
  });

  final String id;
  final String name;
  final String description;
  final String restrictions;
  final int archetypeSlots;

  static RuleHeroType fromJson(Map<String, dynamic> j) => RuleHeroType(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    restrictions: j['restrictions'] as String? ?? '',
    archetypeSlots: j['archetypeSlots'] as int? ?? 1,
  );
}

class RuleBuild {
  const RuleBuild({
    required this.id,
    required this.name,
    required this.description,
    required this.maxHp,
    required this.hpBars,
    required this.totalBars,
  });

  final String id;
  final String name;
  final String description;
  final int maxHp;
  final int hpBars;
  final int totalBars;

  static RuleBuild fromJson(Map<String, dynamic> j) => RuleBuild(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    maxHp: j['maxHp'] as int? ?? 0,
    hpBars: j['hpBars'] as int? ?? 0,
    totalBars: j['totalBars'] as int? ?? 0,
  );
}

class RuleArchetype {
  const RuleArchetype({
    required this.id,
    required this.name,
    required this.description,
    required this.abilitiesSummary,
    required this.complexity,
    this.abilitiesByHeroType = const {},
  });

  final String id;
  final String name;
  final String description;
  final String abilitiesSummary;
  final int complexity;

  /// Focused / fused / frantic archetype rules quoted from the rulebook (`focused`, `fused`, `frantic`).
  final Map<String, String> abilitiesByHeroType;

  static RuleArchetype fromJson(Map<String, dynamic> j) {
    Map<String, String> heroAbilities = const {};
    final rawHero = j['abilitiesByHeroType'];
    if (rawHero is Map) {
      heroAbilities = rawHero.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
    }
    return RuleArchetype(
      id: j['id'] as String,
      name: j['name'] as String,
      description: j['description'] as String? ?? '',
      abilitiesSummary: j['abilitiesSummary'] as String? ?? '',
      complexity: j['complexity'] as int? ?? 1,
      abilitiesByHeroType: heroAbilities,
    );
  }
}

class RuleStyle {
  const RuleStyle({
    required this.id,
    required this.archetypeId,
    required this.name,
    required this.basicInfo,
    this.description = '',
    this.range = '',
    this.passive = '',
    this.actions = const [],
    this.marginNotes = '',
    this.sourceBook = '',
    this.sourcePage = '',
    this.skillId,
  });

  final String id;
  final String archetypeId;
  final String name;

  /// Short rulebook-facing summary (often the “{Style} is …” paragraph).
  final String description;

  /// Stance range from the printed style card (e.g. `1-2`, `1`).
  final String range;

  /// Passive ability block from the style card.
  final String passive;

  /// Tiered style actions from the card (heading + body each).
  final List<RuleFormAction> actions;

  final String basicInfo;
  final String marginNotes;
  final String sourceBook;
  final String sourcePage;

  /// RuleSkill id for this style's stance rules (tiered action name + full body).
  final String? skillId;

  static RuleStyle fromJson(Map<String, dynamic> j) => RuleStyle(
        id: j['id'] as String,
        archetypeId: j['archetypeId'] as String,
        name: stripRuleTextCarriageReturns(j['name'] as String? ?? ''),
        description:
            stripRuleTextCarriageReturns(j['description'] as String? ?? ''),
        range: stripRuleTextCarriageReturns(j['range'] as String? ?? ''),
        passive: stripRuleTextCarriageReturns(j['passive'] as String? ?? ''),
        actions: ruleFormActionsFromJson(j['actions']),
        basicInfo:
            stripRuleTextCarriageReturns(j['basicInfo'] as String? ?? ''),
        marginNotes:
            stripRuleTextCarriageReturns(j['marginNotes'] as String? ?? ''),
        sourceBook: j['sourceBook'] as String? ?? '',
        sourcePage: j['sourcePage']?.toString() ?? '',
        skillId: j['skillId'] as String?,
      );
}

class RuleFormAction {
  const RuleFormAction({
    required this.heading,
    required this.description,
  });

  /// Printed tier line, e.g. `3+: Amplify` or `3+ or 6+: Shockwave`.
  final String heading;

  /// Rule text below the heading on the form card.
  final String description;

  static RuleFormAction fromJson(Map<String, dynamic> j) => RuleFormAction(
        heading:
            stripRuleTextCarriageReturns(j['heading'] as String? ?? ''),
        description:
            stripRuleTextCarriageReturns(j['description'] as String? ?? ''),
      );
}

List<RuleFormAction> ruleFormActionsFromJson(dynamic raw) {
  final out = <RuleFormAction>[];
  if (raw is! List<dynamic>) return out;
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(RuleFormAction.fromJson(e));
    }
  }
  return out;
}

/// A fixed rules option the player picks when this form is paired with a style
/// (e.g. Control Form range modes). [minRange]/[maxRange] are additive deltas;
/// [absoluteMin]/[absoluteMax] override the parsed bound after deltas when set.
class RuleFormChoice {
  const RuleFormChoice({
    required this.id,
    required this.text,
    this.helpText,
    this.minRange,
    this.maxRange,
    this.absoluteMin,
    this.absoluteMax,
  });

  final String id;
  final String text;

  /// Full rulebook wording (dialog + Frantic stance sheet). Omitted when [text]
  /// alone is enough.
  final String? helpText;
  final int? minRange;
  final int? maxRange;
  final int? absoluteMin;
  final int? absoluteMax;

  static RuleFormChoice fromJson(Map<String, dynamic> j) => RuleFormChoice(
    id: j['id'] as String,
    text: stripRuleTextCarriageReturns(j['text'] as String? ?? ''),
    helpText: j['helpText'] != null
        ? stripRuleTextCarriageReturns(j['helpText'] as String)
        : null,
    minRange: (j['minRange'] as num?)?.toInt(),
    maxRange: (j['maxRange'] as num?)?.toInt(),
    absoluteMin: (j['absoluteMin'] as num?)?.toInt(),
    absoluteMax: (j['absoluteMax'] as num?)?.toInt(),
  );
}

List<RuleFormChoice> ruleFormChoicesFromJson(dynamic raw) {
  if (raw is! List<dynamic>) return const [];
  final out = <RuleFormChoice>[];
  for (final e in raw) {
    if (e is Map<String, dynamic>) {
      out.add(RuleFormChoice.fromJson(e));
    }
  }
  return out;
}

class RuleForm {
  const RuleForm({
    required this.id,
    required this.name,
    required this.altNames,
    required this.skillIds,
    this.description = '',
    this.passive = '',
    this.dice = const [],
    this.actions = const [],
    this.sourceBook = '',
    this.sourcePage = '',
    this.minRange,
    this.maxRange,
    this.choices = const [],
  });

  final String id;
  final String name;

  /// Rulebook summary for pickers/tooltips (kept in sync with [passive] when sourced from cards).
  final String description;

  /// Passive ability block under Action Dice on the form card.
  final String passive;

  /// Action dice shown on the form card (e.g. Blaster Form → 8, 8, 8).
  final List<int> dice;

  /// Tiered form actions from the card (heading + body each).
  final List<RuleFormAction> actions;

  final List<String> altNames;

  /// Skill ids from this form (rulebook skill id(s); padded by policies if fewer than three slots).
  final List<String> skillIds;
  final String sourceBook;
  final String sourcePage;

  /// Optional **delta** added to the style’s parsed minimum range (stance line).
  /// Omitted when the form does not change printed range numbers.
  final int? minRange;

  /// Optional **delta** added to the style’s parsed maximum range (stance line).
  final int? maxRange;

  /// Rulebook options the player must pick when using this form on a stance
  /// (see [RuleFormChoice]). When non-empty, [minRange]/[maxRange] on the form
  /// itself are ignored in favor of the selected choice’s numbers.
  final List<RuleFormChoice> choices;

  static RuleForm fromJson(Map<String, dynamic> j) {
    final diceRaw = j['dice'];
    final dice = <int>[];
    if (diceRaw is List<dynamic>) {
      for (final e in diceRaw) {
        if (e is int) {
          dice.add(e);
        } else if (e is num) {
          dice.add(e.toInt());
        }
      }
    }
    final actions = ruleFormActionsFromJson(j['actions']);
    final passive =
        stripRuleTextCarriageReturns(j['passive'] as String? ?? '');
    return RuleForm(
      id: j['id'] as String,
      name: j['name'] as String,
      altNames: (j['altNames'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      skillIds: (j['skillIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      description:
          stripRuleTextCarriageReturns(j['description'] as String? ?? ''),
      passive: passive,
      dice: dice,
      actions: actions,
      sourceBook: j['sourceBook'] as String? ?? '',
      sourcePage: j['sourcePage']?.toString() ?? '',
      minRange: (j['minRange'] as num?)?.toInt(),
      maxRange: (j['maxRange'] as num?)?.toInt(),
      choices: ruleFormChoicesFromJson(j['choices']),
    );
  }
}

class RuleSkill {
  const RuleSkill({
    required this.id,
    required this.name,
    required this.description,
    this.associatedFormId,
    this.playerNoteMaxChars,
  });

  final String id;
  final String name;
  final String description;

  /// Form id when this skill is the rulebook skill granted by that form (e.g. form_blaster).
  final String? associatedFormId;

  /// When set (e.g. 30), the sheet asks for a short free-text note after this skill
  /// appears on the character (rules-driven; see rules JSON).
  final int? playerNoteMaxChars;

  static RuleSkill fromJson(Map<String, dynamic> j) => RuleSkill(
    id: j['id'] as String,
    name: stripRuleTextCarriageReturns(j['name'] as String? ?? ''),
    description: stripRuleTextCarriageReturns(j['description'] as String? ?? ''),
    associatedFormId: j['associatedForm'] as String? ??
        j['associatedFormId'] as String?,
    playerNoteMaxChars: (j['playerNoteMaxChars'] as num?)?.toInt(),
  );
}

/// Printable sheet chrome strings (hero-type blurbs not tied to a single archetype object).
class RuleSheetPresentation {
  const RuleSheetPresentation({
    required this.franticHeroStanceRules,
    required this.franticAbilityIntroTemplate,
  });

  final String franticHeroStanceRules;

  /// `{name}` → character display name for frantic ability lists.
  final String franticAbilityIntroTemplate;

  static RuleSheetPresentation fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) {
      return const RuleSheetPresentation(
        franticHeroStanceRules: '',
        franticAbilityIntroTemplate: "{name}'s Frantic Abilities are:",
      );
    }
    return RuleSheetPresentation(
      franticHeroStanceRules: j['franticHeroStanceRules'] as String? ?? '',
      franticAbilityIntroTemplate:
          j['franticAbilityIntroTemplate'] as String? ??
          "{name}'s Frantic Abilities are:",
    );
  }

  /// Substitutes `{name}` in [franticAbilityIntroTemplate] using [characterDisplayName].
  String franticAbilityIntroLine(String characterDisplayName) {
    final name = characterDisplayName.trim().isEmpty
        ? 'Hero'
        : characterDisplayName.trim();
    return franticAbilityIntroTemplate.replaceAll('{name}', name);
  }
}

class RuleSuper {
  const RuleSuper({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceBook,
    required this.sourcePage,
  });

  final String id;
  final String name;
  final String description;
  final String sourceBook;
  final String sourcePage;

  static RuleSuper fromJson(Map<String, dynamic> j) => RuleSuper(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    sourceBook: j['sourceBook'] as String? ?? 'Patch',
    sourcePage: j['sourcePage']?.toString() ?? '',
  );
}

class MergedRules {
  MergedRules({
    required this.version,
    required this.heroTypes,
    required this.builds,
    required this.archetypes,
    required this.styles,
    required this.forms,
    required this.skills,
    required this.supers,
    this.sheetPresentation = const RuleSheetPresentation(
      franticHeroStanceRules: '',
      franticAbilityIntroTemplate: "{name}'s Frantic Abilities are:",
    ),
  });

  final int version;
  final List<RuleHeroType> heroTypes;
  final List<RuleBuild> builds;
  final List<RuleArchetype> archetypes;
  final List<RuleStyle> styles;
  final List<RuleForm> forms;
  final List<RuleSkill> skills;
  final List<RuleSuper> supers;
  final RuleSheetPresentation sheetPresentation;

  static MergedRules fromJson(Map<String, dynamic> root) {
    List<T> mapList<T>(String key, T Function(Map<String, dynamic>) f) {
      final raw = root[key] as List<dynamic>? ?? [];
      return raw.map((e) => f((e as Map).cast<String, dynamic>())).toList();
    }

    final sheetRaw = root['sheetPresentation'];
    Map<String, dynamic>? sheetMap;
    if (sheetRaw is Map<String, dynamic>) {
      sheetMap = sheetRaw;
    } else if (sheetRaw is Map) {
      sheetMap = Map<String, dynamic>.from(sheetRaw);
    }

    return MergedRules(
      version: root['version'] as int? ?? 1,
      heroTypes: mapList('heroTypes', RuleHeroType.fromJson),
      builds: mapList('builds', RuleBuild.fromJson),
      archetypes: mapList('archetypes', RuleArchetype.fromJson),
      styles: mapList('styles', RuleStyle.fromJson),
      forms: mapList('forms', RuleForm.fromJson),
      skills: mapList('skills', RuleSkill.fromJson),
      supers: mapList('supers', RuleSuper.fromJson),
      sheetPresentation: RuleSheetPresentation.fromJson(sheetMap),
    );
  }

  RuleHeroType? heroTypeById(String? id) {
    if (id == null) return null;
    for (final h in heroTypes) {
      if (h.id == id) return h;
    }
    return null;
  }

  RuleBuild? buildById(String? id) {
    if (id == null) return null;
    for (final b in builds) {
      if (b.id == id) return b;
    }
    return null;
  }

  RuleArchetype? archetypeById(String? id) {
    if (id == null) return null;
    for (final a in archetypes) {
      if (a.id == id) return a;
    }
    return null;
  }

  RuleStyle? styleById(String? id) {
    if (id == null) return null;
    for (final s in styles) {
      if (s.id == id) return s;
    }
    return null;
  }

  RuleForm? formById(String? id) {
    if (id == null) return null;
    for (final f in forms) {
      if (f.id == id) return f;
    }
    return null;
  }

  RuleSkill? skillById(String? id) {
    if (id == null) return null;
    for (final s in skills) {
      if (s.id == id) return s;
    }
    return null;
  }

  RuleSuper? superById(String? id) {
    if (id == null) return null;
    for (final s in supers) {
      if (s.id == id) return s;
    }
    return null;
  }

  Iterable<RuleStyle> stylesForArchetype(String archetypeId) =>
      styles.where((s) => s.archetypeId == archetypeId);
}
