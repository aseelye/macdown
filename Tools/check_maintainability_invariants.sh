#!/bin/sh
set -eu

# Usage: `Tools/check_maintainability_invariants.sh`
# This script currently takes no arguments; `$1/$2/$3/$4` are parameters for the
# internal helper functions.

cd "$(dirname "$0")/.."

fail=0

check_no_matches() {
    description="$1"
    pattern="$2"
    path="$3"

    if command -v rg >/dev/null 2>&1; then
        if rg -n -- "$pattern" "$path" >/dev/null; then
            echo "FAIL: $description"
            rg -n -- "$pattern" "$path" || true
            fail=1
        fi
    else
        if grep -R -n -E -- "$pattern" "$path" >/dev/null 2>&1; then
            echo "FAIL: $description"
            grep -R -n -E -- "$pattern" "$path" || true
            fail=1
        fi
    fi
}

check_no_matches_excluding() {
    description="$1"
    pattern="$2"
    path="$3"
    excluded_path="$4"

    if command -v rg >/dev/null 2>&1; then
        excluded_tail="$excluded_path"
        if [ "${excluded_path#"$path"/}" != "$excluded_path" ]; then
            excluded_tail="${excluded_path#"$path"/}"
        fi

        if rg -n \
            --glob "!$excluded_path" \
            --glob "!**/$excluded_tail" \
            -- "$pattern" "$path" \
            >/dev/null; then
            echo "FAIL: $description"
            rg -n \
                --glob "!$excluded_path" \
                --glob "!**/$excluded_tail" \
                -- "$pattern" "$path" \
                || true
            fail=1
        fi
    else
        matches="$(grep -R -n -E -- "$pattern" "$path" 2>/dev/null || true)"
        filtered="$(printf "%s\n" "$matches" | grep -v "^$excluded_path:" || true)"
        if [ -n "$filtered" ]; then
            echo "FAIL: $description"
            printf "%s\n" "$filtered"
            fail=1
        fi
    fi
}

check_max_lines() {
    description="$1"
    max_lines="$2"
    path="$3"

    if [ ! -f "$path" ]; then
        echo "FAIL: $description"
        echo "Missing file: $path"
        fail=1
        return
    fi

    lines="$(wc -l < "$path" | tr -d ' ')"
    if [ "$lines" -gt "$max_lines" ]; then
        echo "FAIL: $description"
        echo "$path has $lines lines (max $max_lines)"
        fail=1
    fi
}

# Add checks here only after the corresponding finding is marked Done in
# `docs/maintainability-audit.md`.
check_no_matches \
    "F-001: no unsafe IMP dispatch in MPToolbarController" \
    "methodForSelector\\(|impFunc\\(" \
    "MacDown/Code/Application/MPToolbarController.m"

check_max_lines \
    "F-002: MPDocument.m stays under 700 lines" \
    700 \
    "MacDown/Code/Document/MPDocument.m"

check_no_matches \
    "F-002: MPDocument.m contains no observer/editor implementations" \
    "^- \\(void\\)(registerObservers|unregisterObservers|editorTextDidChange:|renderingPreferencesDidChange|observeValueForKeyPath:|setupEditor:|adjustEditorInsets|redrawDivider|updateWordCount|scaleWebview)" \
    "MacDown/Code/Document/MPDocument.m"

check_no_matches \
    "F-011: MPDocument.m does not import hoedown" \
    "hoedown/html\\.h|hoedown_html_patch\\.h" \
    "MacDown/Code/Document/MPDocument.m"

check_no_matches \
    "F-003: MPDocument KVO does not use NULL contexts" \
    "context:NULL|context:\\(void \\*\\)0" \
    "MacDown/Code/Document/MPDocument+Observers.m"

check_no_matches \
    "F-003: MPDocument KVO does not branch on observed object identity" \
    "object == self\\.(editor|preferences)" \
    "MacDown/Code/Document/MPDocument+Observers.m"

check_no_matches \
    "F-003: MPDocument KVO removals include explicit context" \
    "removeObserver:self forKeyPath:key\\];" \
    "MacDown/Code/Document/MPDocument+Observers.m"

check_no_matches_excluding \
    "F-004: legacy preference keys only in migration shim" \
    "supressesUntitledDocumentOnLaunch|extensionStrikethough" \
    "MacDown/Code" \
    "MacDown/Code/Preferences/MPPreferences+Migration.m"

check_no_matches \
    "F-004: NIB bindings do not use legacy preference keys" \
    "supressesUntitledDocumentOnLaunch|extensionStrikethough" \
    "MacDown/Localization/Base.lproj"

check_no_matches \
    "F-005: MPDocument editor KVO does not touch NSUserDefaults" \
    "NSUserDefaults|standardUserDefaults" \
    "MacDown/Code/Document/MPDocument+Observers.m"

check_no_matches \
    "F-005: MPDocument editor setup does not touch NSUserDefaults" \
    "NSUserDefaults|standardUserDefaults" \
    "MacDown/Code/Document/MPDocument+Editor.m"

check_no_matches \
    "F-006: MPRenderer has no rendererFlags property" \
    "@property \\(nonatomic\\) int rendererFlags;" \
    "MacDown/Code/Document/MPRenderer.h"

check_no_matches \
    "F-006: document code does not sync renderer.rendererFlags" \
    "(self\\.)?renderer\\.rendererFlags" \
    "MacDown/Code/Document"

check_no_matches \
    "F-007: MPEditorView uses Allman @synchronized" \
    "^\\s*@synchronized\\(self\\) \\{" \
    "MacDown/Code/View/MPEditorView.m"

check_no_matches \
    "F-007: MPMainController uses Allman if braces" \
    "^\\s*if\\s*\\([^\\n]*\\)\\s*\\{" \
    "MacDown/Code/Application/MPMainController.m"

check_no_matches \
    "F-007: MPMainController uses Allman else braces" \
    "^\\s*\\}\\s*else\\s*\\{" \
    "MacDown/Code/Application/MPMainController.m"

check_no_matches \
    "F-007: MPMainController openPendingPipedContent uses Allman braces" \
    "- \\(void\\)openPendingPipedContent \\{" \
    "MacDown/Code/Application/MPMainController.m"

if [ "$fail" -ne 0 ]; then
    exit 1
fi

echo "OK: maintainability invariants"
