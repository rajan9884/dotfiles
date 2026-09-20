#!/usr/bin/env python3
"""Merge matugen VS Code fragment into settings.json (VS Code only).

Targets both the Microsoft build (Code) and the running OSS build
(Code - OSS). Preserves every unrelated key in each file.

Code target: full fragment replace, then post-process so colors stay
readable on OLED *and* follow the wallpaper instead of going static.

OSS target: keeps the user's own chrome (Catppuccin-style backgrounds
etc.); only accents follow the wallpaper, plus derived syntax /
semantic / terminal colors. System templates are never touched.
"""
import colorsys
import json
import os
import re
import sys

HOME = os.path.expanduser("~")
FRAG = os.path.join(HOME, ".config", "Code", "User", "matugen-colors.json")
SETTINGS_CODE = os.path.join(HOME, ".config", "Code", "User", "settings.json")
SETTINGS_OSS = os.path.join(HOME, ".config", "Code - OSS", "User",
                            "settings.json")
FALLBACK_PRIMARY = "#B4C5FF"


def strip_jsonc(text):
    """Remove // and /* */ comments plus trailing commas, but only
    outside string literals (paths/flags like "cscript //Nologo" survive)."""
    out = []
    i, n = 0, len(text)
    in_str = False
    esc = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
        elif c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
        elif c == ",":
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "}]":
                i += 1  # trailing comma: drop it
            else:
                out.append(c)
                i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def load_jsonc(path):
    with open(path) as fh:
        text = fh.read()
    return json.loads(strip_jsonc(text))


def split_alpha(value):
    v = value.strip().lstrip("#")
    if len(v) == 8:
        return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4)), v[6:8].upper()
    if len(v) == 6:
        return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4)), ""
    raise ValueError("bad hex: %r" % value)


def to_hex(rgb, alpha=""):
    return "#%02X%02X%02X%s" % (round(rgb[0]), round(rgb[1]),
                                round(rgb[2]), alpha)


def rgb_to_hsv255(rgb):
    h, s, v = colorsys.rgb_to_hsv(rgb[0] / 255.0, rgb[1] / 255.0,
                                  rgb[2] / 255.0)
    return h * 360.0, s, v


def hsv_to_rgb255(h, s, v):
    r, g, b = colorsys.hsv_to_rgb((h % 360.0) / 360.0,
                                  min(1.0, max(0.0, s)),
                                  min(1.0, max(0.0, v)))
    return (r * 255.0, g * 255.0, b * 255.0)


def boost(value, s_floor=0.50, v_floor=0.88):
    """Raise dull colors to vivid ones, preserving hue and alpha."""
    try:
        rgb, alpha = split_alpha(value)
    except (ValueError, AttributeError):
        return value
    h, s, v = rgb_to_hsv255(rgb)
    if v < 0.08:
        return value  # OLED blacks stay black
    if s < 0.05 and v > 0.85:
        return value  # near-whites stay neutral
    return to_hex(hsv_to_rgb255(h, max(s, s_floor), max(v, v_floor)), alpha)


def spin(base_h, offset, s, v):
    return to_hex(hsv_to_rgb255(base_h + offset, s, v))


# Full-replace target accent keys (Code): wallpaper hue, vivid floor.
ACCENT_KEYS = [
    "editorCursor.foreground",
    "activityBar.activeBorder", "activityBar.activeFocusBorder",
    "activityBar.foreground",
    "activityBarBadge.background",
    "tab.activeBorder", "tab.activeBorderTop",
    "panelTitle.activeBorder",
    "button.background", "badge.background",
    "progressBar.background",
    "focusBorder", "contrastActiveBorder",
    "list.highlightForeground",
    "breadcrumb.activeSelectionForeground",
    "editorSuggestWidget.highlightForeground",
    "notificationLink.foreground",
    "terminalCursor.foreground",
    "terminalOverviewRuler.cursorBackground",
    "editor.selectionBackground", "editor.inactiveSelectionBackground",
    "editor.selectionHighlightBackground",
    "editor.wordHighlightBackground", "editor.wordHighlightStrongBackground",
    "terminal.selectionBackground", "terminal.inactiveSelectionBackground",
    "minimapSlider.background", "minimapSlider.hoverBackground",
    "minimapSlider.activeBackground",
    "scrollbarSlider.activeBackground",
    "charts.foreground", "charts.blue",
]


