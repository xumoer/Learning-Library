; JSON.ahk (AHK v2) — single-file friendly
; - Parses JSON into Map/Array
; - Stringifies Map/Array/primitives to JSON
; - Supports \uXXXX escapes
; - Represents JSON null as unset/Null (configurable)

class JSON {
    ; ---------------------------
    ; Public API
    ; ---------------------------

    static Parse(text) {
        if (text = "")
            throw Error("JSON.Parse: Empty input string")
        pos := 1
        val := this._ParseValue(text, &pos)
        this._SkipWhitespace(text, &pos)
        if (pos <= StrLen(text))
            throw Error("JSON.Parse: Trailing characters at position " pos)
        return val
    }

    static Stringify(value, indent := "    ", _level := 0) {
        ; null handling
        if (value = JSON.Null)  ; if you choose to use JSON.Null explicitly
            return "null"

        if IsObject(value) {
            is_map := (value is Map)
            is_array := (value is Array)

            ; Treat generic objects as Map-like
            if (!is_map && !is_array)
                is_map := true

            current_indent := ""
            loop _level
                current_indent .= indent
            next_indent := current_indent . indent

            if is_array {
                if (value.Length = 0)
                    return "[]"

                out := "["
                for i, v in value {
                    out .= (i = 1 ? "" : ",")
                    . "`n" . next_indent . this.Stringify(v, indent, _level + 1)
                }
                out .= "`n" . current_indent . "]"
                return out
            } else {
                ; Map/object
                i := 0
                out := "{"
                for k, v in value {
                    i++
                    out .= (i = 1 ? "" : ",")
                    . "`n" . next_indent
                    . this._QuoteString(String(k)) . ": "
                    . this.Stringify(v, indent, _level + 1)
                }
                if (i)
                    out .= "`n" . current_indent
                out .= "}"
                return out
            }
        }

        ; primitives
        if IsNumber(value)
            return this._FormatNumber(value)

        if (value == true)
            return "true"
        if (value == false)
            return "false"

        ; AHK doesn't have a dedicated null literal.
        ; Default: treat unset/"" as string unless you explicitly pass JSON.Null.
        ; If you want empty string to serialize as null, uncomment:
        ; if (value = "") return "null"

        return this._QuoteString(String(value))
    }

    ; Optional: a sentinel you can use in your app to mean JSON null
    static Null := { __json_null: true }

    ; ---------------------------
    ; Private: Parsing
    ; ---------------------------

    static _ParseValue(text, &pos) {
        this._SkipWhitespace(text, &pos)
        if (pos > StrLen(text))
            throw Error("JSON.Parse: Unexpected end of input")

        ch := SubStr(text, pos, 1)

        if (ch = "{")
            return this._ParseObject(text, &pos)
        if (ch = "[")
            return this._ParseArray(text, &pos)
        if (ch = '"')
            return this._ParseString(text, &pos)

        if (ch = "t" || ch = "f" || ch = "n")
            return this._ParseLiteral(text, &pos)

        ; number (or error)
        return this._ParseNumber(text, &pos)
    }

    static _ParseObject(text, &pos) {
        obj := Map()
        pos++ ; skip '{'

        this._SkipWhitespace(text, &pos)
        if (SubStr(text, pos, 1) = "}") {
            pos++
            return obj
        }

        loop {
            this._SkipWhitespace(text, &pos)
            if (SubStr(text, pos, 1) != '"')
                throw Error("JSON.Parse: Expected" . '\"' . " at position " . pos . " for object key")

            key := this._ParseString(text, &pos)

            this._SkipWhitespace(text, &pos)
            if (SubStr(text, pos, 1) != ":")
                throw Error("JSON.Parse: Expected ':' at position " pos)
            pos++

            val := this._ParseValue(text, &pos)
            obj[key] := val

            this._SkipWhitespace(text, &pos)
            ch := SubStr(text, pos, 1)
            if (ch = "}") {
                pos++
                return obj
            }
            if (ch = ",") {
                pos++
                continue
            }
            throw Error("JSON.Parse: Expected ',' or '}' at position " pos)
        }
    }

