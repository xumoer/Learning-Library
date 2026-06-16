#Requires AutoHotkey v2.0
#SingleInstance Force
#Include JSON.ahk

; Modules Editor — AHK v2 GUI for editing the Learning Library's modules.js.
; See docs/superpowers/specs/2026-06-15-modules-editor-ahk-design.md.

ModulesEditor().Run()

class ModulesEditor {
    ; canonical field order (also the emit order)
    Fields := ["title", "blurb", "type", "category", "code", "tags", "status", "href", "steps", "progress"]
    Statuses := ["solid", "learning", "planned"]
    Types := ["Tutorial", "Info", "Rules", "Plan"]
    PadWidth := 10

    FilePath := ""
    Header := ""
    Modules := []          ; Array of Maps
    CurrentIndex := 0
    Loading := false       ; guards ListView events during programmatic changes
    gui := ""
    lv := ""
    ctrl := Map()

    ; ------------------------------------------------------------------ run
    Run() {
        if !this.LocateFile()
            ExitApp()
        this.LoadFile()
        this.BuildGui()
        this.RefreshList()
        this.gui.Show("w760 h500")
        this.SelectIndex(this.Modules.Length ? 1 : 0)
    }

    ; -------------------------------------------------------------- locate
    LocateFile() {
        default := A_ScriptDir "\..\modules.js"
        if FileExist(default) {
            this.FilePath := default
            return true
        }
        sel := FileSelect(3, A_ScriptDir, "Locate modules.js", "JavaScript (*.js)")
        if (sel = "") {
            MsgBox("No file selected — exiting.", "Modules Editor")
            return false
        }
        this.FilePath := sel
        return true
    }

    ; ----------------------------------------------------------------- load
    LoadFile() {
        raw := StrReplace(FileRead(this.FilePath, "UTF-8"), "`r`n", "`n")

        ; 1. capture the leading /* ... */ header verbatim for re-emit
        if RegExMatch(raw, "s)^\s*(/\*.*?\*/)", &mh)
            this.Header := mh[1]
        else
            this.Header := "/*`n * Learning Library — module data.`n */"

        ; 2. isolate the array body between `window.MODULES = [` and the final `];`
        if !RegExMatch(raw, "s)window\.MODULES\s*=\s*\[(.*)\]\s*;", &mb) {
            MsgBox("Could not find `nwindow.MODULES = [ ... ];`n in " this.FilePath
                . "`n`nStarting with an empty list.", "Parse error", "Icon!")
            this.Modules := []
            return
        }
        body := mb[1]

        ; 3. quote the known keys so the body becomes strict JSON
        body := RegExReplace(body
            , "m)^(\h*)(title|blurb|type|category|code|tags|status|href|steps|progress)\h*:"
            , "$1`"$2`":")

        ; 4. parse; on failure, warn and fall back to an empty list (don't crash)
        try {
            arr := JSON.Parse("[" body "]")
        } catch as e {
            MsgBox("Could not parse modules.js:`n" e.Message
                . "`n`nStarting with an empty list.", "Parse error", "Icon!")
            arr := []
        }

