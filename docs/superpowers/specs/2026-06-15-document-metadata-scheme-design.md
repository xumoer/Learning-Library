# Document Metadata Scheme

A reference for the metadata each document page carries in its `<head>`, written as
standard `<meta name="..." content="...">` tags.

## Purpose

Every document lives at `library/<doc-name>/<page>.html` and is registered in
`modules.js`, which feeds the cards on `index.html`. This scheme puts the same
metadata **inside each page**, so a document is self-describing: the page and its
`modules.js` entry agree, and the tags could later be scraped to build `modules.js`
automatically.

The fields mirror the `modules.js` entry shape, with one exception:

- **`href` is excluded** — it is derived from the file's own location.

All fields except `title`, `blurb`, and `type` are optional but helpful.

## The scheme

| Field      | Required | Form in HTML                                  | Notes                                                         |
| ---------- | -------- | --------------------------------------------- | ------------------------------------------------------------ |
| `title`    | ✅       | `<title>` **and** `<meta name="title">`       | Plain text. Matches the card title.                          |
| `blurb`    | ✅       | `<meta name="blurb">`                         | One or two sentences. Matches the card blurb.               |
| `type`     | ✅       | `<meta name="type">`                          | `Tutorial` \| `Info` \| `Rules` \| `Plan` \| … Drives the shelf. |
| `category` | optional | `<meta name="category">`                      | Topic; shown as a tag chip on the card.                     |
| `code`     | optional | `<meta name="code">`                          | Call-number prefix (e.g. `TUT`). Default derived from `type`. |
| `tags`     | optional | `<meta name="tags">`                          | Comma-separated list (e.g. `rigging, animation, blender`).  |
| `status`   | optional | `<meta name="status">`                        | One of `solid` \| `learning` \| `planned`.                  |
| `steps`    | optional | `<meta name="steps">`                         | Tutorials only. Integer.                                    |
| `progress` | optional | `<meta name="progress">`                      | Fallback **default** fill (`0`–`100`). The live value comes from `progress.js` — see [Reading-progress tracking](#reading-progress-tracking). |

## Placement

Put the metadata in `<head>`, after the standard `charset` and `viewport` tags and
alongside the `<title>`.

## Copy-paste block

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>Unified Dice Game</title>
  <meta name="title"    content="Unified Dice Game">
  <meta name="blurb"    content="A unique tabletop rule set">
  <meta name="type"     content="Rules">
  <meta name="category" content="Game Rules">
  <meta name="code"     content="RUL">
  <meta name="tags"     content="Games, Rules, Dice">
  <meta name="status"   content="solid">
  <meta name="steps"    content="25">
  <!-- progress: tutorials only -->
  <!-- <meta name="progress" content="0"> -->
</head>
```

## Reading-progress tracking

Every document page **must** include the shared tracker so the reader's scroll
progress shows on that document's card on `index.html`:

```html
<script src="../../progress.js"></script>   <!-- just before </body> -->
```

The `../../` path resolves to the repo root because every document lives two levels
deep at `library/<doc-name>/<page>.html`.

How it works:

- `progress.js` records how far the reader has scrolled (a monotonic `0`–`100` max)
  into `localStorage`, keyed by the page's `library/...` path.
- `index.html` reads that key to fill the card's progress bar. The live value wins;
  the `progress` field/`<meta>` is only the fallback default for docs not yet opened.
- It is purely client-side — no backend — so it works the same locally and on
  GitHub Pages. Progress is **per-browser/per-device** (a personal "how far I've
  read" marker), not a shared/published number.

## Keeping it in sync

These values should match the document's entry in `modules.js`. When you change a
title, blurb, or status in one place, update the other. (`progress` is the
exception — it is now tracked live by `progress.js`; the field is just a default.)
