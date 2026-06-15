# Documents Library Reframe — Design

**Date:** 2026-06-15
**Status:** Approved (pending spec review)

## Goal

Reframe the repo from a *skill guide library* into a broader **Documents Library**.
It still hosts tutorials, but also informational documents, game rules, and
business/project plans. The change is conceptual + data-model + copy; the visual
theme is untouched.

## Background (current state)

- Static site on GitHub Pages: `index.html` (the hub) renders cards from
  `modules.js`; content lives in `skills/<name>/`.
- Vocabulary is skill/learning-centric: folder `skills/`, masthead copy
  ("teaching myself", "Creation Library"), an "Add a skill" card, and a footer
  explaining the skill workflow.
- Each `modules.js` entry has: `title`, `blurb`, `category`, `code`, `tags`,
  `status` (`solid`/`learning`/`planned`), `href`, `steps`, `progress`.
- `category` drives both the filter buttons and the call-number prefix.
- `tooling/modules-editor.ahk` is an AutoHotkey v2 GUI that reads/writes
  `modules.js`.

## Decisions

1. **`type` is a new first-class field**, separate from `category`. It is the
   primary classification axis. Initial values: `Tutorial`, `Info`, `Rules`,
   `Plan`. The set is open — new types can be added just by using them in data.
2. **`category` is retained as topic metadata** (e.g. `3D`, `Health`) but no
   longer drives filters or call-numbers. It is shown only as a tag/chip.
3. **Status & progress degrade gracefully.** `status` becomes optional; the
   progress bar and "N steps" render only when their fields are present. Non-
   tutorial docs therefore show clean (type badge, title, blurb, topic tags),
   no empty bar.
4. **Content folder renamed `skills/` → `library/`, kept flat** (`library/<name>/`).
   The `type` field is the single source of truth for classification — no
   per-type subdirectories.
5. **Placeholders removed.** The 2 "planned" placeholder entries are deleted.
   The hub will show the 2 real tutorials + the "Add" card; the filter bar shows
   only the types that actually exist in the data.
6. **AHK editor updated** in the same pass so it keeps producing valid entries.

## Data model (`modules.js`)

Entry shape after the change:

```js
{
  title:    "…",                 // required
  blurb:    "…",                 // required
  type:     "Tutorial",          // required — Tutorial | Info | Rules | Plan | …
  category: "3D",                // optional — topic; shown as a tag only
  code:     "TUT",               // optional — call-no prefix; default derived from type
  tags:     ["…"],               // optional — chips
  status:   "learning",          // optional — solid | learning | planned
  href:     "library/<name>/…",  // optional — omit for a not-yet-written doc
  steps:    10,                  // optional — tutorials only
  progress: 8                    // optional — 0–100, tutorials only
}
```

The template comment block at the top of `modules.js` is rewritten to document
`type` first and mark `steps`/`progress` as tutorial-only.

### Call-number derivation

- Prefix derives from **`type`** (not category). Default map:
  `Tutorial→TUT`, `Info→INF`, `Rules→RUL`, `Plan→PLN`.
- Fallback for an unmapped type: first 3 chars of the type, uppercased
  (same algorithm currently applied to `category`).
- Still overridable per-entry via `code`.
- Numbering increments **per type**, e.g. `TUT · 01`, `TUT · 02`, `RUL · 01`.

## Hub rendering (`index.html`)

- **Filter bar** is generated from distinct `type` values (in order of
  appearance): `All` + one button per type present. Same auto-generation and
  filtering logic as today, re-keyed from `category` to `type` (the per-card
  `data-cat` attribute becomes `data-type`, or equivalent).
- **Card body:**
  - call-number uses the type-derived prefix.
  - status badge renders only when `status` is set.
  - progress bar renders only when `progress` is set.
  - footer "N steps" renders only when `steps` is set; otherwise the footer
    shows the open affordance (active) or "Not started" (inactive) without a
    fabricated step count.
  - topic `category` (if present) is included among the tag chips.
- **Active/clickable** rule unchanged: a card is active when it has an `href`.
- **Copy changes:**
  - `<title>` and masthead heading → documents-library framing (drop "teaching
    myself" / "Creation Library" skill language).
  - masthead sub-paragraph describes a mixed library (tutorials, info, rules,
    plans).
  - "Add a skill" template card → "Add a document", pointing at
    `library/<name>/` and the `modules.js` template.
  - footer "How this library works" text updated for `library/` + `type`.

## Seed data

Two entries, both `type: "Tutorial"`, `href` repointed to `library/…`:

- Rigging & Animation in Blender 5.1 (`category: "3D"`)
- Pelvic Floor Training (`category: "Health"`)

No placeholder entries.

## File moves

- `skills/blender-rigging/` → `library/blender-rigging/`
  (note: this folder may not yet contain its `index.html`; move whatever exists)
- `skills/pelvic-floor-training/` → `library/pelvic-floor-training/`
- All `href` values in `modules.js` updated to the new paths.
- README structure/instructions updated to `library/` and the `type` field.

## Tooling (`tooling/modules-editor.ahk`)

- Add a **`type`** input (dropdown/combo with the four seed types, free-text
  allowed for new types).
- Update field labels/help to match the new schema and mark `steps`/`progress`
  as tutorial-only.
- Ensure the serializer writes the `type` field into each `modules.js` entry.

## Out of scope

- No subdirectories by document type (flat `library/`).
- No change to the visual theme, colors, or fonts.
- No edits to the content of the guide HTML files themselves.

## Success criteria

- `index.html` opens with no console errors; filter bar shows `All` + `Tutorial`
  only (the types present); both tutorial cards render with progress bars and
  step counts.
- A hand-added `Info`/`Rules`/`Plan` entry with no `steps`/`progress`/`status`
  renders cleanly (no empty bar, correct call-number prefix, appears under its
  type filter).
- No references to the old `skills/` path remain in `index.html`, `modules.js`,
  or `README.md`.
- The AHK editor can create an entry with a `type` and the result is valid
  `modules.js`.
