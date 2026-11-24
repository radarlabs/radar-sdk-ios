# iOS SDK end-to-end tests

These tests run the Radar SDK on an iOS simulator against the live Radar API and a Radar test project. They stub nothing. They run separately from the SDK's unit tests.

## Layout

```
RadarSDKE2ETests/
  Helpers/
    RadarE2EConfiguration.swift             host app, RadarSDKE2ETests
    RadarE2ESDK.swift                       host app, RadarSDKE2ETests
    RadarE2ETrackLog.swift                  host app, RadarSDKE2ETests
    RadarE2ETrackLogTests.swift             RadarSDKE2ETests
  Scenarios/
    RadarE2EScenario.swift                  host app, RadarSDKE2ETests, RadarSDKE2EPermissionUITests
  TrackOnce/
    RadarTrackOnceE2ETests.swift            RadarSDKE2ETests
  TestHost/
    RadarE2ETestHost.swift                  RadarE2ETestHost app
  XCUITestWrapper/
    RadarE2EPermissionUITestCase.swift      RadarSDKE2EPermissionUITests
    RadarTrackOncePermissionUITests.swift   RadarSDKE2EPermissionUITests
```

`RadarE2ESDK` points the SDK at the live API, runs `Radar.trackOnce`, and checks the outcome. `RadarE2ETrackLog` parses the SDK's request and response log lines. `RadarE2EScenario` names the scenarios the host app can run and defines the result it reports.

`RadarSDKE2ETests` runs inside the host app, which gives Core Location an iOS process. The hosted tests need location permission granted before they start. `RadarSDKE2EPermissionUITests` launches the host app itself and answers the system prompts, so it covers the permission cases.

## What a passing trackOnce checks

A successful `trackOnce` must pass three checks that agree with each other.

- The SDK callback has status `SUCCESS` and a user with this run's user ID. That user is marked foreground, has source `FOREGROUND_LOCATION`, and is within 100 m of the fixture location.
- The `/v1/track` request in the SDK's log has `foreground` true, source `FOREGROUND_LOCATION`, this run's user ID, and a location within 100 m of the fixture. It is the only track request, and replays count as track requests.
- The server response in the SDK's log has status 200 and the same user ID, foreground flag, source, and location. `meta.code` must be 200 when the response has one.

A failure names the field that mismatched and its value. It never includes log lines, headers, or the key.

## Setup

You need:

- A dedicated simulator. Set `SIMULATOR_UDID` to its UDID, which `xcrun simctl list devices` prints.
- A Radar test project whose SDK configuration has `syncAfterSetUser`, `trackOnceOnAppOpen`, and `startTrackingOnInitialize` turned off, and whose tracking options set replay to none. Otherwise the SDK can send extra or replayed track requests and the run fails.
- A test project SDK log level of `debug`. The checks read the SDK's debug log. `Radar.setLogLevel(.debug)` only sends the level to the server as client configuration, and the SDK applies the level in the server's config response. The harness stores `debug` before the first request, but a config response with a lower level turns logging off. Then a successful run fails with `Expected one track request, observed 0`.
- Two environment variables, set in the shell that runs `xcodebuild`.

`TEST_RUNNER_RADAR_E2E_BASE_URL` is the API origin. It must use HTTPS, or HTTP on `localhost` or `127.0.0.1`, and have no path or query.

`TEST_RUNNER_RADAR_E2E_PUBLISHABLE_KEY` is the project's test publishable key. It must start with `prj_test_pk_`.

`xcodebuild` strips the `TEST_RUNNER_` prefix, so the tests read `RADAR_E2E_BASE_URL` and `RADAR_E2E_PUBLISHABLE_KEY`. Keep the key out of the repo and pass it only through the environment. At debug level the SDK writes request headers, including the key, to the device console, and it caches the key in the test host's UserDefaults on the simulator. Each test starts from clean SDK defaults.

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

To run only the log parser tests, which need no key and no permission, add `-only-testing:RadarSDKE2ETests/RadarE2ETrackLogTests`.

## Run RadarSDKE2EPermissionUITests

Each test resets the host app's location permission, launches the host app with a scenario, taps the system prompts, and checks the result the host reports. No manual permission step is needed. The tests tap the buttons by their iOS 26.2 labels, such as "Allow While Using App" and "Change to Always Allow". Other iOS versions can word them differently.

```sh
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
xcrun simctl location "$SIMULATOR_UDID" set 40.78382,-73.97536

xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2EPermissionUITests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e \
  -parallel-testing-enabled NO test
```

## Add a test

A hosted test calls `RadarE2ESDK` and asserts in two lines. See `TrackOnce/RadarTrackOnceE2ETests.swift`.

A permission test adds a case to `RadarE2EScenario`, handles it in `RadarE2ESDK.run(_:)`, and calls `run(_:request:answers:)` from a subclass of `RadarE2EPermissionUITestCase`.
