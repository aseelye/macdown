# Maintainability Audit Backlog

Last updated: 2026-01-13

This document tracks maintainability findings and provides a concrete, verifiable
definition of “fixed” for each item. The goal is that **Critical/High** issues
do not reappear in subsequent audits because (a) the call sites are removed and
(b) regression guards prevent the pattern from returning.

## Scope & assumptions

- Scope: `MacDown/` app + `Tools/` scripts (excluding vendored dependencies unless
  explicitly called out).
- “Use virtual environment at `backend/.venv` for all python work” is not
  applicable: this repo has no `backend/` directory.

## Definition of “fixed”

An item is **Done** only when all are true:

1) The proof-by-inspection call sites/flows are removed or made safe.
2) The underlying *pattern* is prevented from reappearing (tests, invariants,
   or both).
3) Verification steps pass (build/test/analyze + any item-specific checks).

## Status values

- **Not Started**
- **In Progress**
- **Blocked** (note what blocks it)
- **Done**
- **Deferred** (with rationale)

## Global verification (after each completed item)

- Build: `xcodebuild build -workspace MacDown.xcworkspace -scheme MacDown -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
- Tests: `xcodebuild test -workspace MacDown.xcworkspace -scheme MacDown -destination 'platform=macOS'`
- Static analysis: `xcodebuild analyze -workspace MacDown.xcworkspace -scheme MacDown -destination 'platform=macOS'`

## Regression-guard invariants (candidate set)

These should return no matches once the corresponding items are **Done**:

- `rg -n "methodForSelector\\(|impFunc\\(" MacDown/Code/Application`
- `rg -n "context:NULL|context:\\(void \\*\\)0" MacDown/Code/Document/MPDocument+Observers.m`
- `rg -n "\\bsupressesUntitledDocumentOnLaunch\\b|\\bextensionStrikethough\\b" MacDown/Code --glob '!MacDown/Code/Preferences/MPPreferences+Migration.m'`
- `rg -n "\\bvalueForKey:fromQueryItems:\\b" MacDown/Code/Application`
- `rg -n "NSFilenamesPboardType|NSDragPboard" MacDown/Code/View/MPEditorView.m`

Whether these become permanent CI checks will be decided as we close each item.

---

## Tracking table (overview)

| ID | Severity | Title | Status | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| F-001 | Critical | Unsafe toolbar action invocation | Done |  | Safe dispatch + regression tests; local build/test/analyze confirmed. |
| F-002 | High | `MPDocument` god-object decomposition | Done |  | Extracted editor/observer logic into categories; added invariants (LOC + no embedded observer/editor impls). |
| F-003 | High | Observer lifecycle safety (KVO/notifications) | Done |  | KVO uses explicit contexts; teardown is idempotent; regression tests added. |
| F-004 | High | Preference canonicalization + migration | Done |  | Migrated legacy defaults keys; updated bindings/observers; migration regression tests added. |
| F-005 | Med | Editor view state persistence layering | Done |  | Persisted editor behavior moved to preferences API; regression tests added. |
| F-006 | Med | Renderer flags ownership clarity | Not Started |  |  |
| F-007 | Med | Style consistency within touched files | Not Started |  |  |
| F-008 | Med | Confusing selector name `valueForKey:fromQueryItems:` | Not Started |  |  |
| F-009 | Med | URL scheme handler unfinished (line/column) | Not Started |  |  |
| F-010 | Low-Med | Heading IBAction boilerplate duplication | Not Started |  |  |
| F-011 | Low-Med | `MPDocument` imports hoedown/parser concerns | Done |  | `MPDocument.m` no longer imports hoedown; parsing remains behind `MPRenderer`. |
| F-012 | Med | Scroll sync header detection duplication/drift | Not Started |  |  |
| F-013 | Med | `MPUtilities` grab-bag split by domain | Not Started |  |  |
| F-014 | Med | Prism dependency parsing via JS evaluation | Not Started |  |  |
| F-015 | Med | Drag/drop uses legacy pasteboard types | Not Started |  |  |
| F-016 | Low-Med | `MPPreferences` object properties declared `assign` | Not Started |  |  |

---

## Findings (detailed)

### F-001 — Unsafe toolbar action invocation (wrong IMP signature)

- Severity: **Critical**
- Status: **Done**
- Owner:
- Notes: Implemented safe dispatch using `objc_msgSend` + method signature arity,
  added `MacDownTests/MPToolbarControllerTests.m` and
  `Tools/check_maintainability_invariants.sh`. Local `xcodebuild` build/test/analyze
  confirmed.

**Proof (call sites / flow)**
- `MacDown/Code/Application/MPToolbarController.m:106` `-selectedToolbarItemGroupItem:`
- `MacDown/Code/Application/MPToolbarController.m:116` uses `methodForSelector:`
- `MacDown/Code/Application/MPToolbarController.m:117` casts to `void (*)(id)`
- `MacDown/Code/Application/MPToolbarController.m:118` calls `impFunc(document)`
- Many actions are `IBAction` methods with `sender` (e.g. headings in
  `MacDown/Code/Document/MPDocument+Actions.m:126`).

**Problem**
- Calling an Objective-C method with the wrong C function signature is undefined
  behavior. On arm64 this can manifest as mis-dispatch, register corruption, or
  “sporadic” crashes.

**What needs to change**
- Remove manual IMP calling; dispatch actions via a safe mechanism that preserves
  the selector’s expected signature and sender.

**Acceptance criteria**
- No manual IMP cast/call remains for toolbar actions.
- All toolbar actions still work and do not crash under repeated use.
- Add a regression guard:
  - Test and/or invariant that prevents reintroducing manual IMP calling.

**Verification**
- Manual smoke: click every toolbar item/group segment repeatedly; confirm the
  correct action occurs and no crash.
- Automated:
  - Run `Tools/check_maintainability_invariants.sh`
  - Run the test suite and confirm `MPToolbarControllerTests` passes.

---

### F-002 — `MPDocument` is a “god object” (multi-responsibility + oversized)

- Severity: **High**
- Status: **Done**
- Owner:
- Notes: Decomposed `MPDocument.m` into focused categories and added an invariant
  to prevent regressing the file back into a multi-responsibility “god file”.

**Proof**
- `MacDown/Code/Document/MPDocument.m` is now <700 LOC (currently ~472).
- Observer + KVO logic lives in `MacDown/Code/Document/MPDocument+Observers.m`.
- Editor setup + NSTextView/NSSplitView delegate logic lives in
  `MacDown/Code/Document/MPDocument+Editor.m`.
- Renderer data source/delegate + preview scaling/word count live in
  `MacDown/Code/Document/MPDocument+Preview.m`.

**Problem**
- Large surface area makes safe change difficult; responsibilities are tightly
  coupled, raising regression risk.

**What needs to change**
- Further split responsibilities into focused categories/classes with clear
  ownership boundaries (e.g. observers, editor config, printing, persistence,
  rendering wiring).

**Acceptance criteria (stop condition)**
- `MPDocument.m` shrinks to an agreed threshold (target: **< 700 LOC**).
- Subsystems have explicit, testable boundaries (e.g. observer logic is not
  interleaved with editor setup).

**Verification**
- Build/test/analyze pass.
- `Tools/check_maintainability_invariants.sh` passes (enforces F-002).
- Manual: open/save/export/print/scroll-sync/word-count behavior remains correct.

---

### F-003 — Observer lifecycle safety (KVO + notifications teardown)

- Severity: **High**
- Status: **Done**
- Owner:
- Notes:

**Proof (call sites / flow)**
- Registers observers: `MacDown/Code/Document/MPDocument+Observers.m:30`
- Unregisters observers: `MacDown/Code/Document/MPDocument+Observers.m:99`
- Teardown still gated by a flag: `MacDown/Code/Document/MPDocument.m:212`
- KVO handler uses contexts: `MacDown/Code/Document/MPDocument+Observers.m:208`
- Regression coverage (idempotence + preference toggle): `MacDownTests/MPDocumentObserverLifecycleTests.m:47`

**Problem**
- Observer teardown is easy to get wrong; repeated close/re-entrancy can leave
  dangling observers or callbacks into partially torn-down objects.

**What needs to change**
- Make observer registration/teardown idempotent and context-safe; reduce or
  remove reliance on “one-time flags” as the primary safety mechanism.

**Acceptance criteria**
- KVO uses unique contexts and ignores unrelated observations.
- Observer teardown can be called multiple times safely.
- Add a regression test that opens/closes documents repeatedly and toggles
  relevant preferences without KVO exceptions.

**Verification**
- Unit: `MacDownTests/MPDocumentObserverLifecycleTests.m:47` passes.
- Manual: stress open/close documents + toggle editor/render preferences.
- `xcodebuild test` and `xcodebuild analyze` pass.

---

### F-004 — Preference naming debt (misspellings + aliases leak into core logic)

- Severity: **High**
- Status: **Done**
- Owner:
- Notes:

**Proof**
- Legacy defaults keys + compatibility accessors centralized:
  `MacDown/Code/Preferences/MPPreferences+Migration.m:8`
- Canonical keys now stored directly via PAPreferences dynamic properties:
  `MacDown/Code/Preferences/MPPreferences.m:75`
- Document observes only canonical keys:
  `MacDown/Code/Document/MPDocument_Private.h:67`
- NIB bindings use canonical key paths:
  `MacDown/Localization/Base.lproj/MPGeneralPreferencesViewController.xib:100`,
  `MacDown/Localization/Base.lproj/MPMarkdownPreferencesViewController.xib:74`,
  `MacDown/Localization/Base.lproj/MainMenu.xib:447`

**Problem**
- The misspellings increase cognitive load and encourage duplication (multiple
  observed keys for one conceptual setting).

**What needs to change**
- Choose canonical keys and perform a one-time migration from legacy keys.

**Acceptance criteria**
- Code observes and uses only canonical keys in core logic.
- Legacy keys exist only in a dedicated migration shim (or not at all).
- Add a migration regression test (legacy value → canonical value preserved).

**Verification**
- Unit: `MacDownTests/MPPreferencesMigrationTests.m:36` passes.
- `Tools/check_maintainability_invariants.sh` passes (enforces F-004).
- `rg -n "\\bsupressesUntitledDocumentOnLaunch\\b|\\bextensionStrikethough\\b" MacDown/Code --glob '!MacDown/Code/Preferences/MPPreferences+Migration.m'`
  returns no matches.

---

### F-005 — Editor view state persistence via KVO/KVC (leaky layering)

- Severity: **Med**
- Status: **Done**
- Owner:
- Notes:

**Proof (call sites / flow)**
- Editor KVO persists via preferences API (no direct defaults writes):
  `MacDown/Code/Document/MPDocument+Observers.m:223`
- Editor setup applies persisted values via preferences API:
  `MacDown/Code/Document/MPDocument+Editor.m:303`
- Persistence API centralized:
  `MacDown/Code/Preferences/MPPreferences+EditorBehavior.m:10`

**Problem**
- The document layer is persisting view internals using stringly-typed key
  mapping and KVC, which is hard to reason about and brittle to refactors.

**What needs to change**
- Move persistence logic behind a typed API (preferences or dedicated controller)
  and reduce dependence on ad-hoc key mapping.

**Acceptance criteria**
- `MPDocument` no longer writes editor view KVO changes directly to defaults.
- Editor settings persistence remains functional.

**Verification**
- Unit: `MacDownTests/MPPreferencesEditorBehaviorTests.m:50` passes.
- Manual: editor settings persist across launches; no runtime KVC/KVO exceptions.

---

### F-006 — Renderer flags ownership is split between preferences and renderer

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- Preferences provide flags: `MacDown/Code/Preferences/MPPreferences+Hoedown.h:11`
- Renderer stores flags: `MacDown/Code/Document/MPRenderer.h:24`
- Document syncs flags and triggers parse/render: `MacDown/Code/Document/MPDocument+Observers.m:80`
  (initial sync: `MacDown/Code/Document/MPDocument.m:156`)

**Problem**
- Unclear ownership increases risk of stale state and redundant updates.

**What needs to change**
- Define a single source of truth and a single configuration pathway.

**Acceptance criteria**
- Renderer configuration is explicit and centralized (no ad-hoc syncing).
- Toggling render-related preferences triggers the minimal correct work.

**Verification**
- Toggle markdown/render preferences; confirm expected parse/render behavior.

---

### F-007 — Style inconsistencies in touched files (Allman vs K&R)

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- K&R `@synchronized`: `MacDown/Code/View/MPEditorView.m:37`
- K&R `if` blocks: `MacDown/Code/Application/MPMainController.m:118`
- K&R `@synchronized`: `MacDown/Code/Document/MPDocument+Observers.m:125`

**Problem**
- Inconsistent styling increases diff noise and slows review/refactor work.

**What needs to change**
- Normalize style within files we touch for higher-severity fixes (avoid
  drive-by reformatting elsewhere).

**Acceptance criteria**
- Touched files follow repo guideline (Allman braces, 4 spaces, no trailing ws).

**Verification**
- Diff review and `git diff --check` clean.

---

### F-008 — Confusing selector name `valueForKey:fromQueryItems:`

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- Method: `MacDown/Code/Application/MPMainController.m:166`
- Use: `MacDown/Code/Application/MPMainController.m:138`

**Problem**
- Resembles KVC `valueForKey:` and is easy to misread.

**What needs to change**
- Rename to a query-specific name and update call sites.

**Acceptance criteria**
- No `valueForKey:fromQueryItems:` remains.

**Verification**
- `rg -n "\\bvalueForKey:fromQueryItems:\\b" MacDown/Code/Application` returns no matches.

---

### F-009 — URL scheme handler has unfinished feature (line/column ignored)

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- FIXME and unused parameters: `MacDown/Code/Application/MPMainController.m:142`–`MacDown/Code/Application/MPMainController.m:148`

**Problem**
- Handler claims support for line/column but doesn’t implement it; adds noisy
  logging and unclear intent.

**What needs to change**
- Either implement cursor positioning or remove parameters/logging and document
  supported behavior.

**Acceptance criteria**
- No FIXME remains; behavior is clearly defined and tested manually.

**Verification**
- Manual: open `x-macdown://open?...` URLs and confirm expected behavior.

