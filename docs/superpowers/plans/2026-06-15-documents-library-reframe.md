# Documents Library Reframe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reframe the skill-guide site into a Documents Library: add a first-class `type` field, group cards into per-type horizontally-scrollable shelves, rename `skills/` → `library/`, and update the data file, hub, README, and AHK editor to match.

**Architecture:** Static site, no build step. `modules.js` is the single source of truth (a `window.MODULES` array); `index.html` reads it and renders. `type` becomes the primary axis (shelves + filters + call-number prefix); `category` is demoted to a topic tag. `tooling/modules-editor.ahk` (AutoHotkey v2 GUI) must keep producing valid `modules.js`.

**Tech Stack:** Plain HTML/CSS/vanilla JS (GitHub Pages), AutoHotkey v2, Node (used only as a syntax/shape checker for `modules.js`).

**Spec:** `docs/superpowers/specs/2026-06-15-documents-library-reframe-design.md`

**Verification note:** There is no test framework. "Verification" steps are (a) a Node one-liner that loads `modules.js` and asserts its shape, and (b) opening `index.html` in a browser and confirming specific observable outcomes. Run Node checks from the repo root.

---

## File Structure

- `modules.js` — data + template comment. Modified: add `type`, repoint `href`s, rewrite header comment.
- `index.html` — hub. Modified: rendering JS (grouping/shelves/filters/conditional fields), shelf CSS, masthead/footer/title copy, empty-state text.
- `library/` — renamed from `skills/` (content unchanged).
- `README.md` — rewritten structure + "add a document" instructions.
- `tooling/modules-editor.ahk` — add `type` field/control, relayout form, update columns/regex/validation.

---

### Task 1: Rename `skills/` → `library/` and repoint hrefs

**Files:**
- Move: `skills/` → `library/` (contains `blender-rigging/index.html`, `pelvic-floor-training/pelvic-floor-training-guide.html`)
- Modify: `modules.js` (the two `href` values)

- [ ] **Step 1: Move the folder with git**

Run from repo root:
```bash
git mv skills library
```

- [ ] **Step 2: Verify the move**

Run:
```bash
ls library/blender-rigging/index.html library/pelvic-floor-training/pelvic-floor-training-guide.html
```
Expected: both paths listed, no error. `skills/` no longer exists.

- [ ] **Step 3: Repoint the two hrefs in `modules.js`**

In `modules.js`, change:
```
    href:     "skills/blender-rigging/index.html",
```
to
```
    href:     "library/blender-rigging/index.html",
```
and change:
```
    href:     "skills/pelvic-floor-training/pelvic-floor-training-guide.html",
```
to
```
    href:     "library/pelvic-floor-training/pelvic-floor-training-guide.html",
```

- [ ] **Step 4: Verify no `skills/` references remain in code**

