//
//  RadarSDKTestsSwift.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
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

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarSDKTestsSwift {

        private let apiHelperMock = MainQueueAPIHelperMock()
        private let locationManagerMock = RequestLocationCLLocationManager()
        private let permissionsHelperMock = RadarPermissionsHelperMock()

        init() {
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
        func expectedAddressIncludedInTrackRequest() async throws {
            let manager = try #require(ObjCVerificationManager.shared)
            let originalFactory = manager.instance.value(forKey: "trackVerifiedPayloadFactory")
            defer { manager.instance.setValue(originalFactory, forKey: "trackVerifiedPayloadFactory") }
            let prepared = MockPreparedFraudPayloadInstance(result: ["payload": MockFraudEnvelope.payload])
            let instance = MockCollectingFraudInstance(result: ["preparedPayload": prepared])
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let factory: @convention(block) ([String: Any]) -> NSObject = { options in
                RadarTrackVerifiedRequestPreparer(fraudSDK: fraudSDK, options: options)
            }
            manager.instance.setValue(factory as AnyObject, forKey: "trackVerifiedPayloadFactory")

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
            let context = try #require(prepared.capturedOptions.last)
            let coreData = try #require(context["body"] as? Data)
            let coreBody = try #require(try JSONSerialization.jsonObject(with: coreData) as? [String: Any])
            #expect(coreBody["expectedAddress"] as? String == "111 5th Ave, NY")
            let sentBody = try #require(apiHelperMock.lastParams as? [String: Any])
            #expect(Set(sentBody.keys) == MockFraudEnvelope.fieldNames)
        }
    }
}