        ; 5. normalise into uniform Maps (every field present; numbers/tags coerced)
        this.Modules := []
        for mod in arr
            this.Modules.Push(this.Normalize(mod))
    }

    Normalize(src) {
        m := this.NewModule()
        if !(src is Map)
            return m
        for k in this.Fields {
            if !src.Has(k)
                continue
            v := src[k]
            if (k = "tags")
                m[k] := this.AsStringArray(v)
            else
                m[k] := String(v)
        }
        return m
    }

    AsStringArray(v) {
        out := []
        if (v is Array)
            for item in v
                out.Push(String(item))
        return out
    }

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

    ; ------------------------------------------------------------------ GUI
    BuildGui() {
        this.gui := Gui("+MinSize720x500", "Modules Editor — " this.FilePath)
        this.gui.OnEvent("Close", (*) => ExitApp())
        this.gui.SetFont("s9", "Segoe UI")

        this.lv := this.gui.AddListView("x8 y40 w330 h418", ["Title", "Type", "Status"])
        this.lv.OnEvent("ItemSelect", this.OnItemSelect.Bind(this))
        this.lv.ModifyCol(1, 180)
        this.lv.ModifyCol(2, 80)
        this.lv.ModifyCol(3, 64)

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

        ; top toolbar
        this.gui.AddButton("x8   y8   w90",  "Add New").OnEvent("Click", (*) => this.AddNew())
        this.gui.AddButton("x666 y8   w86",  "Reload").OnEvent("Click", (*) => this.Reload())
        ; list-management row, under the ListView (gap between Delete and the Move buttons)
        this.gui.AddButton("x8   y462 w70",  "Delete").OnEvent("Click", (*) => this.DeleteSel())
        this.gui.AddButton("x150 y462 w88",  "Move Up").OnEvent("Click", (*) => this.Move(-1))
        this.gui.AddButton("x242 y462 w96",  "Move Down").OnEvent("Click", (*) => this.Move(1))
        ; prominent save, bottom-right under the form
        this.gui.AddButton("x500 y462 w252", "Save to File").OnEvent("Click", (*) => this.SaveFile())
    }

    AddLabel(text, x, y) {
        this.gui.AddText("x" x " y" y " w84", text)
    }

    ; ------------------------------------------------------------ list view
    RefreshList() {
        this.Loading := true
        this.lv.Delete()
        for mod in this.Modules
            this.lv.Add(, mod["title"], mod["type"], mod["status"])
        this.Loading := false
    }

    OnItemSelect(lv, item, selected) {
        if (this.Loading || !selected)
            return
        this.CommitForm()
        this.CurrentIndex := item
        this.LoadForm(item)
    }

    SelectIndex(i) {
        if (i < 1 || i > this.Modules.Length) {
            this.CurrentIndex := 0
            this.ClearForm()
            return
        }
        this.Loading := true
        this.lv.Modify(i, "Select Focus Vis")
        this.Loading := false
        this.CurrentIndex := i
        this.LoadForm(i)
    }

    ; ----------------------------------------------------------------- form
    LoadForm(i) {
        mod := this.Modules[i]
        this.ctrl["title"].Value    := mod["title"]
        this.ctrl["blurb"].Value    := mod["blurb"]
        this.ctrl["type"].Text     := mod["type"]
        this.ctrl["category"].Value := mod["category"]
        this.ctrl["code"].Value     := mod["code"]
        this.ctrl["tags"].Value     := this.Join(mod["tags"], ", ")
        this.ctrl["status"].Text    := mod["status"]
        this.ctrl["href"].Value     := mod["href"]
        this.ctrl["steps"].Value    := mod["steps"]
        this.ctrl["progress"].Value := mod["progress"]
    }

    ClearForm() {
        for k in this.Fields
            if (k != "status" && k != "type")
                this.ctrl[k].Value := ""
        this.ctrl["type"].Text := ""
        this.ctrl["status"].Choose(0)
    }

    ; Commit the form back into the selected module (called on every navigation/save).
    CommitForm() {
        i := this.CurrentIndex
        if (i < 1 || i > this.Modules.Length)
            return
        m := this.Modules[i]
        m["title"]    := this.ctrl["title"].Value
        m["blurb"]    := this.ctrl["blurb"].Value
        m["type"]     := this.ctrl["type"].Text
        m["category"] := this.ctrl["category"].Value
        m["code"]     := this.ctrl["code"].Value
        m["tags"]     := this.SplitTags(this.ctrl["tags"].Value)
        m["status"]   := this.ctrl["status"].Text
        m["href"]     := this.ctrl["href"].Value
        m["steps"]    := Trim(this.ctrl["steps"].Value)
        m["progress"] := Trim(this.ctrl["progress"].Value)
        if (i <= this.lv.GetCount())
            this.lv.Modify(i, , m["title"], m["type"], m["status"])
    }

    SplitTags(text) {
        tags := []
        for t in StrSplit(text, ",")
            if ((tt := Trim(t)) != "")
                tags.Push(tt)
        return tags
    }

    ; -------------------------------------------------------------- actions
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

    DeleteSel() {
        i := this.CurrentIndex
        if (i < 1)
            return
        title := this.Modules[i]["title"]
        label := (title = "") ? "row " i : title
        if (MsgBox("Delete '" label "'?", "Confirm delete", "YesNo Icon!") != "Yes")
            return
        this.CurrentIndex := 0          ; avoid committing into the doomed row
        this.Modules.RemoveAt(i)
        this.RefreshList()
        this.SelectIndex(Min(i, this.Modules.Length))
    }

    Move(dir) {
        this.CommitForm()
        i := this.CurrentIndex
        j := i + dir
        if (i < 1 || j < 1 || j > this.Modules.Length)
            return
        tmp := this.Modules[i]
        this.Modules[i] := this.Modules[j]
        this.Modules[j] := tmp
        this.RefreshList()
        this.SelectIndex(j)
    }

    Reload() {
        if (MsgBox("Discard in-memory changes and reload from disk?", "Reload", "YesNo Icon!") != "Yes")
            return
        this.CurrentIndex := 0
        this.LoadFile()
        this.RefreshList()
        this.SelectIndex(this.Modules.Length ? 1 : 0)
    }

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

    SaveFile() {
        this.CommitForm()
        errs := this.Validate()
        if errs.Length {
            MsgBox("Cannot save — fix these first:`n`n• " this.Join(errs, "`n• ")
                , "Validation failed", "Icon!")
            return
        }
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
        try {
            f := FileOpen(this.FilePath, "w", "UTF-8-RAW")
            f.Write(content)
            f.Close()
        } catch as e {
            MsgBox("Write failed: " e.Message, "Error", "IconX")
            return
        }
        MsgBox("Saved " this.Modules.Length " modules to`n" this.FilePath, "Saved", "Iconi")
    }

    ; ----------------------------------------------------------- validation
    Validate() {
        errs := []
        for i, mod in this.Modules {
            label := (Trim(mod["title"]) != "") ? mod["title"] : "row " i
            for req in ["title", "blurb", "type"]
                if (Trim(mod[req]) = "")
                    errs.Push(label ": '" req "' is required")
            st := Trim(mod["status"])
            if (st != "" && !this.Contains(this.Statuses, st))
                errs.Push(label ": status must be solid/learning/planned (got '" st "')")
            steps := Trim(mod["steps"])
            if (steps != "" && (!IsInteger(steps) || Integer(steps) < 0))
                errs.Push(label ": steps must be a non-negative integer")
            prog := Trim(mod["progress"])
            if (prog != "" && (!IsInteger(prog) || Integer(prog) < 0 || Integer(prog) > 100))
                errs.Push(label ": progress must be an integer 0–100")
        }
        return errs
    }

    ; ------------------------------------------------------------- emitter
    ; Custom stringifier that reproduces modules.js's unquoted, column-aligned style.
    Serialize() {
        objs := []
        for mod in this.Modules
            objs.Push(this.SerializeModule(mod))
        return this.Header "`nwindow.MODULES = [`n" this.Join(objs, ",`n") "`n];`n"
    }

    SerializeModule(mod) {
        lines := []
        for field in this.Fields {
            if !this.IncludeField(mod, field)
                continue
            key := this.Pad(field ":", this.PadWidth)
            lines.Push("    " key this.SerializeValue(mod, field))
        }
        return "  {`n" this.Join(lines, ",`n") "`n  }"
    }

    ; Required fields always emit; optional fields are dropped when empty/unset.
    IncludeField(mod, field) {
        switch field {
            case "title", "blurb", "category", "status":
                return true
            case "tags":
                return mod["tags"].Length > 0
            default:
                return Trim(mod[field]) != ""
        }
    }

    SerializeValue(mod, field) {
        switch field {
            case "tags":
                parts := []
                for t in mod["tags"]
                    parts.Push(JSON._QuoteString(t))
                return "[" this.Join(parts, ", ") "]"
            case "steps", "progress":
                return Trim(mod[field])          ; bare number
            default:
                return JSON._QuoteString(mod[field])
        }
    }

    ; ------------------------------------------------------------- helpers
    Pad(s, width) {
        while (StrLen(s) < width)
            s .= " "
        return s
    }

    Join(arr, sep) {
        out := ""
        for i, v in arr
            out .= (i = 1 ? "" : sep) v
        return out
    }

    Contains(arr, value) {
        for v in arr
            if (v = value)
                return true
        return false
    }
}
