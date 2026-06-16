# Modules Editor — File-First Add & Button Relayout — Design

**Date:** 2026-06-15
**Status:** Approved (pending spec review)
**Component:** `tooling/modules-editor.ahk` (AutoHotkey v2 GUI)

## Goal

Make adding a new document a "pick the HTML file, get a head start" flow instead
of typing every field by hand. Picking a file derives the `href` from the file's
location (no typos), copies the file into `library/` on save, and prefills
`title`/`blurb` by parsing the HTML. The user can still edit every field. Also
relayout the buttons: Add New top-left, Save + Reload top-right, and
Delete/Move Up/Move Down under the ListView.

## Background

- The editor reads/writes `modules.js`. `modules.js` lives at `A_ScriptDir "\..\modules.js"`;
  the repo root is `A_ScriptDir "\.."` and the content dir is `<repo>\library\`.
- `href` values in `modules.js` are repo-root-relative with forward slashes,
  e.g. `library/blender-rigging/index.html`.
- Today, `AddNew()` creates a blank module and `href` is a free-text Edit field.
- Modules are normalised into AHK `Map`s keyed by the `Fields` array; the
  serializer emits only keys in `Fields`, so any extra Map key is ignored on save.

## Part A — File-First Add workflow

### Add New behavior
`Add New` opens an HTML file picker (`FileSelect`, filter `HTML (*.html;*.htm)`,
starting in `<repo>\library`).
- **File chosen:** create a new entry, prefilled (see below), select it, focus Title.
- **Picker cancelled:** fall back to today's behavior — a blank entry
  (`NewModule()`) the user fills in by hand (supports planned/placeholder docs
  with no file yet).

### Destination & href derivation
When a file is chosen, compute where it belongs:

1. **Slug** = slugify the file's base name (filename without extension):
   lowercase; spaces and underscores → `-`; drop any char that isn't
   `a–z`, `0–9`, or `-`; collapse repeated `-`; trim leading/trailing `-`.
   If the result is empty, slug = `doc`.
2. **Already inside `library/`?** If the picked file's absolute path is under
   `<repo>\library\`, do NOT copy. Set `href` = the existing path relative to
   the repo root, using forward slashes (e.g. `library/foo/bar.html`). No source
   stashed.
3. **Outside `library/`:** stash the picked absolute path as transient state
   (see below). Set `href` = `library/<slug>/<original-filename>` (filename kept
   verbatim, including spaces/caps — these become `%20` etc. in the URL; cosmetic
   only). The actual copy happens on Save.

### HTML parsing (best-effort, never blocks)
Read the picked file as UTF-8 and parse:
- **Title:** first `<title>…</title>` (case-insensitive, dot-matches-newline).
  Trim whitespace; decode the common entities `&amp; &lt; &gt; &quot; &#39;`.
  If absent, fall back to the filename without extension.
- **Blurb:** `<meta name="description" content="…">` (case-insensitive; tolerate
  attribute order, single or double quotes). Decode the same entities. If absent,
  leave blurb blank.
- `type` defaults to `Tutorial` (as today via `NewModule`); `status` defaults to
  `learning`. Category/code/tags/steps/progress left blank for the user.
- If the file can't be read, show a non-fatal warning and still create the entry
  with the derived href + filename-based title.

### Transient source-path state
Store the picked absolute source path on the module Map under the key `_src`.
- `_src` is editor-only: it is NOT in `Fields`, so the serializer never writes it
  to `modules.js`.
- `NewModule()` initialises `_src` to `""`.
- `_src` is set only for entries whose file lives outside `library/` and still
  needs copying.
