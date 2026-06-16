# Modules Editor — File-First Add & Button Relayout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a file-first "new document" workflow to `tooling/modules-editor.ahk` (pick an HTML file → derive href, parse title/blurb, copy into `library/` on save) and relayout the buttons.

**Architecture:** Pure additions plus three localized edits to the existing `ModulesEditor` AHK v2 class. New best-effort helpers (slugify, HTML parsing, repo/library paths, file→module). `AddNew()` becomes file-first with a blank-entry fallback. `SaveFile()` copies pending source files (tracked by a non-persisted `_src` Map key) to the href location, prompting before overwrite. `BuildGui()` button/field coordinates change.

**Tech Stack:** AutoHotkey v2 (single-file GUI app). No build/test framework.

**Spec:** `docs/superpowers/specs/2026-06-15-editor-file-first-add-design.md`

**VERIFICATION CONSTRAINT:** AutoHotkey v2 is **not runnable in this environment**, and the user will perform the live GUI verification after implementation. Therefore each task's verification is a **static check** (grep/read confirming the exact code is present) — NOT a runtime test. Do not attempt to install or run AutoHotkey. All edits must be exact and syntactically careful because they won't be executed here.

---

## File Structure

Only one file changes: `tooling/modules-editor.ahk`. New methods added to the `ModulesEditor` class:
- `RepoRoot()` / `LibraryDir()` — resolve paths from `this.FilePath` (the modules.js location).
- `Slugify(name)` — filename → URL-safe slug.
- `DecodeEntities(s)` — decode the five common HTML entities.
- `ParseHtmlMeta(path)` — best-effort `<title>` + `<meta name="description">` extraction.
- `ModuleFromHtml(path)` — build a prefilled module Map from a picked HTML file.
- `CopyPendingFiles()` — copy `_src` files into the library at save time.

Modified methods: `NewModule` (init `_src`), `AddNew` (file-first), `SaveFile` (call `CopyPendingFiles`), `BuildGui` (relayout), `Run` (window height).

---

### Task 1: Add path/parse/module helpers and `_src` field

**Files:**
- Modify: `tooling/modules-editor.ahk`

- [ ] **Step 1: Initialise `_src` in `NewModule`**

Replace:
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
with:
```ahk
    NewModule() {
        m := Map()
        for k in this.Fields
            m[k] := ""
        m["tags"] := []
        m["type"] := "Tutorial"
        m["status"] := "learning"
        m["_src"] := ""          ; editor-only: pending source HTML to copy on save (never serialized)
        return m
    }
```

- [ ] **Step 2: Add the helper methods**

Insert the following methods immediately AFTER the `NewModule()` method's closing brace (before the `; ------ GUI` comment / `BuildGui()`):
```ahk
    ; ---------------------------------------------------------- file helpers
    ; Repo root = the directory that holds modules.js (this.FilePath).
    RepoRoot() {
        SplitPath(this.FilePath, , &dir)
        return dir
    }

    LibraryDir() {
        return this.RepoRoot() "\library"
    }

    ; Filename (no extension) -> URL-safe slug. Empty -> "doc".
    Slugify(name) {
        s := StrLower(Trim(name))
        s := RegExReplace(s, "[\s_]+", "-")     ; spaces/underscores -> hyphen
        s := RegExReplace(s, "[^a-z0-9-]", "")  ; drop everything else
        s := RegExReplace(s, "-+", "-")         ; collapse repeats
        s := Trim(s, "-")                        ; trim edge hyphens
        return (s = "") ? "doc" : s
    }

    DecodeEntities(s) {
        s := StrReplace(s, "&lt;", "<")
        s := StrReplace(s, "&gt;", ">")
        s := StrReplace(s, "&quot;", '"')
        s := StrReplace(s, "&#39;", "'")
        s := StrReplace(s, "&amp;", "&")        ; do & last to avoid double-decoding
        return s
    }

    ; Best-effort parse of <title> and <meta name="description">. Never throws.
    ParseHtmlMeta(path) {
        out := Map("title", "", "blurb", "")
        try {
            raw := FileRead(path, "UTF-8")
        } catch {
            return out
        }
        if RegExMatch(raw, "is)<title[^>]*>(.*?)</title>", &mt)
            out["title"] := this.DecodeEntities(Trim(mt[1]))
        ; find the <meta ...> tag whose name attr is description (any attr order)
        if RegExMatch(raw, "is)<meta\s+[^>]*name\s*=\s*([""'])description\1[^>]*>", &mm)
            if RegExMatch(mm[0], "is)content\s*=\s*([""'])(.*?)\1", &mc)
                out["blurb"] := this.DecodeEntities(Trim(mc[2]))
        return out
    }

    ; Build a prefilled module from a picked HTML file.
    ModuleFromHtml(path) {
        m := this.NewModule()
        SplitPath(path, &fileName, , , &nameNoExt)
        meta := this.ParseHtmlMeta(path)
        m["title"] := (meta["title"] != "") ? meta["title"] : nameNoExt
        m["blurb"] := meta["blurb"]
        libDir := this.LibraryDir()
        if (SubStr(path, 1, StrLen(libDir) + 1) = libDir "\") {
            ; already inside library/ -> link to its existing path, no copy
            m["href"] := StrReplace(SubStr(path, StrLen(this.RepoRoot()) + 2), "\", "/")
        } else {
            ; outside library/ -> derive dest from filename slug; copy on save
            m["href"] := "library/" this.Slugify(nameNoExt) "/" fileName
            m["_src"] := path
        }
        return m
    }
```