def derive_palette(primary_hex):
    try:
        base_h, _, _ = rgb_to_hsv255(split_alpha(primary_hex)[0])
    except ValueError:
        base_h, _, _ = rgb_to_hsv255(split_alpha(FALLBACK_PRIMARY)[0])
    red = spin(base_h, 330, 0.70, 0.92)
    return {
        "keywords": spin(base_h, 0, 0.70, 0.95),
        "strings": spin(base_h, 150, 0.55, 0.90),
        "types": spin(base_h, 55, 0.80, 0.95),
        "functions": spin(base_h, 205, 0.65, 0.95),
        "numbers": spin(base_h, 315, 0.70, 0.95),
        "tags": spin(base_h, 285, 0.65, 0.92),
        "punctuation": spin(base_h, 180, 0.45, 0.82),
        "storage": spin(base_h, 0, 0.60, 0.80),
        "comments": spin(base_h, 0, 0.18, 0.50),
        "variables": "#F2EFF2",
        "red": red,
        "invalid": "#FF5370",
    }


def build_textmate_rules(p):
    def rule(scope, color=None, style=None):
        settings = {}
        if color:
            settings["foreground"] = color
        if style:
            settings["fontStyle"] = style
        return {"scope": scope, "settings": settings}

    return [
        rule("comment", p["comments"], "italic"),
        rule(["comment.line", "comment.block",
              "comment.block.documentation"], p["comments"], "italic"),
        rule("keyword.control", p["keywords"], "bold"),
        rule("keyword.operator", p["punctuation"]),
        rule("keyword.other", p["tags"]),
        rule("storage", p["storage"]),
        rule("storage.type", p["types"]),
        rule("string.quoted", p["strings"]),
        rule("string.template", p["strings"]),
        rule("string.regexp", p["functions"]),
        rule("string.other", p["strings"]),
        rule("constant.numeric", p["numbers"]),
        rule("constant.language", p["numbers"]),
        rule("constant.character", p["numbers"]),
        rule("constant.other", p["numbers"]),
        rule("entity.name.function", p["functions"]),
        rule("entity.name.class", p["types"]),
        rule("entity.name.type", p["types"]),
        rule("entity.name.tag", p["tags"]),
        rule("entity.other.attribute-name", p["strings"]),
        rule("variable", p["variables"]),
        rule("variable.parameter", p["types"]),
        rule("variable.other.property", p["punctuation"]),
        rule("variable.other.readwrite", p["variables"]),
        rule("punctuation", p["punctuation"]),
        rule("punctuation.definition.tag", p["punctuation"]),
        rule("meta.tag", p["tags"]),
        rule("support.function", p["functions"]),
        rule("support.class", p["types"]),
        rule("support.type", p["types"]),
        rule("markup.heading", p["keywords"], "bold"),
        rule("markup.bold", None, "bold"),
        rule("markup.italic", None, "italic"),
        rule("markup.inline.raw", p["strings"]),
        rule("markup.fenced_code", p["variables"]),
        rule("invalid", p["invalid"]),
    ]


def build_semantic_rules(p):
    return {
        "enabled": True,
        "rules": {
            "namespace": p["types"],
            "class": p["types"],
            "enum": p["types"],
            "interface": p["types"],
            "struct": p["types"],
            "typeParameter": p["types"],
            "type": p["types"],
            "parameter": p["types"],
            "variable": p["variables"],
            "property": p["punctuation"],
            "enumMember": p["numbers"],
            "event": p["functions"],
            "function": p["functions"],
            "method": p["functions"],
            "macro": p["keywords"],
            "keyword": p["keywords"],
            "modifier": p["keywords"],
            "comment": p["comments"],
            "string": p["strings"],
            "number": p["numbers"],
            "regexp": p["functions"],
            "operator": p["punctuation"],
            "decorator": p["tags"],
        },
    }


def build_ansi(p):
    return {
        "ansiBlack": "#131314",
        "ansiRed": p["red"],
        "ansiGreen": p["strings"],
        "ansiYellow": p["types"],
        "ansiBlue": p["keywords"],
        "ansiMagenta": p["tags"],
        "ansiCyan": p["punctuation"],
        "ansiWhite": "#EEFFFF",
        "ansiBrightBlack": "#5A5A64",
        "ansiBrightRed": boost(p["red"], 0.60, 1.0),
        "ansiBrightGreen": boost(p["strings"], 0.50, 1.0),
        "ansiBrightYellow": boost(p["types"], 0.70, 1.0),
        "ansiBrightBlue": boost(p["keywords"], 0.60, 1.0),
        "ansiBrightMagenta": boost(p["tags"], 0.55, 1.0),
        "ansiBrightCyan": boost(p["punctuation"], 0.45, 1.0),
        "ansiBrightWhite": "#FFFFFF",
    }


