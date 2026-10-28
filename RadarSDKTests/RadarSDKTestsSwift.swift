//
//  RadarSDKTestsSwift.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    @MainActor
    struct RadarSDKTestsSwift {

        private let fixture = RadarSDKTestFixture(apiHelperMock: MainQueueAPIHelperMock())
        private var apiHelperMock: RadarAPIHelperMock { fixture.apiHelperMock }
        private var locationManagerMock: RequestLocationCLLocationManager { fixture.locationManagerMock }
        private var permissionsHelperMock: RadarPermissionsHelperMock { fixture.permissionsHelperMock }

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
