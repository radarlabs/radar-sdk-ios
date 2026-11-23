# iOS SDK end-to-end tests

The `RadarSDKE2ETests` scheme runs separately from the SDK's unit-test schemes.
Its test host supplies an iOS process for Core Location. XCTest calls the SDK
directly.

Use a dedicated simulator and an isolated Radar test project with automatic
tracking and replay disabled. Set `TEST_RUNNER_RADAR_E2E_BASE_URL` to the API
origin and `TEST_RUNNER_RADAR_E2E_PUBLISHABLE_KEY` to the project's test
publishable key. Supply the key through the environment.

Build the scheme once to provision the simulator:

```sh
xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2ETests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e build-for-testing
```

Install `.build/e2e/Build/Products/Debug-iphonesimulator/RadarE2ETestHost.app` on
the simulator, grant `io.radar.RadarE2ETestHost` When In Use location permission,
and set the simulator location to latitude `40.78382`, longitude `-73.97536`.
Then run:

```sh
xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2ETests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e \
  -parallel-testing-enabled NO test-without-building
```

The test uses a unique user ID for each run. The test's loopback HTTP relay forwards
requests to the configured API and records each track body and HTTP status.

## Run with permission setup

Use the `RadarSDKE2EPermissionUITests` scheme on a fresh simulator or a hosted
iPhone. The wrapper accepts the system's While Using the App prompt when it
appears. The host then runs the same SDK assertions as the hosted XCTest scheme.

Set the same API origin, test key, and location fixture as above. On a simulator
with the fixture location set, run:

```sh
xcodebuild -project RadarSDK.xcodeproj -scheme RadarSDKE2EPermissionUITests \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath .build/e2e \
  -parallel-testing-enabled NO test
```

For BrowserStack, build this scheme for a generic iOS device. Upload
`RadarE2ETestHost.app` as an IPA and zip `RadarSDKE2EPermissionUITests-Runner.app`
at the archive root. Start the run through App Automate's standard XCUITest
`/app-automate/xcuitest/v2/build` endpoint so BrowserStack generates the test
manifest. Pass `RADAR_E2E_BASE_URL` and `RADAR_E2E_PUBLISHABLE_KEY` in
`setEnvVariables`, and set `gpsLocation` to `40.78382,-73.97536` and `language`
to `en`.
