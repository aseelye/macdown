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

# Add checks here only after the corresponding finding is marked Done in
# `docs/maintainability-audit.md`.
check_no_matches \
    "F-001: no unsafe IMP dispatch in MPToolbarController" \
    "methodForSelector\\(|impFunc\\(" \
    "MacDown/Code/Application/MPToolbarController.m"

if [ "$fail" -ne 0 ]; then
    exit 1
fi

echo "OK: maintainability invariants"