Run:
```bash
grep -rn "skills/" modules.js index.html README.md
```
Expected: no matches (exit code 1 / empty output). (Spec/plan docs may still mention it — that's fine.)

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: rename skills/ to library/ and repoint hrefs"
```

---

### Task 2: Add `type` to `modules.js` data + rewrite the template comment

**Files:**
- Modify: `modules.js`

- [ ] **Step 1: Replace the template comment block**

Replace the entire leading `/* ... */` comment (lines 1–19) with:
```js
/*
 * Documents Library — module data.
 * Add a document by copying the TEMPLATE object below into the MODULES array.
 * Shelves (grouped by type), filter buttons, call numbers (e.g. "TUT · 01"),
 * and the header counts are all generated from this file — no other edits needed.
 *
 * TEMPLATE (copy this, fill it in, drop it in the array):
 * {
 *   title:    "Your Document Title",          // required, plain text
 *   blurb:    "One or two sentences.",         // required
 *   type:     "Tutorial",                      // required; Tutorial | Info | Rules | Plan | …
 *                                              //   drives the shelf, filter button, and call-no prefix
 *   category: "Dev",                           // optional; topic — shown as a tag chip
 *   code:     "TUT",                           // optional; call-no prefix. Default derived from type
 *   tags:     ["topic", "topic"],              // optional; extra chips shown on the card
 *   status:   "learning",                      // optional; one of: "solid" | "learning" | "planned"
 *   href:     "library/your-doc/index.html",   // optional. Omit for a not-yet-written doc (inactive card)
 *   steps:    10,                              // optional; tutorials only — shown as "10 steps"
 *   progress: 0                                // optional; tutorials only — 0–100, progress-bar fill %
 * }
 */
```

- [ ] **Step 2: Add `type` to both entries and drop the now-redundant `code`/duplicate tags**

Replace the entire `window.MODULES = [ ... ];` array with:
```js
window.MODULES = [
  {
    title:    "Rigging & Animation in Blender 5.1",
    blurb:    "Zero to animating a monster: armatures, weight painting, FK/IK, Rigify, walk cycles, and creature-specific techniques — with every 5.1 change flagged.",
    type:     "Tutorial",
    category: "3D",
    tags:     ["rigging", "animation", "blender"],
    status:   "learning",
    href:     "library/blender-rigging/index.html",
    steps:    10,
    progress: 8
  },
  {
    title:    "Pelvic Floor Training — Postpartum Prolapse to Lifting",
    blurb:    "From symptom relief to confident lifting: a staged pelvic-floor program covering prolapse recovery and load progression.",
    type:     "Tutorial",
    category: "Health",
    tags:     ["pelvic floor", "postpartum", "prolapse"],
    status:   "solid",
    href:     "library/pelvic-floor-training/pelvic-floor-training-guide.html",
    steps:    8,
    progress: 100
  }
];
```
(The old `code: "3D"` / `code: "HLT"` are removed so the call-no derives from `type` → `TUT`. The category words are removed from `tags` because the renderer now shows `category` as its own chip.)

- [ ] **Step 3: Verify `modules.js` parses and every entry has a `type`**

Run from repo root:
```bash
node -e "global.window={}; require('./modules.js'); const m=window.MODULES; if(!Array.isArray(m)) throw 'not array'; if(m.length!==2) throw 'expected 2, got '+m.length; m.forEach(x=>{if(!x.type) throw 'missing type: '+x.title}); console.log('OK', m.map(x=>x.type).join(','));"
```
Expected: `OK Tutorial,Tutorial`

- [ ] **Step 4: Commit**

```bash
git add modules.js
git commit -m "feat: add type field to modules.js and reframe template comment"
```

---

### Task 3: Rewrite the hub rendering JS (shelves, filters, type-driven call-no, conditional fields)

**Files:**
- Modify: `index.html` (the `<script>` IIFE, lines ~148–252)

- [ ] **Step 1: Replace the entire inline IIFE**

Replace everything between `<script src="modules.js"></script>` and the closing `</body>`'s `<script>...</script>` — i.e. the second `<script>` block — with:
```html
<script>
  (function(){
    var grid = document.getElementById('grid');
    var modules = window.MODULES || [];

    function pad(n){ return n < 10 ? '0' + n : '' + n; }
    function esc(s){ return String(s).replace(/[&<>"]/g, function(c){
      return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]; }); }

    var CODE_MAP = { Tutorial:'TUT', Info:'INF', Rules:'RUL', Plan:'PLN' };
    function codeFor(m){
      return m.code || CODE_MAP[m.type] || String(m.type || '').slice(0,3).toUpperCase();
    }

    var statusLabels = { solid:'Solid', learning:'Learning', planned:'Planned' };

    // group modules by type, preserving first-appearance order
    var types = [];
    var byType = {};
    modules.forEach(function(m){
      var t = m.type || 'Other';
      if (!byType[t]) { byType[t] = []; types.push(t); }
      byType[t].push(m);
    });

    function cardHtml(m, n){
      var callno = codeFor(m) + ' · ' + pad(n);
      var status = m.status || '';
      var active = !!m.href;
      var cls = 'card' + (active ? ' active' : '') + (status === 'planned' ? ' planned' : '');

      var attrs = 'class="' + cls + '"';
      attrs += active
        ? ' tabindex="0" role="link" aria-label="Open: ' + esc(m.title) + '"'
        : ' aria-label="' + esc(m.title) + '"';

      var link = active
        ? '<a class="card-link" href="' + esc(m.href) + '" aria-hidden="true" tabindex="-1"></a>'
        : '';

      // tags: topic category first (if any), then any explicit tags (deduped)
      var tagList = [];
      if (m.category) tagList.push(m.category);
      (m.tags || []).forEach(function(t){ if (tagList.indexOf(t) < 0) tagList.push(t); });
      var tags = tagList.map(function(t){ return '<span class="tag">' + esc(t) + '</span>'; }).join('');

      var statusBadge = status
        ? '<span class="status ' + esc(status) + '">' + esc(statusLabels[status] || status) + '</span>'
        : '';

      var pbar = (m.progress != null)
        ? '<div class="pbar"><i style="width:' + (m.progress || 0) + '%"></i></div>'
        : '';

      var footRight = (m.steps != null) ? esc(m.steps) + ' steps' : '—';
      var footLeft = active
        ? '<span class="open">Open ↗</span>'
        : '<span class="muted">Not started</span>';
      var foot = '<div class="card-foot">' + footLeft
        + '<span class="muted">' + footRight + '</span></div>';

      return '<article ' + attrs + '>'
        + link
        + '<div class="card-top"><span class="callno">' + esc(callno) + '</span>'
        + statusBadge + '</div>'
        + '<h2>' + esc(m.title) + '</h2>'
        + '<p class="blurb">' + esc(m.blurb || '') + '</p>'
        + '<div class="tags">' + tags + '</div>'
        + pbar
        + foot
        + '</article>';
    }

    var addCard = '<article class="card add" aria-label="How to add a new document">'
      + '<div class="plus">+</div>'
      + '<div>Add a document: drop your page in<br><code>library/your-doc/</code><br>then add an entry to <code>modules.js</code>.</div>'
      + '</article>';

    // build one shelf per type
    var html = '';
    types.forEach(function(t){
      var items = byType[t];
      var cards = '';
      items.forEach(function(m, i){ cards += cardHtml(m, i + 1); });
      cards += addCard;
      html += '<section class="shelf" data-type="' + esc(t) + '">'
        + '<div class="shelf-head"><span class="shelf-name">' + esc(t) + '</span>'
        + '<span class="rule"></span>'
        + '<span class="shelf-count">' + items.length + '</span></div>'
        + '<div class="track">' + cards + '</div>'
        + '</section>';
    });
    grid.innerHTML = html;

    // ledger counts
    document.getElementById('count-active').textContent =
      modules.filter(function(m){ return !!m.href; }).length;
    document.getElementById('count-total').textContent = modules.length;
    document.getElementById('updated').textContent = new Date().getFullYear();

    // filter buttons: All + one per type (first-appearance order)
    var filterHtml = '<span class="label">Filter</span>'
      + '<button class="filter" data-filter="all" aria-pressed="true">All</button>';
    types.forEach(function(t){
      filterHtml += '<button class="filter" data-filter="' + esc(t) + '" aria-pressed="false">' + esc(t) + '</button>';
    });
    document.querySelector('.controls').innerHTML = filterHtml;

    // filtering: show/hide whole shelves
    var buttons = document.querySelectorAll('.filter');
    var shelves = document.querySelectorAll('.shelf');
    var empty = document.getElementById('empty');
    buttons.forEach(function(btn){
      btn.addEventListener('click', function(){
        var f = btn.getAttribute('data-filter');
        buttons.forEach(function(b){ b.setAttribute('aria-pressed', b === btn ? 'true' : 'false'); });
        var shown = 0;
        shelves.forEach(function(s){
          var show = (f === 'all') || (s.getAttribute('data-type') === f);
          s.style.display = show ? '' : 'none';
          if (show) shown++;
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

- [ ] **Step 2: Verify in a browser (CSS comes in Task 4 — structure first)**

Open `index.html` in a browser (e.g. `start index.html` on Windows). Open devtools console.
Expected:
- No console errors.
- A `TUTORIAL` heading with a `2` count, followed by the two cards and an "Add a document" card.
- Filter bar shows `All` and `Tutorial` only.
- Each tutorial card shows call-no `TUT · 01` / `TUT · 02`, a status badge, a progress bar, and "N steps".
(Layout will be unstyled/stacked until Task 4 — that's expected.)

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: render per-type shelves with type-driven call-no and conditional fields"
```

---

### Task 4: Add shelf CSS + reframe masthead/footer/title copy

**Files:**
- Modify: `index.html` (`<style>` block, masthead, footer, `<title>`, empty-state text)

- [ ] **Step 1: Add shelf styles**

In the `<style>` block, immediately after the `.grid{...}` rule (the line beginning `.grid{display:grid;`), add:
```css
  /* ---------- per-type shelves ---------- */
  /* #grid no longer a card grid — it stacks shelves vertically */
  #grid{display:block;margin-top:6px}
  .shelf{margin-top:34px}
  .shelf:first-of-type{margin-top:10px}
  .shelf-head{display:flex;align-items:center;gap:14px;margin-bottom:12px}
  .shelf-name{font-family:"Space Grotesk",sans-serif;font-size:1.1rem;font-weight:600;letter-spacing:.04em;text-transform:uppercase;color:var(--ink)}
  .shelf-head .rule{flex:1;height:1px;background:var(--line)}
  .shelf-count{font-family:"JetBrains Mono",monospace;font-size:12px;color:var(--ink-faint)}
  .track{display:flex;gap:18px;overflow-x:auto;overflow-y:hidden;padding:4px 2px 16px;scroll-snap-type:x proximity;scrollbar-width:thin;scrollbar-color:var(--line-2) transparent}
  .track > .card{flex:0 0 330px;scroll-snap-align:start}
  .track::-webkit-scrollbar{height:9px}
  .track::-webkit-scrollbar-thumb{background:var(--line-2);border-radius:100px}
  .track::-webkit-scrollbar-track{background:transparent}
  @media (prefers-reduced-motion:reduce){.track{scroll-snap-type:none}}
```
(The existing `.grid` rule is now harmless — `#grid` is just a container of `.shelf` sections. Leave it.)

- [ ] **Step 2: Update the `<title>`**

Change:
```html
<title>Learning Library</title>
```
to:
```html
<title>Documents Library</title>
```

- [ ] **Step 3: Reframe the masthead**

Replace:
```html
    <p class="eyebrow">Creation Library</p>
    <h1><br>teaching myself<span class="amp">.</span></h1>
    <p class="sub">A growing shelf of self-contained, Documents one folder per skill, each with text, diagrams, and videos. Tutorials, Guides, Information packs.</p>
```
with:
```html
    <p class="eyebrow">Documents Library</p>
    <h1>the library<span class="amp">.</span></h1>
    <p class="sub">A growing shelf of self-contained documents — tutorials, info packs, game rules, and plans. One folder per document, each with text, diagrams, and embedded video.</p>
```

- [ ] **Step 4: Reframe the footer copy**

Replace the first footer paragraph:
```html
    <p>Each skill is its own folder under <code>skills/</code> with its guide inside it. The card grid above is generated from <code>modules.js</code>. To add one: create your page under <code>skills/&lt;name&gt;/</code>, then add one entry to the <code>MODULES</code> array in <code>modules.js</code> (copy the template at the top of that file). Commit, push, and it's live.</p>
```
with:
```html
    <p>Each document is its own folder under <code>library/</code> with its page inside it. The shelves above are generated from <code>modules.js</code>, grouped by document type. To add one: create your page under <code>library/&lt;name&gt;/</code>, then add an entry to the <code>MODULES</code> array in <code>modules.js</code> (copy the template at the top of that file). Commit, push, and it's live.</p>
```

- [ ] **Step 5: Update the empty-state text**

Change:
```html
  <p class="empty" id="empty">No modules with that tag yet.</p>
```
to:
```html
  <p class="empty" id="empty">No documents of that type yet.</p>
```

- [ ] **Step 6: Verify in a browser**

Reload `index.html`.
Expected:
- Masthead reads "the library" / Documents Library framing.
- The `TUTORIAL` shelf header has a rule line and a `2` at the right; cards sit in a single row.
- If the window is narrow enough, the row scrolls horizontally (cards keep a fixed ~330px width) rather than wrapping. The "Add a document" card is the last item in the row.
- Click `Tutorial` then `All`: shelf hides/shows correctly. No console errors.

- [ ] **Step 7: Commit**

```bash
git add index.html
git commit -m "feat: shelf styling and Documents Library copy"
```

---

### Task 5: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the whole README**

Replace the entire contents of `README.md` with:
```markdown
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
```

- [ ] **Step 2: Verify no stale references**

Run:
```bash
grep -n "skills/\|teaching myself\|Learning Library" README.md
```
Expected: no matches.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update README for Documents Library"
```

---

### Task 6: Update the AHK editor for the `type` field

**Files:**
- Modify: `tooling/modules-editor.ahk`

- [ ] **Step 1: Add `type` to the canonical field order and add a `Types` list**

Replace:
```ahk
    Fields := ["title", "blurb", "category", "code", "tags", "status", "href", "steps", "progress"]
    Statuses := ["solid", "learning", "planned"]
```
with:
```ahk
    Fields := ["title", "blurb", "type", "category", "code", "tags", "status", "href", "steps", "progress"]
    Statuses := ["solid", "learning", "planned"]
    Types := ["Tutorial", "Info", "Rules", "Plan"]
```

- [ ] **Step 2: Default new modules to a `type`**

Replace:
```ahk
    NewModule() {
        m := Map()
        for k in this.Fields
            m[k] := ""
        m["tags"] := []
        m["status"] := "learning"
        return m
    }
```
with:
```ahk
    NewModule() {
        m := Map()
        for k in this.Fields
            m[k] := ""
        m["tags"] := []
        m["type"] := "Tutorial"
        m["status"] := "learning"
        return m
    }
```

- [ ] **Step 3: Quote the `type` key when normalising to JSON**

Replace:
```ahk
        body := RegExReplace(body
            , "m)^(\h*)(title|blurb|category|code|tags|status|href|steps|progress)\h*:"
            , "$1`"$2`":")
```
with:
```ahk
        body := RegExReplace(body
            , "m)^(\h*)(title|blurb|type|category|code|tags|status|href|steps|progress)\h*:"
            , "$1`"$2`":")
```

- [ ] **Step 4: Show `Type` instead of `Category` in the ListView**

Replace:
```ahk
        this.lv := this.gui.AddListView("x8 y8 w330 h420", ["Title", "Category", "Status"])
```
with:
```ahk
        this.lv := this.gui.AddListView("x8 y8 w330 h450", ["Title", "Type", "Status"])
```

- [ ] **Step 5: Add the Type control and relayout the form**

Replace the block from `this.AddLabel("Title", ...)` through the `this.ctrl["progress"] := ...` line:
```ahk
        this.AddLabel("Title",    350, 12)
        this.ctrl["title"]    := this.gui.AddEdit("x440 y10 w310")
        this.AddLabel("Blurb",    350, 44)
        this.ctrl["blurb"]    := this.gui.AddEdit("x440 y42 w310 r3 +Wrap")
        this.AddLabel("Category", 350, 110)
        this.ctrl["category"] := this.gui.AddEdit("x440 y108 w310")
        this.AddLabel("Code",     350, 142)
        this.ctrl["code"]     := this.gui.AddEdit("x440 y140 w310")
        this.AddLabel("Tags",     350, 174)
        this.ctrl["tags"]     := this.gui.AddEdit("x440 y172 w310")
        this.gui.AddText("x440 y196 w310 cGray", "comma-separated")
        this.AddLabel("Status",   350, 222)
        this.ctrl["status"]   := this.gui.AddDropDownList("x440 y220 w150", this.Statuses)
        this.AddLabel("Href",     350, 252)
        this.ctrl["href"]     := this.gui.AddEdit("x440 y250 w310")
        this.AddLabel("Steps",    350, 284)
        this.ctrl["steps"]    := this.gui.AddEdit("x440 y282 w80 +Number")
        this.AddLabel("Progress", 350, 316)
        this.ctrl["progress"] := this.gui.AddEdit("x440 y314 w80 +Number")
```
with:
```ahk
        this.AddLabel("Title",    350, 12)
        this.ctrl["title"]    := this.gui.AddEdit("x440 y10 w310")
        this.AddLabel("Blurb",    350, 44)
        this.ctrl["blurb"]    := this.gui.AddEdit("x440 y42 w310 r3 +Wrap")
        this.AddLabel("Type",     350, 110)
        this.ctrl["type"]     := this.gui.AddComboBox("x440 y108 w150", this.Types)
        this.AddLabel("Category", 350, 142)
        this.ctrl["category"] := this.gui.AddEdit("x440 y140 w310")
        this.AddLabel("Code",     350, 174)
        this.ctrl["code"]     := this.gui.AddEdit("x440 y172 w310")
        this.AddLabel("Tags",     350, 206)
        this.ctrl["tags"]     := this.gui.AddEdit("x440 y204 w310")
        this.gui.AddText("x440 y228 w310 cGray", "comma-separated")
        this.AddLabel("Status",   350, 254)
        this.ctrl["status"]   := this.gui.AddDropDownList("x440 y252 w150", this.Statuses)
        this.AddLabel("Href",     350, 286)
        this.ctrl["href"]     := this.gui.AddEdit("x440 y284 w310")
        this.AddLabel("Steps",    350, 318)
        this.ctrl["steps"]    := this.gui.AddEdit("x440 y316 w80 +Number")
        this.AddLabel("Progress", 350, 350)
        this.ctrl["progress"] := this.gui.AddEdit("x440 y348 w80 +Number")
```

- [ ] **Step 6: Move the button rows down to fit the taller form**

Replace:
```ahk
        this.gui.AddButton("x440 y352 w74",  "Add New").OnEvent("Click", (*) => this.AddNew())
        this.gui.AddButton("x519 y352 w74",  "Delete").OnEvent("Click", (*) => this.DeleteSel())
        this.gui.AddButton("x598 y352 w74",  "Move Up").OnEvent("Click", (*) => this.Move(-1))
        this.gui.AddButton("x677 y352 w74",  "Move Down").OnEvent("Click", (*) => this.Move(1))
        this.gui.AddButton("x440 y388 w150", "Save to File").OnEvent("Click", (*) => this.SaveFile())
        this.gui.AddButton("x598 y388 w153", "Reload").OnEvent("Click", (*) => this.Reload())
```
with:
```ahk
        this.gui.AddButton("x440 y386 w74",  "Add New").OnEvent("Click", (*) => this.AddNew())
        this.gui.AddButton("x519 y386 w74",  "Delete").OnEvent("Click", (*) => this.DeleteSel())
        this.gui.AddButton("x598 y386 w74",  "Move Up").OnEvent("Click", (*) => this.Move(-1))
        this.gui.AddButton("x677 y386 w74",  "Move Down").OnEvent("Click", (*) => this.Move(1))
        this.gui.AddButton("x440 y422 w150", "Save to File").OnEvent("Click", (*) => this.SaveFile())
        this.gui.AddButton("x598 y422 w153", "Reload").OnEvent("Click", (*) => this.Reload())
```

- [ ] **Step 7: Grow the window**

Replace:
```ahk
        this.gui.Show("w760 h440")
```
with:
```ahk
        this.gui.Show("w760 h470")
```
And replace the MinSize:
```ahk
        this.gui := Gui("+MinSize720x440", "Modules Editor — " this.FilePath)
```
with:
```ahk
        this.gui := Gui("+MinSize720x470", "Modules Editor — " this.FilePath)
```

- [ ] **Step 8: Show `type` in the ListView rows (3 places)**

In `RefreshList`, replace:
```ahk
        for mod in this.Modules
            this.lv.Add(, mod["title"], mod["category"], mod["status"])
```
with:
```ahk
        for mod in this.Modules
            this.lv.Add(, mod["title"], mod["type"], mod["status"])
```

In `CommitForm`, replace:
```ahk
        if (i <= this.lv.GetCount())
            this.lv.Modify(i, , m["title"], m["category"], m["status"])
```
with:
```ahk
        if (i <= this.lv.GetCount())
            this.lv.Modify(i, , m["title"], m["type"], m["status"])
```

In `AddNew`, replace:
```ahk
        this.lv.Add(, m["title"], m["category"], m["status"])
```
with:
```ahk
        this.lv.Add(, m["title"], m["type"], m["status"])
```

- [ ] **Step 9: Load/commit/clear the `type` field**

In `LoadForm`, after the `this.ctrl["blurb"].Value := mod["blurb"]` line, add:
```ahk
        this.ctrl["type"].Text     := mod["type"]
```

In `CommitForm`, after the `m["blurb"] := this.ctrl["blurb"].Value` line, add:
```ahk
        m["type"]     := this.ctrl["type"].Text
```

Replace `ClearForm`:
```ahk
    ClearForm() {
        for k in this.Fields
            if (k != "status")
                this.ctrl[k].Value := ""
        this.ctrl["status"].Choose(0)
    }
```
with:
```ahk
    ClearForm() {
        for k in this.Fields
            if (k != "status" && k != "type")
                this.ctrl[k].Value := ""
        this.ctrl["type"].Text := ""
        this.ctrl["status"].Choose(0)
    }
```

- [ ] **Step 10: Update validation — require `type`, not `category`**

In `Validate`, replace:
```ahk
            for req in ["title", "blurb", "category", "status"]
```
with:
```ahk
            for req in ["title", "blurb", "type"]
```
(`status` is now optional; the existing `if (st != "" && ...)` check still validates it when present. `category` is no longer required.)

- [ ] **Step 11: Verify the editor round-trips**

This requires AutoHotkey v2 on the machine. Run `tooling/modules-editor.ahk`.
Expected:
- The form shows a **Type** combo (Tutorial/Info/Rules/Plan) above Category; both existing rows show "Tutorial" in the ListView Type column.
- Add a new entry, set Type = `Rules`, Title/Blurb filled, click **Save to File**.
- Then verify the written file still parses and the new type is present:
```bash
node -e "global.window={}; delete require.cache[require.resolve('./modules.js')]; require('./modules.js'); const t=window.MODULES.map(x=>x.type); console.log(t.join(',')); if(!t.includes('Rules')) throw 'Rules not saved';"
```
Expected: the type list printed, including `Rules`, no error.
(If AHK is unavailable in this environment, note that and defer this manual check to the user; the Node check still validates any saved output.)

- [ ] **Step 12: Commit**

```bash
git add tooling/modules-editor.ahk
git commit -m "feat: add type field to modules-editor.ahk"
```

---

### Task 7: Final end-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Confirm `modules.js` shape**

Run:
```bash
node -e "global.window={}; require('./modules.js'); const m=window.MODULES; m.forEach(x=>{if(!x.title||!x.blurb||!x.type) throw 'incomplete: '+JSON.stringify(x)}); console.log('all entries have title/blurb/type; count='+m.length);"
```
Expected: `all entries have title/blurb/type; count=2`

- [ ] **Step 2: Confirm links resolve**

Run:
```bash
ls library/blender-rigging/index.html library/pelvic-floor-training/pelvic-floor-training-guide.html
```
Expected: both exist.

- [ ] **Step 3: Confirm no stale vocabulary in shipped files**

Run:
```bash
grep -rn "skills/\|teaching myself\|Learning Library\|Creation Library" index.html modules.js README.md
```
Expected: no matches.

- [ ] **Step 4: Browser smoke test**

Open `index.html`. Confirm, with no console errors:
- "Documents Library" / "the library" masthead.
- One `TUTORIAL` shelf, count `2`, two cards (`TUT · 01`, `TUT · 02`) each with progress bar + steps, then the "Add a document" card.
- Filter bar: `All`, `Tutorial`. Clicking each toggles the shelf; `All` restores it.
- Clicking a card opens its document under `library/...`.

- [ ] **Step 5: Final commit (if any uncommitted changes remain)**

```bash
git add -A
git commit -m "chore: documents library reframe — final verification" || echo "nothing to commit"
```