- [ ] **Step 3: Static verification**

Run from repo root:
```bash
grep -n "m\[\"_src\"\] := \"\"\|RepoRoot()\|LibraryDir()\|Slugify(name)\|DecodeEntities(s)\|ParseHtmlMeta(path)\|ModuleFromHtml(path)" tooling/modules-editor.ahk
```
Expected: matches for the `_src` init line and each new method definition.
Also confirm the meta-description regex line is present (it should contain the
`[""']` escaped-quote char class and the `\1` backreference):
```bash
grep -n "description" tooling/modules-editor.ahk
```
Expected: one match — the `ParseHtmlMeta` line `...name\s*=\s*([""'])description\1...`. Eyeball it to confirm the `[""']` char class and `\1` backref are intact.

- [ ] **Step 4: Commit**

```bash
git add tooling/modules-editor.ahk
git commit -m "feat(editor): add slug/HTML-parse/path helpers and _src field"
```

---

### Task 2: File-first `AddNew`

**Files:**
- Modify: `tooling/modules-editor.ahk` (the `AddNew` method)

- [ ] **Step 1: Replace `AddNew`**

Replace:
```ahk
    AddNew() {
        this.CommitForm()
        m := this.NewModule()
        this.Modules.Push(m)
        this.lv.Add(, m["title"], m["type"], m["status"])
        this.SelectIndex(this.Modules.Length)
        this.ctrl["title"].Focus()
    }
```
with:
```ahk
    AddNew() {
        this.CommitForm()
        sel := FileSelect(3, this.LibraryDir()
            , "Select the document's HTML file  (Cancel for a blank entry)"
            , "HTML (*.html; *.htm)")
        m := (sel = "") ? this.NewModule() : this.ModuleFromHtml(sel)
        this.Modules.Push(m)
        this.lv.Add(, m["title"], m["type"], m["status"])
        this.SelectIndex(this.Modules.Length)
        this.ctrl["title"].Focus()
    }
```

- [ ] **Step 2: Static verification**

Run:
```bash
grep -n "FileSelect(3, this.LibraryDir()\|ModuleFromHtml(sel)\|(sel = \"\") ? this.NewModule()" tooling/modules-editor.ahk
```
Expected: matches for the picker call, the conditional module creation, and `ModuleFromHtml(sel)`.

- [ ] **Step 3: Commit**

```bash
git add tooling/modules-editor.ahk
git commit -m "feat(editor): file-first Add New with blank-entry fallback"
```

---

### Task 3: Copy-on-save

**Files:**
- Modify: `tooling/modules-editor.ahk` (`SaveFile` + new `CopyPendingFiles`)

- [ ] **Step 1: Add `CopyPendingFiles` method**

Insert this method immediately BEFORE the `SaveFile()` method:
```ahk
    ; Copy any picked HTML files (modules with a pending _src) into the library,
    ; at the location their href points to. Returns false to abort the save.
    CopyPendingFiles() {
        repo := this.RepoRoot()
        for m in this.Modules {
            src  := m.Has("_src") ? m["_src"] : ""
            href := Trim(m["href"])
            if (src = "" || href = "")
                continue
            dest := repo "\" StrReplace(href, "/", "\")
            if FileExist(dest) {
                if (MsgBox("Overwrite " href " ?", "File exists", "YesNo Icon!") != "Yes") {
                    m["_src"] := ""          ; user declined; don't ask again
                    continue
                }
            }
            SplitPath(dest, , &destDir)
            try {
                if !DirExist(destDir)
                    DirCreate(destDir)
                FileCopy(src, dest, true)
            } catch as e {
                MsgBox("Copy failed for " href ":`n" e.Message "`n`nSave aborted.", "Error", "IconX")
                return false
            }
            m["_src"] := ""                   ; copied; don't recopy on next save
        }
        return true
    }
