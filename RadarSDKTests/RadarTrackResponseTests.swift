//
//  RadarTrackResponseTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/12/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import XCTest

@testable import RadarSDK

private final class TrackResponseDelegate: NSObject, RadarDelegate, RadarVerifiedDelegate {
    var tokens: [RadarVerifiedLocationToken] = []
    var failures: [RadarStatus] = []
    var locationUpdates = 0
    var eventUpdates = 0

    func didUpdateToken(_ token: RadarVerifiedLocationToken) {
        tokens.append(token)
    }

    func didFail(status: RadarStatus) {
        failures.append(status)
    }

    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        locationUpdates += 1
    }

    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        eventUpdates += 1
    }
}

final class RadarTrackResponseTests: XCTestCase {
    private func jweResponse(passed: Bool = true) -> [AnyHashable: Any] {
        [
            "format": "jwe",
            "_id": "evaluation-id",
            "token": "opaque-token",
            "expiresAt": "2026-11-12T12:00:00.000Z",
            "expiresIn": 90,
            "passed": passed,
            "meta": [
                "code": 200,
                "trackingOptions": ["desiredMovingUpdateInterval": 17],
            ],
        ]
    }

    private func legacyResponse() -> [AnyHashable: Any] {
        [
            "_id": "evaluation-id",
            "token": "signed-token",
            "expiresAt": "2026-11-12T12:00:00.000Z",
            "expiresIn": 90,
            "passed": true,
            "user": [
                "_id": "user-id",
                "location": ["coordinates": [-73.9, 40.7]],
            ],
            "events": [],
            "failureReasons": [],
            "extra": "preserved",
        ]
    }

    func test_JWE_passedAndFailedEvaluationsSucceed() throws {
        for passed in [true, false] {
            try assertResponse(
                jweResponse(passed: passed),
                expectedStatus: .success,
                expectedFormat: .jwe
            )
        }
    }

    func test_IDResponseSucceeds() throws {
        try assertResponse(
            [
                "format": "id",
                "_id": "lookup-id",
                "meta": [
                    "code": 200,
                    "trackingOptions": ["desiredMovingUpdateInterval": 17],
                ],
            ],
            expectedStatus: .success,
            expectedFormat: .id
        )
    }

    func test_JWEIgnoresUnexpectedLegacyFields() throws {
        var response = jweResponse()
        response["user"] = legacyResponse()["user"]
        response["events"] = []
        response["failureReasons"] = ["unexpected-reason"]

        try assertResponse(
            response,
            expectedStatus: .success,
            expectedFormat: .jwe
        )
    }

    func test_malformedReducedResponsesFail() throws {
        var missingToken = jweResponse()
        missingToken["token"] = nil

        var invalidExpiration = jweResponse()
        invalidExpiration["expiresAt"] = "not a date"

        var unknownFormat = legacyResponse()
        unknownFormat["format"] = "unknown"

        var malformedFormat = legacyResponse()
        malformedFormat["format"] = NSNull()

        let responses: [[AnyHashable: Any]] = [
            missingToken,
            invalidExpiration,
            unknownFormat,
            malformedFormat,
            ["format": "id", "_id": ""],
            ["format": "id"],
        ]

        for response in responses {
            try assertResponse(
                response,
                expectedStatus: .errorServer,
                expectedFormat: nil
            )
        }
    }

    func test_legacyAndExplicitJWSKeepExistingBehavior() throws {
        for explicitFormat in [false, true] {
            var response = legacyResponse()
            if explicitFormat {
                response["format"] = "jws"
            }

            try assertResponse(
                response,
                expectedStatus: .success,
                expectedFormat: .jws
            )
        }
    }

    func test_ordinaryTrackKeepsExistingBehavior() throws {
        try assertResponse(
            legacyResponse(),
            verified: false,
            expectedStatus: .success,
            expectedFormat: .jws
        )
    }