---

### F-010 — Heading IBAction boilerplate duplication

- Severity: **Low–Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- Repetitive actions: `MacDown/Code/Document/MPDocument+Actions.m:126`–`MacDown/Code/Document/MPDocument+Actions.m:155`

**Problem**
- Duplication increases maintenance overhead for action naming/wiring changes.

**What needs to change**
- Optional: consolidate using sender tags or shared helper. If avoiding `.xib`
  churn is more important, explicitly defer/accept.

**Acceptance criteria**
- Either consolidated (with minimal UI churn) OR explicitly marked as intentional
  duplication to avoid UI merge conflicts.

**Verification**
- Manual: menu/toolbar heading actions still work.

---

### F-011 — `MPDocument` imports renderer internals (hoedown concerns)

- Severity: **Low–Med**
- Status: **Done**
- Owner:
- Notes: `MPDocument.m` no longer imports hoedown headers; parsing remains in
  `MPRenderer`/preferences categories.

**Proof**
- Parser imports now live in `MacDown/Code/Document/MPRenderer.m:11`.

**Problem**
- Layering violation: document coordinator should not depend on parser details.

**What needs to change**
- Remove unnecessary hoedown imports from `MPDocument.m` and keep parsing behind
  renderer and preferences category.

**Acceptance criteria**
- `MPDocument.m` does not import hoedown unless strictly necessary (documented).

