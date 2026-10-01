//
//  RadarSDKTestsSwift.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import ObjectiveC
import Testing

@testable import RadarSDK

/// Delivers `mockLocation` to the delegate on `requestLocation()`, like `CLLocationManagerMock`.
private final class RequestLocationCLLocationManager: CLLocationManager, @unchecked Sendable {
    var mockLocation: CLLocation?

    override var location: CLLocation? { mockLocation }

    override func requestLocation() {
        if let mockLocation {
            delegate?.locationManager?(self, didUpdateLocations: [mockLocation])
        }
    }
}

/// `RadarVerificationManager` looks the fraud SDK up by name, so this is registered as
/// `RadarSDKFraud` when the real submodule isn't linked into the test bundle.
private class StubRadarSDKFraud: NSObject {
    private static let instance = MockFraudSDK(result: ["payload": "mock-fraud-payload"], sharing: false)

    @objc static func sharedInstance() -> NSObject {
        return instance
    }

    static func registerIfNeeded() {
        guard NSClassFromString("RadarSDKFraud") == nil,
            let cls = objc_allocateClassPair(StubRadarSDKFraud.self, "RadarSDKFraud", 0)
        else {
            return
        }
        objc_registerClassPair(cls)
    }
}

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarSDKTestsSwift {

        private let apiHelperMock = RadarAPIHelperMock()
        private let locationManagerMock = RequestLocationCLLocationManager()
        private let permissionsHelperMock = RadarPermissionsHelperMock()

        init() {
            StubRadarSDKFraud.registerIfNeeded()
            Radar.initialize(publishableKey: "prj_test_pk_0000000000000000000000000000000000000000")

            RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
            let locationManager = RadarLocationManager.sharedInstance()
            locationManager.locationManager = locationManagerMock
            locationManager.lowPowerLocationManager = locationManagerMock
            locationManagerMock.delegate = locationManager
            locationManager.permissionsHelper = permissionsHelperMock
        }

        /// The mocks call back synchronously, so the track response is handled on the caller's thread.
        /// It must be main, because the response handler touches `@MainActor` `RadarInAppMessageManager`.
        @Test("Includes the expected address in the track request after setExpectedAddress")
        @MainActor
        func expectedAddressIncludedInTrackRequest() async {
            Radar.setExpectedAddress("111 5th Ave, NY")
            defer { Radar.setExpectedAddress(nil) }

            permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedWhenInUse
            locationManagerMock.mockLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40.78382, longitude: -73.97536),
                altitude: -1,
                horizontalAccuracy: 65,
                verticalAccuracy: -1,
                timestamp: Date()
            )
            apiHelperMock.mockStatus = .success
            apiHelperMock.mockResponse = ["meta": ["config": [:]]]

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Radar.trackVerified { _, _ in
                    continuation.resume()
                }
            }

            #expect(apiHelperMock.lastUrl?.contains("/v1/track") == true)
            #expect(apiHelperMock.lastParams?["expectedAddress"] as? String == "111 5th Ave, NY")
        }
    }
}
