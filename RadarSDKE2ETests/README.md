# iOS SDK end-to-end tests

These tests call `Radar.trackOnce` on an iOS simulator and check the track request the SDK sends to a Radar test project. They run separately from the SDK's unit tests.

## Layout

```
RadarSDKE2ETests/
  Helpers/
    RadarE2EConfiguration.swift             Shared by the host app and RadarSDKE2ETests
    RadarE2EHTTPRelay.swift                 Shared by the host app and RadarSDKE2ETests
  TestHost/
    RadarE2ETestHost.swift                  RadarE2ETestHost app
  XCUITestWrapper/
    RadarTrackOncePermissionUITests.swift   RadarSDKE2EPermissionUITests
  RadarTrackOnceScenario.swift              Shared by the host app and RadarSDKE2ETests
  RadarTrackOnceE2ETests.swift              RadarSDKE2ETests
```

The host app gives Core Location an iOS process to run in. `RadarTrackOnceScenario` points the SDK at a loopback relay, which forwards each request to the API and records the track request. The scenario passes when `trackOnce` succeeds with a location within 100 m of the fixture, and the SDK sends one `FOREGROUND_LOCATION` track request that gets HTTP 200. Each run uses a new user ID.

## Setup

You need:

- A dedicated simulator. Set `SIMULATOR_UDID` to its UDID, which `xcrun simctl list devices` prints.
- A Radar test project whose SDK configuration has `syncAfterSetUser`, `trackOnceOnAppOpen`, and `startTrackingOnInitialize` turned off. Otherwise the SDK can send extra track requests and the run fails.
- Two environment variables, set in the shell that runs `xcodebuild`.

`TEST_RUNNER_RADAR_E2E_BASE_URL` is the API origin. It must use HTTPS, or HTTP on `localhost` or `127.0.0.1`, and have no path or query.

`TEST_RUNNER_RADAR_E2E_PUBLISHABLE_KEY` is the project's test publishable key. It must start with `prj_test_pk_`.

`xcodebuild` strips the `TEST_RUNNER_` prefix, so the tests read `RADAR_E2E_BASE_URL` and `RADAR_E2E_PUBLISHABLE_KEY`. Keep the key out of the repo and pass it only through the environment. The SDK caches it in the test host's UserDefaults on the simulator.

## Run RadarSDKE2ETests

XCTest runs inside the host app and can't tap the permission prompt, so grant location access first.

```sh
xcrun simctl bootstatus "$SIMULATOR_UDID" -b

xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2ETests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e build-for-testing

xcrun simctl install "$SIMULATOR_UDID" \
  .build/e2e/Build/Products/Debug-iphonesimulator/RadarE2ETestHost.app
xcrun simctl privacy "$SIMULATOR_UDID" grant location io.radar.RadarE2ETestHost
xcrun simctl location "$SIMULATOR_UDID" set 40.78382,-73.97536

xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2ETests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e \
  -parallel-testing-enabled NO test-without-building
```

## Run RadarSDKE2EPermissionUITests

This scheme runs the same scenario. The wrapper launches the host app and taps "Allow While Using App" when the prompt appears. Uninstall the host app first. This resets its location permission so the prompt appears, and it succeeds when the app is not installed.

```sh
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
xcrun simctl uninstall "$SIMULATOR_UDID" io.radar.RadarE2ETestHost
xcrun simctl location "$SIMULATOR_UDID" set 40.78382,-73.97536

xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2EPermissionUITests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e \
  -parallel-testing-enabled NO test
```