**Verification**
- Build passes; rendering behavior unchanged.

---

### F-012 — Scroll sync header detection duplicated across JS and regexes

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- Web query: `MacDown/Code/Document/MPScrollSyncController.m:46`–`MacDown/Code/Document/MPScrollSyncController.m:52`
- Regex detection: `MacDown/Code/Document/MPScrollSyncController.m:65`–`MacDown/Code/Document/MPScrollSyncController.m:102`

**Problem**
- Drift risk: editor and preview may disagree on header anchors.

**What needs to change**
- Define and share a single header detection “spec” (or explicitly document
  divergence and test representative cases).

**Acceptance criteria**
- Shared spec exists or divergence is documented + covered by tests/smoke steps.

**Verification**
- Manual: scroll sync works for ATX, Setext, and image-only lines.

---

### F-013 — `MPUtilities` is a grab-bag; split by domain

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- Mixed API surface: `MacDown/Code/Utility/MPUtilities.h:18`–`MacDown/Code/Utility/MPUtilities.h:48`
- JS eval utility: `MacDown/Code/Utility/MPUtilities.m:189`–`MacDown/Code/Utility/MPUtilities.m:236`

**Problem**
- High coupling and unclear ownership boundaries; more difficult refactors.

**What needs to change**
- Split into domain-specific modules (filesystem, serialization, JS, temp files).

