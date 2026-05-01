# XP Advancement — Design Spike (Post-MVP)

Character JSON already reserves:

- `xpEarned`, `xpSpent`, `advancements[]`, and optional `super` (`SuperUnlock`).

This note captures implementation options **after** the creation MVP is stable.

## Goals

- Let players record XP earned in play and spend it on allowed upgrades.
- First concrete unlock: **Super** (patch), tied to `rules.supers` entries and full text in the sheet/PDF.

## Option A — Ledger-first (recommended)

- **UI**: “Advancement” screen on a saved character: buttons “+1 XP”, “+3 XP”, custom add; list of **purchased** upgrades with undo (same session) optional.
- **Model**: append-only `advancements[]` with `{ kind, costXp, at, note?, payload? }`; derive effective character by replaying ledger on load (or cache denormalized fields on `Character`).
- **Pros**: Auditable, export-friendly, easy to migrate when rules change.
- **Cons**: Slightly more code to “replay” or keep in sync.

## Option B — Direct mutation

- **UI**: pick upgrade → immediately write new fields on `Character` (e.g. set `super`, bump a stat).
- **Pros**: Simplest code path.
- **Cons**: Harder to audit; undo/history is manual.

## Option C — Hybrid

- Store **both** a ledger (`advancements`) **and** denormalized fields (`superUnlock`, future perks) updated transactionally when spending XP.

## Super unlock flow (sketch)

1. Load `MergedRules.supers` (merged patch).
2. Show list with costs if/when the patch defines costs; otherwise use a placeholder cost table in JSON until transcribed.
3. On purchase: append `Advancement(kind: gainSuper, costXp: N, ...)` and set `superUnlock`.
4. Sheet/PDF: replace locked placeholder with full Super block.

## Open questions to resolve from the patch PDF

- Exact XP economy (earn rates, caps, refund rules).
- Whether multiple Supers exist per character or exclusivity.
- Other XP sinks (new skills, stance tweaks, stat bumps) and their stacking rules.

When those are answered, encode them as small policy modules + tests (same style as `CharacterPolicies`).
