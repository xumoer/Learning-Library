# Data-driven Learning Library Hub — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make adding a module to the hub a one-place edit — append an object to `modules.js` — by rendering all cards, filter buttons, call numbers, and ledger counts from data instead of hand-written HTML.

**Architecture:** A JS data file (`modules.js`) assigns `window.MODULES = [ … ]`, loaded via `<script src>` so it works on `file://` and GitHub Pages alike. `index.html` keeps all its existing CSS but replaces the static card markup and static filter buttons with a render script that builds the grid, filter row, call numbers, and ledger counts from `window.MODULES`.

**Tech Stack:** Plain HTML/CSS/vanilla JS. No build step, no Node, no test runner — verification is done by opening the page in a browser and checking observable outcomes (matches the project's "nothing to run" guarantee).

**Spec:** `docs/superpowers/specs/2026-06-15-data-driven-hub-design.md`

---

## File Structure

- **Create `modules.js`** — the data array + a documented template comment. Single responsibility: hold module data.
- **Modify `index.html`** — empty the `#grid` and `.controls` children (JS fills them), add `<script src="modules.js">`, replace the bottom `<script>` with the new render+filter+ledger logic, and update the footer copy. CSS block is untouched.

No other files change. Individual skill pages under `skills/` are not touched.

---

## Task 1: Create `modules.js` with seed data and template

**Files:**
- Create: `modules.js`

- [ ] **Step 1: Write `modules.js`**

Create `G:/Software Dev/Learning-library/modules.js` with exactly this content:

```js
/*
 * Learning Library — module data.
 * Add a new guide by copying the TEMPLATE object below into the MODULES array.
 * Cards, filter buttons, call numbers (e.g. "3D · 01"), and the header counts
 * are all generated from this file — no other edits needed.
 *
 * TEMPLATE (copy this, fill it in, drop it in the array):
 * {
 *   title:    "Your Module Title",        // required, plain text
 *   blurb:    "One or two sentences.",     // required
 *   category: "Dev",                       // required; makes a filter button + call-no prefix
 *   code:     "DEV",                        // optional; call-no prefix. Default = category, first 3 chars, uppercased
 *   tags:     ["Dev", "topic", "topic"],  // optional; chips shown on the card
 *   status:   "learning",                  // required; one of: "solid" | "learning" | "planned"
 *   href:     "skills/your-skill/index.html", // optional. Omit (or use status:"planned") for a placeholder card
 *   steps:    10,                           // optional; shown in the footer, e.g. "10 steps"
 *   progress: 0                             // optional; 0–100; progress-bar fill %
 * }
 */
window.MODULES = [
  {
    title:    "Rigging & Animation in Blender 5.1",
    blurb:    "Zero to animating a monster: armatures, weight painting, FK/IK, Rigify, walk cycles, and creature-specific techniques — with every 5.1 change flagged.",
    category: "3D",
    code:     "3D",
    tags:     ["3D", "rigging", "animation", "blender"],
    status:   "learning",
    href:     "skills/blender-rigging/index.html",
    steps:    10,
    progress: 8
  },
  {
    title:    "Pelvic Floor Training — Postpartum Prolapse to Lifting",
    blurb:    "From symptom relief to confident lifting: a staged pelvic-floor program covering prolapse recovery and load progression.",
    category: "Health",
    code:     "HLT",
    tags:     ["Health", "pelvic floor", "postpartum", "prolapse"],
    status:   "solid",
    href:     "skills/pelvic-floor-training/pelvic-floor-training-guide.html",
    steps:    8,
    progress: 100
  }
];
```

- [ ] **Step 2: Sanity-check the file is valid JS**

Run: `node --check modules.js` if Node is available; otherwise skip — it will be validated in the browser in Task 3.
Expected: no output (valid). If Node is absent, this is fine; proceed.

- [ ] **Step 3: Commit**

```bash
git add modules.js
git commit -m "feat: add modules.js data file with seed entries and template"
```

---

## Task 2: Convert `index.html` to render from `window.MODULES`

**Files:**
- Modify: `index.html` (the `.controls` block, the `#grid` block, the footer copy, and the bottom `<script>`)

- [ ] **Step 1: Empty the static filter buttons**

In `index.html`, replace the `.controls` inner buttons with nothing (the render script rebuilds them). Change this block:

```html
  <div class="controls" role="group" aria-label="Filter modules by topic">
    <span class="label">Filter</span>
    <button class="filter" data-filter="all" aria-pressed="true">All</button>
    <button class="filter" data-filter="3D" aria-pressed="false">3D</button>
    <button class="filter" data-filter="Music" aria-pressed="false">Music</button>
    <button class="filter" data-filter="Dev" aria-pressed="false">Dev</button>
    <button class="filter" data-filter="Trading" aria-pressed="false">Trading</button>
  </div>
```

to:

```html
  <div class="controls" role="group" aria-label="Filter modules by topic">
    <!-- filter buttons are generated from modules.js -->
  </div>
```

- [ ] **Step 2: Empty the static card grid**

Replace the entire contents of `<div class="grid" id="grid"> … </div>` (all the `<article>` blocks: the Blender card, the three planned placeholders, and the "Add a skill" template card) with an empty grid. The block becomes exactly:

```html
  <div class="grid" id="grid">
    <!-- cards (and the "Add a skill" template card) are generated from modules.js -->
  </div>
  <p class="empty" id="empty">No modules with that tag yet.</p>
```

(Keep the surrounding `<main><div class="wrap"> … </div></main>` as-is. The `#empty` paragraph stays.)

- [ ] **Step 3: Update the footer "how this library works" copy**

In the `<footer>`, change the first paragraph that says to duplicate a card:

```html
    <p>Each skill is its own folder under <code>skills/</code> with an <code>index.html</code> inside it. The card grid above just links to them. To add one: create <code>skills/&lt;name&gt;/index.html</code>, then duplicate a card in this file and point it there. Commit, push, and it's live.</p>
```

to:

```html
    <p>Each skill is its own folder under <code>skills/</code> with its guide inside it. The card grid above is generated from <code>modules.js</code>. To add one: create your page under <code>skills/&lt;name&gt;/</code>, then add one entry to the <code>MODULES</code> array in <code>modules.js</code> (copy the template at the top of that file). Commit, push, and it's live.</p>
```

- [ ] **Step 4: Add the data file include and replace the bottom script**

Replace the entire existing bottom `<script> … </script>` block (the IIFE that does tag filtering and sets `updated`) with these two script tags:

```html
<script src="modules.js"></script>
<script>
  (function(){
    var grid = document.getElementById('grid');
    var modules = window.MODULES || [];

    function pad(n){ return n < 10 ? '0' + n : '' + n; }
    function esc(s){ return String(s).replace(/[&<>"]/g, function(c){
      return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]; }); }
    function codeFor(m){ return m.code || String(m.category).slice(0,3).toUpperCase(); }

    var statusLabels = { solid:'Solid', learning:'Learning', planned:'Planned' };
    var counters = {};
    var html = '';

    modules.forEach(function(m){
      var cat = m.category;
      counters[cat] = (counters[cat] || 0) + 1;
      var callno = codeFor(m) + ' · ' + pad(counters[cat]);
      var status = m.status || 'planned';
      var active = !!m.href && status !== 'planned';
      var tags = (m.tags || []).map(function(t){ return '<span class="tag">' + esc(t) + '</span>'; }).join('');
      var cls = 'card' + (active ? ' active' : '') + (status === 'planned' ? ' planned' : '');

      var attrs = 'class="' + cls + '" data-cat="' + esc(cat) + '"';
      attrs += active
        ? ' tabindex="0" role="link" aria-label="Open: ' + esc(m.title) + '"'
        : ' aria-label="Planned module"';

      var link = active
        ? '<a class="card-link" href="' + esc(m.href) + '" aria-hidden="true" tabindex="-1"></a>'
        : '';

      var pbar = '<div class="pbar"><i style="width:' + (active ? (m.progress || 0) : 0) + '%"></i></div>';
      var foot = active
        ? '<div class="card-foot"><span class="open">Open module ↗</span><span class="muted">' + (m.steps ? esc(m.steps) + ' steps' : '—') + '</span></div>'
        : '<div class="card-foot"><span class="muted">Not started</span><span class="muted">—</span></div>';

      html += '<article ' + attrs + '>'
        + link
        + '<div class="card-top"><span class="callno">' + esc(callno) + '</span>'
        + '<span class="status ' + esc(status) + '">' + esc(statusLabels[status] || status) + '</span></div>'
        + '<h2>' + esc(m.title) + '</h2>'
        + '<p class="blurb">' + esc(m.blurb || '') + '</p>'
        + '<div class="tags">' + tags + '</div>'
        + pbar
        + foot
        + '</article>';
    });

    // "Add a skill" template card — always last, always visible.
    html += '<article class="card add" data-cat="__add__" aria-label="How to add a new module">'
      + '<div class="plus">+</div>'
      + '<div>Add a skill: drop your page in<br><code>skills/your-skill/</code><br>then add an entry to <code>modules.js</code>.</div>'
      + '</article>';

    grid.innerHTML = html;

    // ledger counts
    var total = modules.length;
    var activeCount = modules.filter(function(m){ return m.status !== 'planned'; }).length;
    document.getElementById('count-active').textContent = activeCount;
    document.getElementById('count-total').textContent = total;
    document.getElementById('updated').textContent = new Date().getFullYear();

    // filter buttons: "All" + distinct categories in order of appearance
    var cats = [];
    modules.forEach(function(m){ if (cats.indexOf(m.category) < 0) cats.push(m.category); });
    var filterHtml = '<span class="label">Filter</span>'
      + '<button class="filter" data-filter="all" aria-pressed="true">All</button>';
    cats.forEach(function(c){
      filterHtml += '<button class="filter" data-filter="' + esc(c) + '" aria-pressed="false">' + esc(c) + '</button>';
    });
    document.querySelector('.controls').innerHTML = filterHtml;

    // wire filtering
    var buttons = document.querySelectorAll('.filter');
    var cards = document.querySelectorAll('.card[data-cat]');
    var empty = document.getElementById('empty');
    buttons.forEach(function(btn){
      btn.addEventListener('click', function(){
        var f = btn.getAttribute('data-filter');
        buttons.forEach(function(b){ b.setAttribute('aria-pressed', b === btn ? 'true' : 'false'); });
        var shown = 0;
        cards.forEach(function(c){
          var isAdd = c.classList.contains('add');
          var show = (f === 'all') || (c.getAttribute('data-cat') === f) || isAdd;
          c.style.display = show ? '' : 'none';
          if (show && !isAdd) shown++;
        });
        empty.style.display = shown === 0 ? 'block' : 'none';
      });
    });

    // keyboard activation of active cards
    document.querySelectorAll('.card.active').forEach(function(c){
      c.addEventListener('keydown', function(e){
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          var l = c.querySelector('.card-link');
          if (l) l.click();
        }
      });
    });
  })();
</script>
```

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: render hub cards, filters, and counts from modules.js"
```

---

## Task 3: Verify in the browser

**Files:** none (verification only)

- [ ] **Step 1: Open the page locally**

Run (Git Bash): `start index.html`  — or in PowerShell: `Invoke-Item index.html`
This opens `index.html` via `file://` in the default browser.

- [ ] **Step 2: Confirm the rendered cards**

Expected, in order:
- Card 1: "Rigging & Animation in Blender 5.1", call number **`3D · 01`**, amber **Learning** badge, progress bar partly filled, footer "Open module ↗" + "10 steps". Clickable (hover lifts it).
- Card 2: "Pelvic Floor Training — Postpartum Prolapse to Lifting", call number **`HLT · 01`**, green **Solid** badge, full progress bar, footer "Open module ↗" + "8 steps". Clickable.
- Last card: dashed **"Add a skill"** template card.
- No "Planned" placeholder cards anywhere.

- [ ] **Step 3: Confirm the ledger and filters**

Expected:
- Header ledger reads **`2` active** and **`2` modules listed**.
- Filter row shows: **All** (pressed), **3D**, **Health** — and nothing else.
- Click **3D** → only the Blender card (and the dashed Add card) show. Click **Health** → only Pelvic Floor (and Add card). Click **All** → both return.

- [ ] **Step 4: Confirm links and keyboard**

Expected:
- Clicking the Blender card opens `skills/blender-rigging/index.html`.
- Clicking the Pelvic Floor card opens `skills/pelvic-floor-training/pelvic-floor-training-guide.html`.
- Tabbing to an active card and pressing Enter opens its page.

- [ ] **Step 5: Confirm the "add a module" flow (smoke test)**

Temporarily append a third object to the `MODULES` array in `modules.js` (e.g. a `category: "Dev"` entry with `status: "planned"` and no `href`), reload the page, and confirm: a new **Dev** filter button appears, a dashed "Not started" card renders with call number `DEV · 01`, and the ledger now reads `2 active` / `3 modules listed`. Then remove the temporary entry and reload to return to two modules.

- [ ] **Step 6: Final commit (if any tweaks were needed)**

If Steps 2–5 surfaced fixes, make them, then:

```bash
git add -A
git commit -m "fix: hub rendering adjustments from browser verification"
```

If no fixes were needed, nothing to commit — the work is already committed in Tasks 1–2.

---

## Notes for the implementer

- **`data-cat`** replaces the old `data-tags` attribute for filtering. The old code matched the *category* string stored in `data-tags`; the new code stores the category in `data-cat` and matches it exactly. Behavior is the same; the attribute name is clearer.
- **`esc()`** is applied to all data-derived strings to keep hand-edited data from breaking the markup (e.g. an `&` in a title). Titles render as plain text — no manual `<br>` line breaks (CSS handles wrapping).
- **Why `modules.js` not `modules.json`:** `<script src>` loads under `file://`; `fetch('modules.json')` does not. See the spec for detail.