**Acceptance criteria**
- `MPUtilities.h` shrinks and domain helpers are moved behind focused headers.

**Verification**
- Build/test/analyze pass; no new cycles in imports.

---

### F-014 — Prism dependencies derived by evaluating JS at runtime (fragile)

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- Reads and evaluates Prism JS: `MacDown/Code/Document/MPRenderer.m:295`–`MacDown/Code/Document/MPRenderer.m:301`
- JS evaluation implementation: `MacDown/Code/Utility/MPUtilities.m:189`–`MacDown/Code/Utility/MPUtilities.m:236`

**Problem**
- Runtime evaluation of arbitrary JS is fragile; breaks when Prism file format
  changes; difficult to test.

**What needs to change**
- Prefer build-generated JSON or a safer parsing strategy behind a stable API.

**Acceptance criteria**
- Renderer no longer depends on “evaluate arbitrary JS file contents” at runtime
  for Prism dependency resolution.

**Verification**
- Manual: enable syntax highlighting and verify multiple languages (including ones
  with dependencies) still work.

---

### F-015 — Drag/drop uses legacy pasteboard types

- Severity: **Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- `MacDown/Code/View/MPEditorView.m:44` uses `NSDragPboard`
- `MacDown/Code/View/MPEditorView.m:68` uses `NSFilenamesPboardType`

**Problem**
- Legacy pasteboard APIs complicate modernization and may degrade compatibility.

**What needs to change**
- Use modern pasteboard types (file URLs) and narrow handling to supported types.

**Acceptance criteria**
- No `NSDragPboard` / `NSFilenamesPboardType` remains in drag/drop logic.

**Verification**
- Manual: drag a JPEG into editor → expected markdown inserted.

---

### F-016 — `MPPreferences` object properties declared `assign`

- Severity: **Low–Med**
- Status: **Not Started**
- Owner:
- Notes:

**Proof**
- `MacDown/Code/Preferences/MPPreferences.h:17` / `:18` use `assign` for `NSString *`
- Many other object types are also `assign` (e.g. dict/string/style names).

**Problem**
- Misleading API contract under ARC; future refactors can become unsafe.

**What needs to change**
- Update object-typed properties to `copy` or `strong` as appropriate.

**Acceptance criteria**
- All object properties in `MPPreferences.h` have appropriate ownership semantics.

**Verification**
- Build/test/analyze pass; preferences persist as expected.
