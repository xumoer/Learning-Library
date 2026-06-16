# Documents Library

A collection of self-contained, work-through-it (and read-only) HTML documents — one folder per document. Hosted on GitHub Pages so embedded videos and external resources load over HTTPS and just work. Holds tutorials, info packs, game rules, and plans.

## Structure

```
documents-library/
├── index.html                      ← the hub / landing page (per-type shelves)
├── modules.js                      ← the data file the hub renders from
├── README.md
├── .nojekyll                       ← tells GitHub Pages to serve files as-is
└── library/
    └── blender-rigging/
        └── index.html              ← Rigging & Animation in Blender 5.1
```

Each document lives in its own folder under `library/` (flat — no per-type subfolders). The hub groups them into shelves by their `type`.

## Add a new document

1. Make a folder: `library/your-doc-name/` and put your page in it (e.g. `index.html`).
2. Add one entry to the `MODULES` array in `modules.js` — copy the `TEMPLATE` comment at the top of that file. Set at least `title`, `blurb`, and `type` (`Tutorial` / `Info` / `Rules` / `Plan` — or a new one), and point `href` at your page.
3. `type` drives the shelf, the filter button, and the call-number prefix automatically. `category` is an optional topic tag. `status`, `steps`, and `progress` are optional and mainly useful for tutorials.
4. Commit and push — it's live.

You can also edit `modules.js` with the GUI tool at `tooling/modules-editor.ahk` (AutoHotkey v2).
