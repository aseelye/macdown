# Repository Guidelines

## Project Structure & Module Organization

- `MacDown/`: macOS app target.
  - `MacDown/Code/`: Objective-C source.
  - `MacDown/Resources/`, `MacDown/Images.xcassets/`: bundled assets (themes, templates, images).
  - `MacDown/Localization/`: `.xib` and localization resources.
- `macdown-cmd/`: command-line tool target.
- `MacDownTests/`: XCTest suite for the app and shared utilities.
- `Dependency/`: submodules/third-party sources built as part of the project (e.g., `Dependency/peg-markdown-highlight`).
- `Tools/`: maintenance scripts (release automation, versioning, CSS generator).
- `assets/`: README/media assets.

## Build, Test, and Development Commands

From the repo root:

- `git submodule update --init`: fetch required submodules under `Dependency/`.
- `bundle install`: install pinned Ruby tooling (notably CocoaPods) from `Gemfile.lock`.
- `bundle exec pod install`: install/update Pods and generate the workspace.
- `make -C Dependency/peg-markdown-highlight`: build the syntax highlighter dependency.
- Open `MacDown.xcworkspace` in Xcode to build and run.

Command-line builds:

- `xcodebuild -workspace MacDown.xcworkspace -scheme MacDown build`
- `xcodebuild test -workspace MacDown.xcworkspace -scheme MacDown -destination 'platform=macOS'`

## Coding Style & Naming Conventions

- Objective-C formatting follows `CONTRIBUTING.md`: 4 spaces (no tabs), Allman braces, 80-column limit, and no trailing whitespace.
- Prefer clear, descriptive names; keep UI file edits (`.xib`, `.xcodeproj`) minimal to reduce merge conflicts.

## Testing Guidelines

- Tests live in `MacDownTests/` and run via Xcode (Product → Test) or `xcodebuild test`.
- Add/extend tests when changing parsing/rendering, preferences, or utility code; keep test files named `*Tests.m`.

## Commit & Pull Request Guidelines

- Commit messages: imperative subject line, keep it short (≤72 chars); add context in the body when needed.
- Before opening a PR: rebase on `master` and keep changes focused. Include a clear description, link related issues, and add screenshots for UI/visual changes.

