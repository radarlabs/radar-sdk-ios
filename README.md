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

## Switching environments (production, staging, local server)

In the Example app, open the Tests tab, tap the settings gear, and pick an environment under **Environment**: Production, Staging, or Local. Each environment keeps its own publishable key. **Apply & quit** saves the choice; reopen the app to use it.

- If no key is set, or the key isn't valid on the selected environment, a red strip across the top of the app says so. On launch the app checks the key against both production and staging to find out. Settings → Environment always shows the active environment, host, key, and key-check result.
- Errors that usually mean a wrong host or key (network, unauthorized, publishable key) include the environment, host, key, and key-check result in the Debug console.
- **Local** points both the SDK's API and verified hosts at your dev server:
  - **Simulator:** `http://localhost:8081` — the simulator reaches your Mac over loopback.
  - **Device:** `http://192.168.1.10:8081` — your server's LAN IP.

The Example `Info.plist` sets `NSAllowsArbitraryLoads` so plaintext HTTP to any dev-server IP works without a per-developer ATS exception; certificate pinning for the Radar verified hosts is preserved via `NSPinnedDomains`.

> **Note:** `NSAllowsArbitraryLoads` disables App Transport Security app-wide and exists here only to make local development convenient in this sample app. Do not copy it into a production app — it lets your app make insecure cleartext connections. Real apps should keep ATS enabled and add a narrowly-scoped `NSExceptionDomains` entry only if a specific host truly requires it.

## Examples

See a Swift example app in `Example/`.

To run the example app, clone this repository, build the app, and set your publishable API key in the Tests tab under Settings → Environment. You can also set default keys in `AppDelegate.swift` (`DEFAULT_PUBLISHABLE_KEY` for production, `DEFAULT_STAGING_PUBLISHABLE_KEY` for staging).

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
