# Contributing to the Radar SDK for iOS

Thanks for your interest in contributing! 💙 This guide covers how to build, test, and submit changes. For questions about your Radar integration (rather than the SDK source), email [support@radar.com](mailto:support@radar.com).

## Ways to contribute

- **Report a bug or request a feature** — open a [GitHub issue](https://github.com/radarlabs/radar-sdk-ios/issues). The issue template asks for a summary, repro steps, and your OS / SDK version.
- **Submit a fix or improvement** — open a pull request (see below).

## Getting started

1. Fork and clone the repo, then initialize submodules: `git submodule update --init --recursive`.
2. Set up your environment: `make bootstrap` (installs SwiftLint, swift-format, clang-format, and other tooling; it calls `sudo` to install some gems).
3. Build the SDK: `make build`
4. (Optional) Run the example app: add your **publishable** API key in the example app's `AppDelegate.swift`, then open and run `Example/Example.xcodeproj`.

> Set up the API-key pre-commit filter first to avoid leaking a real key from the example app:
> ```
> git config filter.radar-keys.clean hooks/clean-filter
> git config filter.radar-keys.smudge hooks/smudge-filter
> ```

## Build, test, and lint

All commands run from the repo root:

| Command | What it does |
| --- | --- |
| `make build` | Build the SDK |
| `make test` | Run the unit test suite (XCTest + Swift Testing) |
| `make lint-swift` | SwiftLint style check on changed Swift files (baseline-gated) |
| `make format-check` | Verify changed Swift files match `swift-format` output |
| `make format` | Auto-format Swift (`swift-format`) and Objective-C (`clang-format`) |

Tests run via `xcodebuild` against an iPhone simulator. Override the destination if needed, e.g. `make test DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.5"`.

CI runs SwiftLint, the swift-format check, a build + analyze, and the test suites on every PR. Run these locally before opening a PR to get a green build faster.

## Code style

- **New code must be Swift.** The SDK has an Objective-C foundation that is actively being migrated to Swift — new classes, structs, enums, extensions, and tests should be Swift only. Don't migrate an existing Objective-C file without checking with the Radar team first (the one exception is the nightly `objc-to-swift-nightly` workflow, whose migration PRs are checked with the team at review time).
- Swift is linted with SwiftLint and formatted with `swift-format`; Objective-C is formatted with `clang-format`. Config lives in `.swiftlint.yml`, `.swift-format`, and `.clang-format`.
- When you add a Swift file, add it to `RadarSDK.xcodeproj` (`project.pbxproj`) so it gets compiled. When migrating a class, remove the old `.m`/`.h` from the project.

### SwiftLint baseline

SwiftLint uses a baseline (`.swiftlint-baseline.json`) so only **new** violations fail CI. Please:

- **Only fix violations on lines you changed.** Don't run formatters across untouched files — they produce a sprawling, unreviewable diff.
- The baseline is stored as one minified line; a git clean filter pretty-prints it on stage so diffs stay readable (configured by `make bootstrap`). If you clean up a file, let the baseline shrink accordingly rather than re-adding stale entries.

## Testing

- Frameworks: XCTest, plus Swift Testing for newer suites. Tests live in `RadarSDKTests/`.
- A few Swift Testing suites (`InAppMessageTest`, `RadarSettingsTest`, `RadarNotificationHelperTest`) run as a separate CI step; `make test` covers the full set locally.
- Prefer extending existing test helpers and mocks over introducing new patterns. Add or update tests for any behavior change.

## Public API & breaking changes

- The public API entry point is the `Radar` class (`RadarSDK/Include/Radar.h`). When adding a public API, surface it there and keep the implementation in the appropriate manager — `Radar` should stay a thin facade.
- For any **breaking change**, add an entry to `MIGRATION.md` and bump the version with `./set-version.sh <VERSION>` (updates the podspecs, `Package.swift`, the Xcode project, and `RadarUtils`).
- Update the README / public docs when you change the public API.

## Opening a pull request

1. Branch off `master` and push to your fork.
2. Open a PR against `master`. The PR template will prompt you for a summary, type of change, manual test steps, and a checklist — please fill it in.
   - **Radar internal contributors:** link the Linear ticket (e.g. `FENCE-1234`).
   - **External contributors:** delete the internal-only section and link any related GitHub issue (e.g. `Closes #123`).
3. Make sure CI is green (SwiftLint, swift-format, build + analyze, tests).
4. A Radar team member will review your PR.

## License

By contributing, you agree that your contributions are licensed under the repository's [Apache License 2.0](LICENSE). No CLA is required.
