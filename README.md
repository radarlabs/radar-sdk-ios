![Radar](https://raw.githubusercontent.com/radarlabs/radar-sdk-ios/master/logo.png)

[![CocoaPods](https://img.shields.io/cocoapods/v/RadarSDK.svg)](https://cocoapods.org/pods/RadarSDK)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)

[Radar](https://radar.com) is the leading geofencing and location tracking platform.

The Radar SDK abstracts away cross-platform differences between location services, allowing you to add geofencing, location tracking, trip tracking, geocoding, and search to your apps with just a few lines of code.

## Documentation

See the Radar overview documentation [here](https://radar.com/documentation). See the Radar SDK documentation [here](https://radar.com/documentation/sdk).

You can also see a detailed SDK reference [here](https://radarlabs.github.io/radar-sdk-ios/Classes/Radar.html).

## Migrating

See migration guides in `MIGRATION.md`.

## Development

Run `make bootstrap` to set up your environment for development and allow you to use the other `make` commands. It will call `sudo` to install some gems.

## Targeting a local server

To point the SDK at a dev server during development, set `TARGET_HOST` at the top of `AppDelegate` in `Example/Example/AppDelegate.swift` to its address:

- **Simulator:** `http://localhost:8081` — the simulator reaches your Mac over loopback.
- **Device:** `http://192.168.1.10:8081` — your server's LAN IP.

The Example app writes it to the SDK's API and verified hosts on launch; leave it blank to use the SDK defaults. The Example `Info.plist` sets `NSAllowsArbitraryLoads` so plaintext HTTP to any dev-server IP works without a per-developer ATS exception; certificate pinning for the Radar verified hosts is preserved via `NSPinnedDomains`.

## Examples

See a Swift example app in `Example/`.

To run the example app, clone this repository, add your publishable API key in `AppDelegate.swift`, and build the app.

Setup Radar key check pre-commit hook to prevent accidental key leak when working with the Example app.
```
git config filter.radar-keys.clean hooks/clean-filter
git config filter.radar-keys.smudge hooks/smudge-filter
```

## SPM

If you are using Swift Package Manager to manage your project's dependency, use this [SPM specific repository](https://github.com/radarlabs/radar-sdk-ios-spm) instead   

## Contributing

Interested in contributing? See [CONTRIBUTING.md](CONTRIBUTING.md) for how to build, test, and submit changes.

## Support

Have questions? We're here to help! Email us at [support@radar.com](mailto:support@radar.com).