```

- [ ] **Step 2: Call it in `SaveFile` (after backup, before write)**

In `SaveFile`, replace:
```ahk
        ; single rolling backup
        if FileExist(this.FilePath) {
            try {
                FileCopy(this.FilePath, this.FilePath ".bak", true)
            } catch as e {
                MsgBox("Backup failed: " e.Message "`nSave aborted.", "Error", "IconX")
                return
            }
        }
        content := this.Serialize()
```
with:
```ahk
        ; single rolling backup
        if FileExist(this.FilePath) {
            try {
                FileCopy(this.FilePath, this.FilePath ".bak", true)
            } catch as e {
                MsgBox("Backup failed: " e.Message "`nSave aborted.", "Error", "IconX")
                return
            }
        }
        ; copy newly-picked HTML files into the library before writing modules.js
        if !this.CopyPendingFiles()
            return
        content := this.Serialize()
```

- [ ] **Step 3: Static verification**

Run:
```bash
grep -n "CopyPendingFiles()\|if !this.CopyPendingFiles()\|m.Has(\"_src\")\|FileCopy(src, dest, true)" tooling/modules-editor.ahk
```
Expected: the method definition, the call site in SaveFile, the `_src` guard, and the FileCopy line.

Confirm `_src` is still never serialized (the serializer only emits keys in `Fields`, and `_src` is not in `Fields`):
```bash
grep -n "Fields :=" tooling/modules-editor.ahk
```
Expected: the `Fields := [...]` line, which must NOT contain `_src`.

- [ ] **Step 4: Commit**

```bash
git add tooling/modules-editor.ahk
git commit -m "feat(editor): copy picked HTML into library on save"
```

---

### Task 4: Button relayout & window size

**Files:**
- Modify: `tooling/modules-editor.ahk` (`BuildGui` ListView+form+buttons, `Run` show, MinSize)

- [ ] **Step 1: Grow the window in `Run`**

Replace:
```ahk
        this.gui.Show("w760 h470")
```
with:
```ahk
        this.gui.Show("w760 h500")
```

- [ ] **Step 2: Update MinSize and ListView position**

Replace:
```ahk
        this.gui := Gui("+MinSize720x470", "Modules Editor — " this.FilePath)
```
with:
```ahk
        this.gui := Gui("+MinSize720x500", "Modules Editor — " this.FilePath)
```
Then replace:
```ahk
        this.lv := this.gui.AddListView("x8 y8 w330 h450", ["Title", "Type", "Status"])
```
with:
```ahk
        this.lv := this.gui.AddListView("x8 y40 w330 h418", ["Title", "Type", "Status"])
```

- [ ] **Step 3: Shift the form fields down (clear the top toolbar)**

Replace the whole block from `this.AddLabel("Title", 350, 12)` through `this.ctrl["progress"] := this.gui.AddEdit("x440 y348 w80 +Number")`:
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
with:
```ahk
        this.AddLabel("Title",    350, 42)
        this.ctrl["title"]    := this.gui.AddEdit("x440 y40 w310")
        this.AddLabel("Blurb",    350, 74)
        this.ctrl["blurb"]    := this.gui.AddEdit("x440 y72 w310 r3 +Wrap")
        this.AddLabel("Type",     350, 140)
        this.ctrl["type"]     := this.gui.AddComboBox("x440 y138 w150", this.Types)
        this.AddLabel("Category", 350, 172)
        this.ctrl["category"] := this.gui.AddEdit("x440 y170 w310")
        this.AddLabel("Code",     350, 204)
        this.ctrl["code"]     := this.gui.AddEdit("x440 y202 w310")
        this.AddLabel("Tags",     350, 236)
        this.ctrl["tags"]     := this.gui.AddEdit("x440 y234 w310")
        this.gui.AddText("x440 y258 w310 cGray", "comma-separated")
        this.AddLabel("Status",   350, 284)
        this.ctrl["status"]   := this.gui.AddDropDownList("x440 y282 w150", this.Statuses)
        this.AddLabel("Href",     350, 316)
        this.ctrl["href"]     := this.gui.AddEdit("x440 y314 w310")
        this.AddLabel("Steps",    350, 348)
        this.ctrl["steps"]    := this.gui.AddEdit("x440 y346 w80 +Number")
        this.AddLabel("Progress", 350, 380)
        this.ctrl["progress"] := this.gui.AddEdit("x440 y378 w80 +Number")
