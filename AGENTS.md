# Repository Guidelines

## Project Structure & Module Organization

- `MacDown/`: macOS app target.
  - `MacDown/Code/`: Objective-C sources.
  - `MacDown/Resources/`, `MacDown/Images.xcassets/`: bundled assets (themes, templates, images).
  - `MacDown/Localization/`: `.xib` and localization resources.
- `macdown-cmd/`: command-line tool target.
- `MacDownTests/`: XCTest suite for the app and shared utilities.
- `Dependency/`: bundled/third-party sources (some are built during the project build).
- `Tools/`: maintenance scripts (release/versioning/style generation).

## Build, Test, and Development Commands

From the repo root:

- `git submodule update --init`: fetch required submodules under `Dependency/`.
- `pod install`: install/update CocoaPods and generate `MacDown.xcworkspace`.
- `make -C Dependency/peg-markdown-highlight`: (re)generate/build the syntax highlighter parser (`pmh_parser.c`).
- `xcodebuild -workspace MacDown.xcworkspace -scheme MacDown build`: build the app.
- `xcodebuild test -workspace MacDown.xcworkspace -scheme MacDown -destination 'platform=macOS'`: run XCTest.

## Coding Style & Naming Conventions

- Objective-C: 4 spaces (no tabs), Allman braces, ~80-column limit, no trailing whitespace.
- Keep UI file edits (`.xib`, `.xcodeproj`) minimal to reduce merge conflicts.
- Tests: place in `MacDownTests/` and name files `*Tests.m`.

## Testing Guidelines

- Use XCTest (tests live in `MacDownTests/`).
- When changing parsing/rendering/preferences/utilities, add/extend focused tests alongside the affected code.

## Commit & Pull Request Guidelines

- Commit messages: imperative subject line, keep it short (≤72 chars); add context in the body when needed.
- Keep changes focused; avoid drive-by formatting churn.
- For UI/visual changes, include screenshots in PR descriptions and link related issues when applicable.

## Notes

- CI (GitHub Actions) expects pods installed and some dependencies generated; local builds may require `pod install` and the `make -C Dependency/peg-markdown-highlight` step if generated sources are missing.
