# Panic at the Dojo — Character Builder (PWA) *(unofficial)*

**Unofficial** fan-made tool: not affiliated with or endorsed by the game's publisher or rights holders.

Flutter Web PWA for **Panic at the Dojo 1st Edition** character creation: guided wizards, offline storage for multiple characters, JSON import/export, printable sheets (PDF via `printing`), and GitHub Pages deployment.

## Features

- **Home**: create new character, import JSON, or open characters cached on this device.
- **Creation wizard**: Hero Type → Build → Archetypes → 3 Stances (style, form, printed name) → Skills (one optional swap + two-word skill) → Review & save.
- **Character sheet**: edit identity fields, calculated stats from build, **Super** placeholder (patch) until XP advancement exists.
- **Print / PDF**: half-letter style layout (4 units: character + 3 stances) via **Print** screen.
- **Rules data**: `assets/data/rules.json`. Form rulebook skills sync from `Cards/html/cards_skills.html` via `dart run tool/sync_form_skills_from_cards_html.dart`. Extract-backed style stance skills merge into `rules.json` via `dart run tool/generate_style_skills.dart`.

## Local development

```bash
flutter pub get
flutter run -d chrome
```

Run tests:

```bash
flutter analyze
flutter test
```

## GitHub Pages

1. Repo **Settings → Pages**: set **Source** to **GitHub Actions**.
2. Push to `main` (or `master`). Workflow: [.github/workflows/deploy-gh-pages.yml](.github/workflows/deploy-gh-pages.yml).
3. Build uses `--base-href "/<repository-name>/"` so the app resolves assets under your project Pages URL.

If your repository name changes, update the `--base-href` in the workflow (or pass the correct name).

## Source material

Rule PDFs live under `Source Material/` (not committed to rules JSON automatically). Replace placeholder text in `assets/data/rules.json` with verbatim book + patch passages as you transcribe them.

## License

Game rules and art remain the property of their respective rights holders. This repository contains app code and **seed** JSON placeholders; replace seed text with your own legally obtained excerpts for public distribution.
