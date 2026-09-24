# radar-sdk-ios

## Project Overview

iOS SDK for [Radar](https://radar.com). The SDK is an Xcode project with an Objective-C foundation that is actively being migrated to Swift.

## Language Policy

**All new code must be written in Swift.**

When working in an existing Objective-C file, consider migrating the file to Swift. Prompt the user to confirm when migrating a file to Swift. Do not migrate without asking. 

- New classes, structs, enums, and extensions → Swift only
- New tests → Swift only

**Sanctioned exception — the nightly batch migration.** The scheduled workflow
`.github/workflows/objc-to-swift-nightly.yml` runs the `objc-to-swift` skill (from
`radarlabs/clankers`) in its unattended batch mode: each run asks the skill to choose one
eligible implementation using its candidacy rules, replaces it with a same-basename Swift
implementation while preserving compatibility, deletes the old `.m` from the project, and
opens a PR labeled `swift-migration`. In that context the
"ask the user" requirement is satisfied by human review of that PR — nothing merges without
an explicit approval — and at most one such PR may be open at a time. Interactive sessions
must still ask before migrating.

Large stateful managers may use a temporary Swift seam only when a user explicitly approves
that staged migration. The nightly workflow does not select managers or leave parallel
implementations for ordinary files.

A public class migrated to Swift becomes `@objc(ClassName) @objcMembers public class ClassName`,
with the same name in Swift and Objective-C. Its public API must be `public` so the generated
`RadarSDK-Swift.h` declares it and the class symbol is exported. Keep the API customers compiled
against through the old header: the same names, types, nullability, selectors, and failable
initializers. Add the Swift call shapes to `RadarPublicAPICompatibilityTests` so drift fails to
compile. Replace the class's `@interface` in its handwritten public header with a compatibility
forwarder that imports `<RadarSDK/RadarSDK.h>`. Keep any enums or constants the header declares,
keep the header Public, and list it in `RadarSDK.h`, so existing `#import <RadarSDK/ClassName.h>`
statements keep compiling (see `Include/RadarChain.h`). Other public headers refer to the class
with `@class ClassName;`, because they cannot import `RadarSDK-Swift.h`. Objective-C-only initializers
used inside the SDK stay internal in Swift (`@objc(initWithObject:)`) and are declared in a class
extension in `ClassName+Internal.h`, which imports `RadarSDK-Swift.h` behind `__has_include`
(see `RadarChain+Internal.h`). Public headers must import only public headers; import `+Internal.h`
headers from implementation files. Before handing off the change, run `make ci-build-example`: its
Release build generates an Objective-C consumer for every public class in the handwritten headers
and `RadarSDK-Swift.h`, then links it. Also run `make lint` to verify the CocoaPods header boundary.

## Concurrency

When Swift starts work that can run later on the main actor, prefer `Task { @MainActor in ... }`
over `DispatchQueue.main.async`. Objective-C cannot enforce Swift actor isolation, so it may use
`runOnMainThread` before calling Swift code that owns main-actor state.

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

The Xcode project is `RadarSDK.xcodeproj`. When adding new Swift files, add them to the
project file (`project.pbxproj`) so they are compiled. Remove the corresponding `.m` file
and project references when migrating a class. Keep the public `.h` and its Headers entry,
reduced to a compatibility forwarder; Objective-C consumers reach the class itself through
`RadarSDK-Swift.h`.

## Debugging CI Failures

If you cannot fetch CI failures, prompt the user to copy in the failure logs. This is often helpful with debugging CircleCI failures.