```

- [ ] **Step 4: Reposition the buttons**

Replace:
```ahk
        this.gui.AddButton("x440 y386 w74",  "Add New").OnEvent("Click", (*) => this.AddNew())
        this.gui.AddButton("x519 y386 w74",  "Delete").OnEvent("Click", (*) => this.DeleteSel())
        this.gui.AddButton("x598 y386 w74",  "Move Up").OnEvent("Click", (*) => this.Move(-1))
        this.gui.AddButton("x677 y386 w74",  "Move Down").OnEvent("Click", (*) => this.Move(1))
        this.gui.AddButton("x440 y422 w150", "Save to File").OnEvent("Click", (*) => this.SaveFile())
        this.gui.AddButton("x598 y422 w153", "Reload").OnEvent("Click", (*) => this.Reload())
```
with:
```ahk
        ; top toolbar
        this.gui.AddButton("x8   y8   w90",  "Add New").OnEvent("Click", (*) => this.AddNew())
        this.gui.AddButton("x666 y8   w86",  "Reload").OnEvent("Click", (*) => this.Reload())
        ; list-management row, under the ListView (gap between Delete and the Move buttons)
        this.gui.AddButton("x8   y462 w70",  "Delete").OnEvent("Click", (*) => this.DeleteSel())
        this.gui.AddButton("x150 y462 w88",  "Move Up").OnEvent("Click", (*) => this.Move(-1))
        this.gui.AddButton("x242 y462 w96",  "Move Down").OnEvent("Click", (*) => this.Move(1))
        ; prominent save, bottom-right under the form
        this.gui.AddButton("x500 y462 w252", "Save to File").OnEvent("Click", (*) => this.SaveFile())
```

- [ ] **Step 5: Static verification**

Run:
```bash
grep -n "Show(\"w760 h500\")\|MinSize720x500\|AddListView(\"x8 y40 w330 h418\"\|\"x8   y8   w90\",  \"Add New\"\|\"x666 y8   w86\",  \"Reload\"\|\"x8   y462 w70\",  \"Delete\"\|\"x500 y462 w252\", \"Save to File\"" tooling/modules-editor.ahk
```
Expected: matches for window size, MinSize, ListView, and the four repositioned buttons.

Confirm no button still sits at the old `y386`/`y422` coordinates:
```bash
grep -n "y386\|y422" tooling/modules-editor.ahk && echo "STALE COORDS FOUND" || echo "(no stale button coords - good)"
```
Expected: `(no stale button coords - good)`

- [ ] **Step 6: Commit**

```bash
git add tooling/modules-editor.ahk
git commit -m "feat(editor): relayout buttons (toolbar + list-management + bottom-right save)"
```

---

### Task 5: Final static review + manual-verification handoff

**Files:** none (review only)

- [ ] **Step 1: Confirm `_src` is never serialized and all new pieces are present**

Run:
```bash
grep -n "_src" tooling/modules-editor.ahk
```
Expected: `_src` appears ONLY in: `NewModule` init, `ModuleFromHtml` (the else branch), and `CopyPendingFiles` (guard + two clears). It must NOT appear in the `Fields` array, `Serialize`, `SerializeModule`, or `Validate`.

- [ ] **Step 2: Brace/paren sanity scan (best-effort, no AHK runtime)**

Run:
```bash
node -e "const s=require('fs').readFileSync('tooling/modules-editor.ahk','utf8'); const o=(s.match(/{/g)||[]).length, c=(s.match(/}/g)||[]).length; console.log('open{',o,'close}',c, o===c?'BALANCED':'MISMATCH');"
```
Expected: `BALANCED` (open and close brace counts equal). (Heuristic only — braces inside strings/regex could skew it; if MISMATCH, eyeball the edited methods.)

- [ ] **Step 3: Record the manual verification checklist for the user**

No code change. The user will run the editor (AutoHotkey v2) and verify, per the spec's Testing section:
1. Add New → pick external `.html` with `<title>` + `<meta name="description">` → title & blurb prefill; href shows `library/<slug>/<file>`.
2. Save → file copied into `library/<slug>/`; entry written to modules.js; re-save does not recopy.
3. Add New → pick a file already under `library/` → no copy; href is its existing relative path.
4. Add New → Cancel → blank entry.
5. Save into an existing destination → overwrite prompt; No skips copy.
6. Buttons in new positions; gap between Delete and the Move buttons; nothing clips at default size.

- [ ] **Step 4: Commit (if any uncommitted changes remain)**

```bash
git add -A
git commit -m "chore(editor): file-first add — final review" || echo "nothing to commit"
```
