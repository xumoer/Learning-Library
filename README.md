# Documents Library

A collection of self-contained HTML documents — tutorials, info packs, game rules, and plans. One folder per document, hosted on GitHub Pages.

## Structure

```
learning-library/
├── index.html                        ← hub page (renders shelves from modules.js)
├── modules.js                        ← AUTO-GENERATED — do not edit by hand
├── progress.js                       ← tracks reading progress in localStorage
├── .nojekyll                         ← tells GitHub Pages to serve files as-is
├── .github/
│   ├── workflows/build-modules.yml   ← GitHub Action that rebuilds modules.js
│   └── scripts/build-modules.js      ← scan script (reads <meta> tags)
└── library/
    ├── blender-rigging/
    │   └── index.html
    ├── pelvic-floor-training/
    │   └── pelvic-floor-training-guide.html
    ├── UDS-Rules/
    │   └── GAME_RULES_v5.html
    ├── business-plan/
    │   └── business-plan.html
    └── Godot4-2d-platformer/
        └── index.html
```

Each document lives in its own folder under `library/` (flat — no per-type subfolders). The hub groups them into shelves by their `type`.

## How it works

`modules.js` is **auto-generated** — you never edit it by hand. A GitHub Action scans every HTML file under `library/`, reads its `<meta>` tags, and rebuilds `modules.js` on every push to `main` that touches `library/`.

You can also trigger the rebuild manually from the Actions tab (`workflow_dispatch`).

## Add a new document

1. Create a folder: `library/your-doc-name/`
2. Add your HTML page with the required `<meta>` tags (see schema below)
3. Push to `main` — the Action rebuilds `modules.js` and the hub updates automatically

That's it. No manifest to edit, no config file to touch.

## Meta tag schema

Add these `<meta>` tags inside the `<head>` of your document's HTML file.

### Required

| Tag | Description | Example |
|-----|-------------|---------|
| `title` | Document title (plain text) | `Rigging & Animation in Blender 5.1` |
| `blurb` | One or two sentence summary | `Zero to animating a monster: armatures, weight painting…` |
| `type` | Shelf grouping — drives the shelf, filter button, and call-number prefix | `Tutorial` · `Info` · `Rules` · `Plan` (or any new type) |

### Optional

| Tag | Description | Example |
|-----|-------------|---------|
| `category` | Topic tag shown as a chip on the card | `3D` · `Health` · `Gamedev` |
| `code` | Override the auto-generated call-number prefix (default derived from type: Tutorial→TUT, Info→INF, Rules→RUL, Plan→PLN) | `RUL` |
| `tags` | Comma-separated extra tag chips | `rigging, animation, blender` |
| `status` | Color-coded badge | `solid` · `learning` · `planned` |
| `steps` | Number of steps/sections (shown as "N steps" on card) | `10` |
| `progress` | Default progress bar fill, 0–100 (live progress from localStorage overrides this) | `0` |

### Example

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Document Title</title>

  <!-- Library metadata — the hub reads these -->
  <meta name="title"    content="Your Document Title">
  <meta name="blurb"    content="A short description of what this document covers.">
  <meta name="type"     content="Tutorial">
  <meta name="category" content="Topic">
  <meta name="tags"     content="tag1, tag2, tag3">
  <meta name="status"   content="learning">
  <meta name="steps"    content="8">
  <meta name="progress" content="0">

  <!-- rest of your <head> -->
</head>
```

## Running the scan locally

You can preview what the Action will generate without pushing:

```bash
node .github/scripts/build-modules.js
```

This overwrites `modules.js` in place with the scanned result.
