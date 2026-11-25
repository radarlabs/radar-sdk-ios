# iOS SDK end-to-end tests

These tests run the Radar SDK on an iOS simulator against the live Radar API and a Radar test project. They stub nothing. They run separately from the SDK's unit tests.

## Layout

| Folder | Contents |
|---|---|
| `Helpers/` | Code shared by every E2E test: configuration, the SDK driver (`RadarE2ESDK`), and the SDK log parser, with the parser's unit tests. |
| `Scenarios/` | The scenarios the host app can run and the result it reports. The XCUITests share this code. |
| `TestHost/` | The `RadarE2ETestHost` app. Hosted tests run inside it, and XCUITests launch it. |
| `XCUITestWrapper/` | XCUITests that launch the host app and answer system permission prompts. |
| One folder per SDK method, such as `TrackOnce/` | Hosted tests for that method. |

There are two test schemes:

- `RadarSDKE2ETests` runs inside the host app. Location permission must be granted before it starts. Put tests that vary SDK options here.
- `RadarSDKE2EPermissionUITests` launches the host app, resets its location permission for each test, and taps the system prompts. Put tests that vary permissions here.

## What the tests check

Every request is checked in three places, and all three must agree:

- the SDK callback
- the request the SDK logged
- the server response the SDK logged

The driver forces the SDK log level to debug for each run, whatever the project's SDK configuration says. It also turns off the SDK's console output, because at debug level the SDK prints request headers, and those include the key. A failure message names the field that didn't match and its value. It never includes log lines, headers, or the key.

For a successful `trackOnce`:

- The callback status is `SUCCESS`. The user has this run's user ID, is marked foreground, has source `FOREGROUND_LOCATION`, and is within 100 m of the fixture location.
- The logged `/v1/track` request has the same user ID, foreground flag, source, and location. It is the only track request, and replays count as track requests.
- The logged response has status 200 and the same user ID, foreground flag, source, and location. If the response has a `meta.code`, it is 200.

## Setup

You need:

- A dedicated simulator. Set `SIMULATOR_UDID` to its UDID. `xcrun simctl list devices` prints it.
- A Radar test project. In its SDK configuration, turn off `syncAfterSetUser`, `trackOnceOnAppOpen`, and `startTrackingOnInitialize`, and set replay to none in its tracking options. Otherwise the SDK can send extra or replayed track requests, and the run fails.
- The two environment variables below, set in the shell that runs `xcodebuild`.

| Variable | Value |
|---|---|
| `TEST_RUNNER_RADAR_E2E_BASE_URL` | The Radar API origin for the key's environment. The dashboard and marketing site won't work. Use HTTPS, or HTTP on `localhost` or `127.0.0.1`, with no path or query. |
| `TEST_RUNNER_RADAR_E2E_PUBLISHABLE_KEY` | The project's test publishable key. It starts with `prj_test_pk_`. |

`xcodebuild` strips the `TEST_RUNNER_` prefix, so the tests read `RADAR_E2E_BASE_URL` and `RADAR_E2E_PUBLISHABLE_KEY`. Pass the key only through the environment, never in a file in the repo. The SDK caches the key in the host app's UserDefaults on the simulator. Each test clears the SDK's stored settings before it starts.

## Run RadarSDKE2ETests

The hosted tests can't tap the permission prompt, so grant location access before running them.

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

To run only the log parser tests, add `-only-testing:RadarSDKE2ETests/RadarE2ETrackLogTests`. They don't need a key or location permission.

## Run RadarSDKE2EPermissionUITests

This scheme needs no manual permission step. The tests find the prompt buttons by their iOS 26.2 labels, such as "Allow While Using App" and "Change to Always Allow". Other iOS versions may use different labels.

```sh
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
xcrun simctl location "$SIMULATOR_UDID" set 40.78382,-73.97536

xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2EPermissionUITests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e \
  -parallel-testing-enabled NO test
```

## Add a test

To test a new SDK method, create a folder for it and add a hosted `XCTestCase` that calls `RadarE2ESDK`. `TrackOnce/` shows the pattern: one call, then one assertion.

To add a permission test, follow these steps:

1. Add a case to `RadarE2EScenario`.
2. Handle that case in `RadarE2ESDK.run(_:)`.
3. Call `run(_:request:answers:)` from a subclass of `RadarE2EPermissionUITestCase`.
