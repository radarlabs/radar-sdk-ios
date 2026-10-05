# radar-sdk-ios

## Project Overview

iOS SDK for [Radar](https://radar.com). The SDK is an Xcode project with an Objective-C foundation that is actively being migrated to Swift.

## Public Repository: No Customer Information

This repository is public. Commits, branch names, PR titles and descriptions, code, comments,
tests, and docs are visible to anyone. Linear tickets and Slack threads often include customer
details. Never copy those into anything in this repo.

Never include:
- Customer, prospect, or partner names, or venue/app names that identify them
- Deal sizes, pricing, contract terms, launch dates, or certification/compliance timelines
- Customer-specific use cases (e.g. "their checkout flow") or quotes from customer conversations
- Links to Slack threads, customer logs, or other internal-only material

Instead, describe the problem and the fix in product terms (e.g. "`trackVerified(beacons: true)`
waits up to 5s in large venues"), and link the Linear ticket by ID (e.g. `FENCE-1234`) for
internal context. Before creating a branch, commit, or PR, check the title, message, and body
for customer details. If a suggested branch name from a ticket contains a customer name, rename it.

## Language Policy

**All new code must be written in Swift.**

When working in an existing Objective-C file, consider migrating the file to Swift. Prompt the user to confirm when migrating a file to Swift. Do not migrate without asking. 

- New classes, structs, enums, and extensions → Swift only
- New tests → Swift only

**Objective-C-only files.** A file with an `// objc-only:` comment must stay in Objective-C;
the comment gives the reason. Do not offer to migrate it interactively, and the nightly batch
migration must never select it.

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

### Public classes implemented in Swift

Every public type is declared once. Types implemented in Swift are declared in Swift, and the
compiler generates their Objective-C interface in `RadarSDK-Swift.h`. See `RadarChain.swift`,
`Include/RadarChain.h`, and `RadarChain+Internal.h` for the full pattern.

1. **Declaration:** `@objc(ClassName) @objcMembers public final class ClassName: NSObject`, with the
   same name in Swift and Objective-C. Models the SDK returns are `final` and have no public `init()`.
   Keep an internal `override init()` that builds an empty value, so an Objective-C `-init` doesn't
   trap. Option types customers create, such as `RadarTripOptions`, keep their public initializers
   and aren't `final`. Use `@objc(selector:)` on a member only when it needs a custom selector.
2. **Public surface:** exactly what the class's old header declared, spelled the way Swift imported
   it: the same names, types, nullability, selectors, and failable initializers. For example,
   `dictionaryValue()` returns `[AnyHashable: Any]`. Everything else is `internal`.
3. **Docs:** move the header's `/** */` comments onto the Swift members as `///` comments. They
   become the customer docs in Quick Help and `RadarSDK-Swift.h`. Keep maintainer notes as `//`.
   Put a `swiftlint:disable:this` comment at the end of the declaration line, so it doesn't
   separate the `///` doc from its declaration.
4. **Headers:** reduce the class's public header to a one-line forwarder that imports
   `<RadarSDK/RadarSDK.h>`, and list it in the umbrella after `RadarSDK-Swift.h` (see
   `Include/RadarChain.h`). No SDK header may import a forwarder, because that creates an import
   cycle through the umbrella. If the header also declares enums that other headers use (like
   `RadarTrip.h`), keep only the enums and don't add the umbrella import. Other public headers
   refer to the class with `@class ClassName;`, because they can't import `RadarSDK-Swift.h`.
   So an Objective-C file that imports only such a header, like `RadarUser.h`, can't use the
   class's members. Customers import the whole SDK. That limit goes away as the Objective-C models
   that reference Swift classes (`RadarUser`, `RadarEvent`, `RadarPlace`, `RadarGeofence`,
   `RadarAddress`, `RadarBeacon`, `RadarRoutes`, `RadarRouteMatrix`) move to Swift. `Radar.h`
   stays handwritten and moves last.
5. **Internal Objective-C access:** Objective-C-only initializers used inside the SDK stay
   internal in Swift (`@objc(initWithObject:)`). Declare them in a class extension in
   `ClassName+Internal.h`, which imports `RadarSDK-Swift.h` behind `__has_include`. An internal
   Swift class that Objective-C code uses isn't in `RadarSDK-Swift.h`, so give it an explicit
   `@objc(ClassName)` (otherwise its runtime name is mangled and won't link) and declare its
   Objective-C interface in `ClassName+Internal.h`, like `RadarInAppMessageManager+Internal.h`.
   The `+Internal.h` suffix matters: the podspec makes every other header in `RadarSDK/` public.
   Public headers import only public headers; import `+Internal.h` headers from implementation
   files.
6. **Verify:** run `make ci-build-example`. Its Release build links an Objective-C consumer of
   every public class in the handwritten headers and `RadarSDK-Swift.h`, and compiles the same
   consumer as non-modular Objective-C++ through the umbrella. Also run `make lint` to check the
   CocoaPods header boundary.

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
reduced to a compatibility forwarder (see "Public classes implemented in Swift" above).
Objective-C consumers reach the class itself through `RadarSDK-Swift.h`.

## Debugging CI Failures

If you cannot fetch CI failures, prompt the user to copy in the failure logs. This is often helpful with debugging CircleCI failures.
