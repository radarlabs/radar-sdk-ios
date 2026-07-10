//
//  RadarIndoorLocationTrackParamsTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import XCTest

@testable import RadarSDK

/// Covers how `RadarAPIClient.trackWithLocation:...indoorLocation:...` maps an indoor ML
/// `CLLocation` into the `/track` request: the top-level coordinate overwrite, the
/// `locationMetadata` indoor/device keys, and the `useIndoorScan && indoorLocation` gate.
///
/// This is the highest-risk behavior in the "Wire RadarIndoors into the tracking pipeline"
/// change and it is a pure function of `(location, options, indoorLocation) -> params`, so it
/// can be exercised directly against `RadarAPIHelperMock` without the `RadarSDKIndoors`
/// framework or the `RadarIndoorsActor`.
final class RadarIndoorLocationTrackParamsTests: XCTestCase {

    private var apiHelperMock: RadarAPIHelperMock!

    // Distinct device vs. indoor coordinates so an accidental passthrough (or a missing
    // overwrite) is unambiguous in an assertion failure.
    private let deviceLatitude = 40.7128
    private let deviceLongitude = -74.0060
    private let indoorLatitude = 40.7130
    private let indoorLongitude = -74.0055

    override func setUp() {
        super.setUp()
        Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

        apiHelperMock = RadarAPIHelperMock()
        apiHelperMock.mockStatus = .success
        apiHelperMock.mockResponse = ["meta": ["config": [:]]]
        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock

        // `Radar.getTrackingOptions()` returns `remoteTrackingOptions ?? trackingOptions`; clear
        // any remote options so the local options set per-test are the ones that take effect.
        RadarSettings.remoteTrackingOptions = nil
    }

    override func tearDown() {
        RadarSettings.trackingOptions = nil
        RadarSettings.remoteTrackingOptions = nil
        super.tearDown()
    }

    /// Continuous preset with only `useIndoorScan` flipped on: motion/pressure stay off so
    /// `locationMetadata` contains exactly the indoor keys.
    private func setIndoorScanEnabled(_ enabled: Bool) {
        let options = RadarTrackingOptions.presetContinuous
        options.useIndoorScan = enabled
        RadarSettings.trackingOptions = options
    }

    private func track(indoorLocation: CLLocation?) -> [AnyHashable: Any] {
        let exp = expectation(description: "track completes")
        let location = CLLocation(latitude: deviceLatitude, longitude: deviceLongitude)
        RadarAPIClient.sharedInstance().track(
            with: location,
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: indoorLocation
        ) { _, _, _, _, _, _, _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return apiHelperMock.lastParams ?? [:]
    }

    // MARK: - indoor on

    func test_indoorOn_withIndoorLocation_overwritesCoordinatesAndAddsMetadata() {
        setIndoorScanEnabled(true)
        let indoor = CLLocation(latitude: indoorLatitude, longitude: indoorLongitude)

        let params = track(indoorLocation: indoor)

        // Top-level coordinates are replaced with the indoor ML prediction.
        XCTAssertEqual(params["latitude"] as? Double ?? .nan, indoorLatitude, accuracy: 1e-9)
        XCTAssertEqual(params["longitude"] as? Double ?? .nan, indoorLongitude, accuracy: 1e-9)

        let metadata = params["locationMetadata"] as? [String: Any]
        XCTAssertNotNil(metadata, "expected locationMetadata to be attached when indoor location is present")
        XCTAssertEqual(metadata?["indoorMLLatitude"] as? Double ?? .nan, indoorLatitude, accuracy: 1e-9)
        XCTAssertEqual(metadata?["indoorMLLongitude"] as? Double ?? .nan, indoorLongitude, accuracy: 1e-9)
        // The original device fix is preserved under device* so the server can compare.
        XCTAssertEqual(metadata?["deviceLatitude"] as? Double ?? .nan, deviceLatitude, accuracy: 1e-9)
        XCTAssertEqual(metadata?["deviceLongitude"] as? Double ?? .nan, deviceLongitude, accuracy: 1e-9)
    }

    // MARK: - indoor off (regression guard for every existing customer)

    func test_indoorOff_withIndoorLocation_leavesCoordinatesUntouched() {
        setIndoorScanEnabled(false)
        // A non-nil indoor location must be ignored entirely when useIndoorScan is off.
        let indoor = CLLocation(latitude: indoorLatitude, longitude: indoorLongitude)

        let params = track(indoorLocation: indoor)

        XCTAssertEqual(params["latitude"] as? Double ?? .nan, deviceLatitude, accuracy: 1e-9)
        XCTAssertEqual(params["longitude"] as? Double ?? .nan, deviceLongitude, accuracy: 1e-9)
        XCTAssertNil(params["locationMetadata"], "no locationMetadata should be sent when indoor is off and motion/pressure are off")
    }

    // MARK: - indoor on but the prediction is an invalid / sentinel coordinate

    func test_indoorOn_withZeroIslandIndoorLocation_leavesCoordinatesUntouched() {
        setIndoorScanEnabled(true)
        // (0, 0) is a valid CLLocationCoordinate2D but the classic "no fix" sentinel; the coordinate
        // overwrite must reject it so a bad prediction can't move the reported location to null island.
        let params = track(indoorLocation: CLLocation(latitude: 0, longitude: 0))

        XCTAssertEqual(params["latitude"] as? Double ?? .nan, deviceLatitude, accuracy: 1e-9)
        XCTAssertEqual(params["longitude"] as? Double ?? .nan, deviceLongitude, accuracy: 1e-9)
        XCTAssertNil(params["locationMetadata"], "invalid/zero indoor coordinate should be ignored")
    }

    // MARK: - indoor on but no prediction available

    func test_indoorOn_withNilIndoorLocation_leavesCoordinatesUntouched() {
        setIndoorScanEnabled(true)

        let params = track(indoorLocation: nil)

        // The `&& indoorLocation` half of the gate: flag on, no prediction -> nothing changes.
        XCTAssertEqual(params["latitude"] as? Double ?? .nan, deviceLatitude, accuracy: 1e-9)
        XCTAssertEqual(params["longitude"] as? Double ?? .nan, deviceLongitude, accuracy: 1e-9)
        XCTAssertNil(params["locationMetadata"], "no locationMetadata should be attached when indoor location is nil and motion/pressure are off")
    }
}