- It is cleared after a successful copy (so re-saving doesn't recopy).
- `Normalize()` (loading existing `modules.js`) leaves `_src` empty — existing
  entries never trigger a copy.

## Part B — Copy-on-save

In `SaveFile()`, after validation passes and the rolling `.bak` is made, but
before/around writing `modules.js`:

1. For each module with a non-empty `_src` **and** a non-empty `href`:
   - Resolve destination = `<repo>\` + `href` with `/`→`\`.
   - If the destination file already exists: prompt `Yes/No`
     "Overwrite `<href>`?". On **No**, skip the copy (the entry is still saved
     with its href; user can place the file manually). On **Yes**, proceed.
   - Create the destination directory (`DirCreate`) and copy
     (`FileCopy(src, dest, overwrite:=true)`).
   - On success, clear `_src`.
   - On copy failure, show the error and abort the save (don't write a
     `modules.js` that points at a file that didn't land) — consistent with the
     existing "backup failed → abort" behavior.
2. Then write `modules.js` as today.

The href is the single source of truth for the destination: if the user edits the
href field before saving, the file is copied to the edited location.

## Part C — Button relayout

Target arrangement (Add New top-left, Reload top-right, Save a prominent
bottom-right button under the form, list-management under the ListView):

```
[Add New]                                           [Reload]
┌─────────────────────────┐   <form fields: Title … Progress>
│ ListView (Title|Type|   │
│  Status)                │
│                         │
└─────────────────────────┘
[Delete]    [Move Up] [Move Down]        [ Save to File ]
```

Concrete coordinates (window stays `w760`, height grows to `h500`;
`+MinSize720x500`):

- **Top toolbar (y8):**
  - `Add New`  → `x8  y8  w90`
  - `Reload`   → `x666 y8 w86`
- **ListView:** `x8 y40 w330 h418` (columns unchanged: Title | Type | Status).
- **List-management row, under the ListView (y462):**
  - `Delete`    → `x8   y462 w70`
  - (gap)
  - `Move Up`   → `x150 y462 w88`
  - `Move Down` → `x242 y462 w96`
- **Save (bottom-right, prominent):** `x500 y462 w252` — aligned on the same row
  as the list-management buttons, on the right side under the form.
- **Form (right column, x350/x440), shifted down to clear the toolbar** — same
  field order and widths as today, each row +30px from current:
  - Title `y40`, Blurb `y72` (r3), Type `y140` (ComboBox), Category `y172`,
    Code `y204`, Tags `y236`, "comma-separated" note `y260`, Status `y284`,
    Href `y316`, Steps `y348`, Progress `y380`.

(Exact pixel values are finalised in the implementation plan; the rule is:
Add New top-left and Reload top-right across the top, list + its management
buttons on the left, the form on the right, and Save as a prominent
bottom-right button.)

## Error handling summary

- Unreadable picked file → warn, still create entry (filename title, derived href).
- Destination exists → per-file Yes/No overwrite prompt.
- Copy failure → error message, abort save (modules.js not rewritten).
- Cancelled picker → blank entry (no error).

## Out of scope

- Auto-detecting `type` from HTML (stays manual, defaults Tutorial).
- Parsing tags/category/steps/progress from HTML.
- Slugifying or renaming the file itself (filename kept verbatim).
- Moving/relinking files for entries that already exist in `modules.js`.
- Any change to `index.html`, `modules.js` data, or the site itself.

## Testing / verification

AutoHotkey v2 is required to run the editor and is not available in the CI/agent
environment, so verification is **manual** (performed by the user):
1. Add New → pick an external `.html` with a `<title>` and a
   `<meta name="description">` → title & blurb prefill; href shows
   `library/<slug>/<file>`.
2. Save → file is copied to `library/<slug>/`, `modules.js` gains the entry, and
   re-saving does not recopy.
3. Add New → pick a file already under `library/` → no copy; href is its existing
   relative path.
4. Add New → cancel picker → blank entry appears.
5. Save into an existing destination → overwrite prompt appears; No skips copy.
6. Buttons appear in the new positions; Delete is visually separated from the
   Move buttons; window large enough that nothing clips.

Where practical, the implementation should keep slugify and the title/description
parsers as small standalone methods so their logic is easy to eyeball.

## Success criteria

- Picking an external HTML file produces a ready-to-save entry with a correct,
  typo-free href and a parsed title (+ blurb when present).
- Saving copies the file to the href location (creating dirs), prompting before
  any overwrite, and never recopies on subsequent saves.
- Files already in `library/` are linked, not duplicated.
- `_src` never appears in the written `modules.js`.
- Buttons are in the specified positions and nothing clips at the default size.