    static _ParseArray(text, &pos) {
        arr := []
        pos++ ; skip '['

        this._SkipWhitespace(text, &pos)
        if (SubStr(text, pos, 1) = "]") {
            pos++
            return arr
        }

        loop {
            arr.Push(this._ParseValue(text, &pos))
            this._SkipWhitespace(text, &pos)
            ch := SubStr(text, pos, 1)
            if (ch = "]") {
                pos++
                return arr
            }
            if (ch = ",") {
                pos++
                continue
            }
            throw Error("JSON.Parse: Expected ',' or ']' at position " pos)
        }
    }

    static _ParseString(text, &pos) {
        ; assumes current char is '"'
        pos++ ; skip opening quote
        out := ""

        len := StrLen(text)
        while (pos <= len) {
            ; grab everything that ISN'T a quote or backslash, all at once
            if RegExMatch(text, '[^"\\]+', &m, pos) && m.Pos[0] = pos {
                out .= m[0]           ; append the whole run
                pos += m.Len[0]       ; jump past it
            }

            if (pos > len)
                throw Error("JSON.Parse: Unterminated string")

        ch := SubStr(text, pos, 1)

            if (ch = '"') {
                pos++
                return out ; done — closing quote
            }

            if (ch = "\") {
                pos++
                if (pos > len)
                    throw Error("JSON.Parse: Unterminated escape at end of input")

                esc := SubStr(text, pos, 1)

                switch esc {
                    case '"': out .= '"'
                    case "\": out .= "\"
                    case "/": out .= "/"
                    case "b": out .= Chr(8)
                    case "f": out .= Chr(12)
                    case "n": out .= "`n"
                    case "r": out .= "`r"
                    case "t": out .= "`t"
                    case "u":
                        ; \uXXXX
                        hex := SubStr(text, pos + 1, 4)
                        if !RegExMatch(hex, "i)^[0-9a-f]{4}$")
                            throw Error("JSON.Parse: Invalid \\u escape at position " pos)
                        code := Integer("0x" hex)
                        out .= Chr(code)
                        pos += 4
                    default:
                        throw Error("JSON.Parse: Invalid escape at " pos)

                }
                pos++
                continue
            }

            ; shouldn't get here, but safety net
            out .= ch
            pos++
            }

        throw Error("JSON.Parse: Unterminated string")
    }

    static _ParseLiteral(text, &pos) {
        if (SubStr(text, pos, 4) = "true") {
            pos += 4
            return true
        }
        if (SubStr(text, pos, 5) = "false") {
            pos += 5
            return false
        }
        if (SubStr(text, pos, 4) = "null") {
            pos += 4
            return JSON.Null
            ; If you want legacy behavior (null -> empty string), use:
            ; return ""
        }
        throw Error("JSON.Parse: Unknown literal at position " pos)
    }

    static _ParseNumber(text, &pos) {
        ; JSON number grammar
        re := "^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?"
        hay := SubStr(text, pos)

        if RegExMatch(hay, re, &m) {
            pos += m.Len[0]          ; v2: Len is an array, [0] is the whole match length
            return Number(m[0])      ; v2: m[0] is the matched text
        }
        throw Error("JSON.Parse: Invalid number at position " pos)
    }

    static _SkipWhitespace(text, &pos) {
       if RegExMatch(text, '[\s]+', &m, pos) && m.Pos[0] = pos
        pos += m.Len[0]
    }

    ; ---------------------------
    ; Private: Stringify helpers
    ; ---------------------------

    static _QuoteString(s) {
        ; Escape per JSON rules
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`b", "\b")
        s := StrReplace(s, "`f", "\f")
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")

        ; Escape other control chars (0x00-0x1F) to \u00XX
        out := ""
        loop parse s {
            ch := A_LoopField
            code := Ord(ch)
            if (code < 0x20) {
                out .= "\u" . Format("{:04X}", code)
            } else {
                out .= ch
            }
        }

        return '"' . out . '"'
    }

    static _FormatNumber(n) {
        ; Ensure JSON-compatible formatting (no locale commas)
        ; AHK's String(n) is usually fine; keep it simple:
          s := Trim(String(n))
    if (StrLen(s) > 1 && SubStr(s, 1, 1) = "0" && SubStr(s, 2, 1) != ".")
        return this._QuoteString(s)  ; treat as string, not number
    return s
    }
}