    private func assertResponse(
        _ response: [AnyHashable: Any],
        verified: Bool = true,
        expectedStatus: RadarStatus,
        expectedFormat: RadarResponseFormat?
    ) throws {
        let client = RadarAPIClient.sharedInstance()
        let originalHelper = client.apiHelper
        let holder = RadarDelegateHolder.sharedInstance()
        let originalDelegate = holder.delegate
        let originalVerifiedDelegate = holder.verifiedDelegate
        let originalPreferences = RadarUserDefaults.Key.allCases.map {
            ($0, RadarUserDefaults.object(forKey: $0))
        }
        let buffer = RadarReplayBuffer.sharedInstance
        let originalReplays = buffer.mutableReplayBuffer

        defer {
            client.apiHelper = originalHelper
            holder.delegate = originalDelegate
            holder.verifiedDelegate = originalVerifiedDelegate
            buffer.mutableReplayBuffer = originalReplays
            for (key, value) in originalPreferences {
                RadarUserDefaults.set(value, forKey: key)
            }
            RadarOfflineEventManager.reset()
        }

        RadarSettings.publishableKey = "prj_test_pk_radar_sdk_ios"
        RadarSettings.anonymousTrackingEnabled = false
        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [:])

        let options = RadarTrackingOptions.presetContinuous
        options.replay = .none
        RadarSettings.trackingOptions = options
        buffer.mutableReplayBuffer = []

        RadarState.shared.geofenceIds = ["existing-geofence"]
        RadarState.shared.canExit = true
        RadarState.shared.altitudeAdjustments = [["adjustment": 1]]

        let stateKeys: [RadarUserDefaults.Key] = [
            .id, .trip, .tripOptions, .userDebug, .radarUser,
            .canExit, .geofenceIds, .placeId, .regionIds,
            .beaconIds, .altitudeAdjustments,
        ]
        let preservedState = stateKeys.map {
            ($0, RadarUserDefaults.object(forKey: $0))
        }

        let helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        helper.mockResponse = response
        client.apiHelper = helper

        let delegate = TrackResponseDelegate()
        holder.delegate = delegate
        holder.verifiedDelegate = delegate

        let finished = expectation(description: "Track response completes once")
        finished.assertForOverFulfill = true
        var callbackCount = 0
        var receivedToken: RadarVerifiedLocationToken?

        RadarTrackTestBridge.track(
            withPreparedPayload: nil,
            verified: verified,
            secondary: false
        ) { status, returnedResponse, events, user, nearbyGeofences, config, token in
            callbackCount += 1
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(status, expectedStatus)
            XCTAssertEqual(token?.format, expectedFormat)
            receivedToken = token

            if expectedStatus == .success {
                XCTAssertNotNil(token)
                XCTAssertNotNil(config)

                if expectedFormat == .jws {
                    XCTAssertNotNil(user)
                    XCTAssertNotNil(events)
                    XCTAssertEqual(returnedResponse?["extra"] as? String, "preserved")
                } else {
                    XCTAssertNil(user)
                    XCTAssertNil(events)
                    XCTAssertNil(nearbyGeofences)
                    XCTAssertNil(returnedResponse?["user"])
                    XCTAssertNil(returnedResponse?["events"])
                    XCTAssertNil(returnedResponse?["failureReasons"])
                    XCTAssertEqual(
                        config?.meta?.trackingOptions?.desiredMovingUpdateInterval,
                        17
                    )
                    XCTAssertEqual(
                        returnedResponse as NSDictionary?,
                        token?.dictionaryValue() as NSDictionary?
                    )
                }
            } else {
                XCTAssertNil(returnedResponse)
                XCTAssertNil(token)
                XCTAssertNil(config)
            }

            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)
        XCTAssertEqual(callbackCount, 1)

        if expectedStatus == .success {
            XCTAssertTrue(delegate.failures.isEmpty)
            XCTAssertEqual(delegate.tokens.count, 1)
            XCTAssertTrue(delegate.tokens.first === receivedToken)
        } else {
            XCTAssertEqual(delegate.failures, [expectedStatus])
            XCTAssertTrue(delegate.tokens.isEmpty)
        }

        if expectedFormat != .jws {
            XCTAssertEqual(delegate.locationUpdates, 0)
            XCTAssertEqual(delegate.eventUpdates, 0)

            for (key, originalValue) in preservedState {
                let current = RadarUserDefaults.object(forKey: key)
                XCTAssertEqual(
                    current as? NSObject,
                    originalValue as? NSObject,
                    "Unexpected state change: \(key.rawValue)"
                )
            }
        }
    }
}