def apply_derived(current, p):
    """Shared derived layer for both targets."""
    current["editor.tokenColorCustomizations"] = {
        "comments": p["comments"],
        "strings": p["strings"],
        "keywords": p["keywords"],
        "numbers": p["numbers"],
        "types": p["types"],
        "functions": p["functions"],
        "variables": p["variables"],
        "textMateRules": build_textmate_rules(p),
    }
    current["editor.semanticTokenColorCustomizations"] = \
        build_semantic_rules(p)
    current["terminal.integrated.ansiColors"] = build_ansi(p)
    return current


def apply_code(current, fragment, p):
    current.update(fragment)
    cc = current.get("workbench.colorCustomizations", {})
    for key in ACCENT_KEYS:
        if key in cc:
            cc[key] = boost(cc[key])
    cc["gitDecoration.addedResourceForeground"] = p["strings"]
    cc["gitDecoration.modifiedResourceForeground"] = p["keywords"]
    cc["gitDecoration.deletedResourceForeground"] = p["red"]
    cc["gitDecoration.untrackedResourceForeground"] = p["functions"]
    cc["gitDecoration.conflictingResourceForeground"] = p["invalid"]
    cc["gitDecoration.stageModifiedResourceForeground"] = p["types"]
    cc["gitDecoration.stageDeletedResourceForeground"] = p["red"]
    cc["editorGutter.modifiedBackground"] = p["keywords"]
    cc["editorGutter.addedBackground"] = p["strings"]
    cc["editorGutter.deletedBackground"] = p["red"]
    cc["terminalCommandDecoration.successBackground"] = p["strings"]
    cc["terminalCommandDecoration.errorBackground"] = p["red"]
    for i, key in enumerate(["keywords", "tags", "functions",
                             "types", "red", "strings"]):
        cc["editorBracketHighlight.foreground%d" % (i + 1)] = p[key]
    cc["charts.green"] = p["strings"]
    cc["charts.yellow"] = p["types"]
    cc["charts.red"] = p["red"]
    cc["charts.purple"] = p["tags"]
    current["workbench.colorCustomizations"] = cc
    return apply_derived(current, p)


def apply_oss(current, p, cursor):
    """Keep the user's chrome; only accents + code colors follow wallpaper."""
    cc = current.get("workbench.colorCustomizations", {})
    cc["activityBar.foreground"] = p["keywords"]
    cc["tab.activeForeground"] = p["keywords"]
    cc["tab.activeBorder"] = p["keywords"]
    cc["tab.activeBorderTop"] = p["keywords"]
    cc["notificationLink.foreground"] = p["keywords"]
    cc["notificationsInfoIcon.foreground"] = p["keywords"]
    cc["notificationsWarningIcon.foreground"] = p["types"]
    cc["notificationsErrorIcon.foreground"] = p["red"]
    cc["list.activeSelectionBackground"] = p["keywords"]
    cc["list.activeSelectionForeground"] = "#11111b"
    cc["list.inactiveSelectionForeground"] = p["keywords"]
    cc["list.hoverBackground"] = p["keywords"] + "2E"
    cc["list.hoverForeground"] = p["keywords"]
    cc["editor.foreground"] = "#F2EFF2"
    cc["editorCursor.foreground"] = cursor
    cc["editor.selectionBackground"] = p["keywords"] + "4D"
    cc["editor.findMatchBackground"] = "#FFCB6BCC"
    cc["editor.findMatchForeground"] = "#000000"
    cc["editor.findMatchHighlightBackground"] = "#FFCB6B55"
    current["workbench.colorCustomizations"] = cc
    return apply_derived(current, p)


def load_settings(path):
    if not os.path.isfile(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        return {}
    try:
        return load_jsonc(path)
    except json.JSONDecodeError:
        return {}


def save_settings(path, data):
    with open(path, "w") as fh:
        json.dump(data, fh, indent=4)
        fh.write("\n")


def main() -> int:
    if not os.path.isfile(FRAG):
        return 0
    try:
        fragment = load_jsonc(FRAG)
    except (OSError, json.JSONDecodeError):
        return 1

    cc = fragment.get("workbench.colorCustomizations", {})
    primary = cc.get("editorCursor.foreground", FALLBACK_PRIMARY)
    p = derive_palette(primary)
    cursor = boost(primary)

    save_settings(SETTINGS_CODE,
                  apply_code(load_settings(SETTINGS_CODE), fragment, p))
    oss_path = SETTINGS_OSS
    if os.path.isdir(os.path.dirname(oss_path)):
        save_settings(oss_path,
                      apply_oss(load_settings(oss_path), p, cursor))
    return 0


if __name__ == "__main__":
    sys.exit(main())
