# radar-sdk-ios

## Project Overview

iOS SDK for [Radar](https://radar.com). The SDK is an Xcode project with an Objective-C foundation that is actively being migrated to Swift.

## Language Policy

**All new code must be written in Swift.**

When working in an existing Objective-C file, consider migrating the file to Swift. Prompt the user to confirm when migrating a file to Swift. Do not migrate without asking. 

- New classes, structs, enums, and extensions → Swift only
- New tests → Swift only

## Build & Test

```bash
# Build
make build

# Run tests
make test

# Run tests (pretty output, skips specific unit test bundles: InAppMessageTest, RadarSettingsTest, RadarNotificationHelperTest)
make test-pretty

# Format (clang-format for ObjC, swift-format for Swift)
make format

# Lint Swift (SwiftLint, gated by .swiftlint-baseline.json — only new violations fail)
make lint-swift
```

**Always run `make lint-swift` before committing or pushing any Swift change** CI fails on
new violations. It only lints changed files against the baseline, so it's fast — there's no reason to skip it.

`.swiftlint-baseline.json` is written by SwiftLint as one minified line. A git clean filter
(`.gitattributes` + `git config filter.swiftlint-baseline.clean "jq -S ."`) pretty-prints it
on stage so its diffs stay readable. Run `make bootstrap` once to configure the filter.

Tests use `xcodebuild` targeting an iPhone simulator. The default destination is `iPhone 17, OS=26.2`. Override with:

```bash
make test DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.5"
make build SDK="iphonesimulator" DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.5"
```

## Formatting

`make format` reformats the **entire** repo (`clang_format.sh` + `swift-format -i -r RadarSDK RadarSDKTests`), not just your changed files. Since formatting is not enforced repo-wide, running it on a scoped change produces a large unrelated diff. For a focused change, format only the files you touched (e.g. `swift-format -i <path>`) rather than running `make format`.

## Project Structure

```
RadarSDK/           # SDK source — mix of .swift and .m/.h (ObjC being migrated)
RadarSDKTests/      # Unit tests
Example/            # Example app
RadarSDKMotion/     # Motion extension
RadarSDKFraud/      # Fraud detection extension (git submodule)
RadarSDKIndoors/    # Indoors extension (git submodule)
```

Run `git submodule update --init --recursive` to initialize submodules.

## Xcode Project

The Xcode project is `RadarSDK.xcodeproj`. When adding new Swift files, add them to the project file (`project.pbxproj`) so they are compiled. Remove the corresponding `.m` and `.h` files from the project when migrating a class.

## Debugging CI Failures

If you cannot fetch CI failures, prompt the user to copy in the failure logs. This is often helpful with debugging CircleCI failures.