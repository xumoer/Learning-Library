# Modules Editor — AHK v2 GUI Design

**Date:** 2026-06-15
**Status:** Approved (brainstorming)

## Purpose

A desktop GUI tool, written in AutoHotkey v2, for editing the Learning Library's
`modules.js` data file without hand-editing JS. It provides full CRUD plus
reordering of module entries, validates them, and writes the file back in the
exact style the file currently uses.

The tool lives in `tooling/` alongside the existing `JSON.ahk` library and is the
single entry point: `tooling/modules-editor.ahk`.

## Background: the file is not strict JSON

`modules.js` is a JavaScript file, not a JSON document:

- A leading `/* ... */` comment block documents the schema and a copy-paste TEMPLATE.
- The data is assigned: `window.MODULES = [ ... ];`
- Object keys are **unquoted** JS identifiers (`title:`, `blurb:`), with aligned
  padding so values line up.

`JSON.ahk` (AHK v2) parses and emits **strict** JSON (quoted keys). The tool must
therefore bridge both directions: convert JS-object syntax to strict JSON on load,
and emit the current unquoted/aligned style on save.

## Data model

Each module is a Map with this canonical field order and these rules
(mirroring the TEMPLATE comment in `modules.js`):

| Field      | Type            | Required | Notes |
|------------|-----------------|----------|-------|
| `title`    | string          | yes      | plain text |
| `blurb`    | string          | yes      | one or two sentences |
| `category` | string          | yes      | makes a filter button + call-no prefix |
| `code`     | string          | no       | call-no prefix; omitted when blank (website defaults it to category, first 3 chars, uppercased) |
| `tags`     | array of string | no       | chips on the card |
| `status`   | string          | yes      | one of `solid` \| `learning` \| `planned` |
| `href`     | string          | no       | omit (or use `status:"planned"`) for a placeholder card |
| `steps`    | integer ≥ 0     | no       | shown in footer |
| `progress` | integer 0–100   | no       | progress-bar fill % |

In memory the data is an **Array of Maps**, preserving array order (array order =
display order on the hub).

## I/O

### Locate the file
- On launch, resolve `modules.js` as `A_ScriptDir "\..\modules.js"`.
- If that path does not exist, prompt with a file picker.

### Load
1. Read the whole file as text.
2. Capture the leading `/* ... */` comment block verbatim (stash for re-emit).
3. Isolate the array text between `window.MODULES = [` and the final `];`.
4. Quote the known keys so the body becomes strict JSON: regex-replace
   `^(\s*)(title|blurb|category|code|tags|status|href|steps|progress)\s*:`
   with `$1"$2":` (multiline). The known-key whitelist avoids touching colons that
   appear inside string values.
5. `JSON.Parse("[" + body + "]")` → Array of Maps.
6. On parse failure: show a message box with the `JSON.ahk` error text; open the
   GUI with an empty list rather than crashing.

### Save
1. Run validation (see below). Abort on any error.
2. Write a backup: copy the current `modules.js` to `modules.js.bak` (single
   rolling backup, overwritten each save). If the backup copy fails, abort and warn.
3. Serialize with the custom emitter and overwrite `modules.js`.

## Output emitter (match current style)

A custom stringifier — **not** `JSON.ahk.Stringify`, which quotes keys. It produces:

```
<verbatim header comment block>
window.MODULES = [
  {
    title:    "…",
    blurb:    "…",
    category: "…",
    code:     "…",
    tags:     ["…", "…"],
    status:   "…",
    href:     "…",
    steps:    10,
    progress: 8
  },
  {
    …
  }
];
```

Rules:
- Object brace indented 2 spaces; fields indented 4 spaces.
- Field `key:` padded with spaces to a fixed column width of 10 (e.g. `title:` +
  4 spaces, `category: ` + 1 space) so values align, matching the current file.
- Canonical field order as in the table above.
- Optional fields that are empty/unset are **omitted** entirely.
- `tags` emitted inline: `["a", "b", "c"]` (empty array omitted).
- `steps` / `progress` emitted as bare numbers.
- Strings escaped per JSON rules (reuse `JSON.ahk`'s quoting where practical) and
  wrapped in double quotes.
- Objects separated by `,`; no trailing comma after the last object or last field.

## GUI layout (single window)

- **Left — ListView** of all modules. Columns: Title, Category, Status. Selecting a
  row loads it into the form on the right.
- **Right — edit form** with controls:
  - Title (Edit)
  - Blurb (multiline Edit)
  - Category (Edit)
  - Code (Edit)
  - Tags (Edit, comma-separated; split/trim on apply)
  - Status (DropDownList: solid / learning / planned)
  - Href (Edit)
  - Steps (Edit, numeric)
  - Progress (Edit, numeric)
- **Buttons:**
  - `Add New` — append a blank module, select it.
  - `Delete` — remove the selected module (confirm).
  - `Move Up` / `Move Down` — reorder the selected module within the array.
  - `Save to File` — validate, back up, write.
  - `Reload` — re-read from disk, discarding in-memory changes (confirm).
- Editing applies to the in-memory array only; disk is untouched until **Save**.
  Form field changes commit back to the selected module's Map automatically when
  the user switches ListView selection, presses a reorder button, or presses
  **Save** — so no separate "Apply" button is needed.

## Validation (on Save)

- Required present and non-empty: `title`, `blurb`, `category`, `status`.
- `status` ∈ { `solid`, `learning`, `planned` }.
- `steps`, if present, is a non-negative integer.
- `progress`, if present, is an integer clamped to 0–100.
- Empty optional fields are dropped from output rather than written as `""`.
- On failure: message box naming the row index/title and offending field; save aborted.

## Error handling

- Load parse failure → message box with error; empty GUI.
- Backup copy failure → abort save, warn.
- Numeric field with non-numeric text → treated as validation error on save.

## Out of scope (YAGNI)

- Editing the header comment / TEMPLATE block (preserved verbatim).
- Multiple backup history / timestamped copies (single rolling `.bak`).
- Auto-deriving `code` from `category` (left to the website's runtime logic).
- Live preview of the rendered hub.
