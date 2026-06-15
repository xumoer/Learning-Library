# Data-driven Learning Library hub — design

**Date:** 2026-06-15
**Status:** Approved (design)

## Problem

Adding a new module to the hub (`index.html`) currently means hand-copying an
`<article class="card">` block and editing its title, blurb, call number, tags,
status, progress bar, and `href`. It is tedious and easy to get wrong (e.g.
forgetting to bump the call number or the ledger counts).

## Goal

Make adding a module a one-place edit: append a single object to a data file.
Everything else (cards, filter buttons, counts, call numbers) is derived
automatically. The site stays a pure static site — no build step, no server.

## Decisions (from brainstorming)

- **Approach:** data file + JS render (cards generated from data at page load).
- **Auto-derive everything:** filter buttons, ledger counts, and per-category
  call numbers all computed from the data.
- **Authoring:** hand-edit the data file for now. (An AHK GUI to write the file
  may come later as its own task — out of scope here.)
- **No skill-page scaffold/template** — the flow only handles the catalog entry.

## Key technical decision: `modules.js`, not `modules.json`

Use a JavaScript data file (`modules.js`) that assigns a global, loaded via
`<script src="modules.js">`, **instead of** a `.json` file loaded with
`fetch()`.

Reason: when `index.html` is opened directly from disk (`file://`) for a local
preview, browsers block `fetch()` of local files (CORS), so a JSON-fetch page
would render empty locally. A `<script src>` include has no such restriction and
works both locally (`file://`) and on GitHub Pages (`https://`). Editing the file
is materially identical to editing JSON.

```js
window.MODULES = [ /* …module objects… */ ];
```

## Files

- **`modules.js`** — the data. An array of module objects, preceded by a comment
  block documenting every field and a copy-paste template entry.
- **`index.html`** — unchanged look. The static card markup inside `#grid` is
  replaced by JS that builds cards from `window.MODULES`. All existing CSS is
  retained as-is. Filter row and ledger numbers become populated by JS.

## Module schema

```js
{
  title:    "Rigging & Animation in Blender 5.1",  // required, plain text
  blurb:    "Zero to animating a monster: armatures…", // required
  category: "3D",            // required; drives filter button + call-no prefix
  code:     "3D",            // optional; call-no prefix. Default: category
                             //   uppercased, first 3 chars (e.g. "Music"→"MUS")
  tags:     ["3D","rigging","animation","blender"], // optional; chips on card
  status:   "learning",      // required; one of: solid | learning | planned
  href:     "skills/blender-rigging/index.html",    // optional (see below)
  steps:    10,              // optional; shown in footer ("10 steps")
  progress: 8                // optional; 0–100; progress-bar fill width %
}
```

### Field semantics

- **`href` present** → card is "active": clickable, keyboard-activatable
  (Enter/Space), hover lift, shows progress bar, "N steps", and "Open module ↗".
- **`href` absent OR `status:"planned"`** → placeholder: dashed border, dimmed,
  shows "Not started" / "—", not clickable.
- **`status`** sets the badge color/label via existing CSS classes
  (`solid` green, `learning` amber, `planned` gray).

## Auto-derived behavior

- **Filter buttons:** "All" first (pressed by default), then one button per
  distinct `category` value in order of first appearance in the data. Clicking
  filters cards by category (same interaction as today). The dashed "Add a skill"
  template card is always visible regardless of filter.
- **Call numbers:** `"<CODE> · <NN>"` where `CODE` = `code` or default, and `NN`
  is a zero-padded counter that increments per category by array order
  (`3D · 01`, `3D · 02`, `MUS · 01`, …).
- **Ledger counts:** *active* = count of modules with `status` ≠ `planned`;
  *modules listed* = total module count. "updated <year>" stays computed from the
  current date as it is today.

## Retained as-is

- Dark theme and all CSS.
- Tag/category filter interaction and the empty-state message.
- Keyboard activation of active cards.
- The dashed "Add a skill" template card at the end of the grid.
- The footer "How this library works" section — copy tweaked to say *add an
  entry to `modules.js`* instead of *duplicate a card*.

## Migration

The current four cards (Blender = learning/active; FL Studio, AutoHotkey,
Futures = planned) become the seed entries in `modules.js`, with `code` values
set to match the existing prefixes (`3D`, `MUS`, `DEV`, `TRD`). After the change
the rendered page is visually identical to today.

## Out of scope

- Skill-page scaffold/template.
- AHK GUI or any input helper (possible later task).
- Any change to individual skill pages under `skills/`.

## Success criteria

- Opening `index.html` locally (`file://`) and on GitHub Pages renders all four
  seed cards identically to the current page.
- Adding a new module = appending one object to `modules.js`; a new card, its
  call number, its filter button (if a new category), and the ledger counts all
  appear with no other edits.
- Active cards link and are keyboard-activatable; placeholders are dashed and
  inert. Tag filtering still works.
