# radar-sdk-ios

## Project Overview

iOS SDK for [Radar](https://radar.com). The SDK is an Xcode project with an Objective-C foundation that is actively being migrated to Swift.

## Language Policy

**All new code must be written in Swift.**

When working in an existing Objective-C file, migrate it to Swift if the scope of changes is reasonable. Prefer incremental migration over large rewrites, but do not add new `.m` or `.h` files.

- New classes, structs, enums, and extensions → Swift only
- New tests → Swift only
- Existing Objective-C files → migrate to Swift when touching them for non-trivial changes

## Build & Test

```bash
# Build
make build

# Run tests
make test

# Run tests (pretty output, skips specific unit test bundles: InAppMessageTest, RadarSettingsTest, RadarNotificationHelperTest)
make test-pretty

# Format (clang-format for any remaining ObjC)
make format
```

Tests use `xcodebuild` targeting an iPhone simulator. See `Makefile` for the default SDK and destination.

## Project Structure

```
RadarSDK/           # SDK source — mix of .swift and .m/.h (ObjC being migrated)
RadarSDKTests/      # Unit tests
Example/            # Example app
RadarSDKMotion/     # Motion extension
RadarSDKFraud/      # Fraud detection extension
```

## Xcode Project

The Xcode project is `RadarSDK.xcodeproj`. When adding new Swift files, add them to the project file (`project.pbxproj`) so they are compiled. Remove the corresponding `.m` and `.h` files from the project when migrating a class.
