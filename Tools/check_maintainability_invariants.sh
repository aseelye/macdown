#!/bin/sh
set -eu

# Usage: `Tools/check_maintainability_invariants.sh`
# This script currently takes no arguments; `$1/$2/$3` are parameters for the
# internal `check_no_matches` helper function.

cd "$(dirname "$0")/.."

fail=0

check_no_matches() {
    description="$1"
    pattern="$2"
    path="$3"

    if command -v rg >/dev/null 2>&1; then
        if rg -n "$pattern" "$path" >/dev/null; then
            echo "FAIL: $description"
            rg -n "$pattern" "$path" || true
            fail=1
        fi
    else
        if grep -R -n -E "$pattern" "$path" >/dev/null 2>&1; then
            echo "FAIL: $description"
            grep -R -n -E "$pattern" "$path" || true
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

if [ "$fail" -ne 0 ]; then
    exit 1
fi

echo "OK: maintainability invariants"
