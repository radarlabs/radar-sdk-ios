//
//  RadarTrackVerifiedIPTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import XCTest

@testable import RadarSDK

private final class IPTrackDelegate: NSObject, RadarDelegate, RadarVerifiedDelegate {
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

final class RadarTrackVerifiedIPTests: XCTestCase {
    private var restore: (() -> Void)?
    private var helper: MainQueueAPIHelperMock!
    private var delegate: IPTrackDelegate!

    private let stateKeys: [RadarUserDefaults.Key] = [
        .id, .trip, .tripOptions, .userDebug, .radarUser,
        .canExit, .geofenceIds, .placeId, .regionIds,
        .beaconIds, .altitudeAdjustments,
    ]

    override func setUp() {
        super.setUp()
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
        restore = {
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
        options.replay = .all
        RadarSettings.trackingOptions = options
        buffer.mutableReplayBuffer = []

        RadarState.shared.geofenceIds = ["existing-geofence"]
        RadarState.shared.canExit = true
        RadarState.shared.altitudeAdjustments = [["adjustment": 1]]

        helper = MainQueueAPIHelperMock()
        helper.mockStatus = .success
        client.apiHelper = helper

        delegate = IPTrackDelegate()
        holder.delegate = delegate
        holder.verifiedDelegate = delegate
    }

    override func tearDown() {
        restore?()
        restore = nil
        helper = nil
        delegate = nil
        super.tearDown()
    }

    private func jwsResponse() -> [AnyHashable: Any] {
        [
            "_id": "evaluation-id",
            "token": "signed-token",
            "expiresAt": "2026-11-12T12:00:00.000Z",
            "expiresIn": 90,
            "passed": true,
            "user": [
                "_id": "user-id",
                "location": ["coordinates": [-73.9, 40.7]],
                "geofences": [["_id": "response-geofence", "description": "g", "type": "circle"]],
                "altitudeAdjustments": [["adjustment": 999]],
            ],
            "events": [["_id": "event-id", "type": "user.failed_fraud", "createdAt": "2026-11-12T12:00:00.000Z"]],
            "failureReasons": [],
            "meta": ["code": 200],
        ]
    }

    private struct Result {
        let status: RadarStatus
        let events: [RadarEvent]?
        let user: RadarUser?
        let nearbyGeofences: [RadarGeofence]?
        let token: RadarVerifiedLocationToken?
    }

    private func track(
        response: [AnyHashable: Any],
        location: CLLocation?,
        status: RadarStatus = .success
    ) -> Result {
        helper.mockStatus = status
        helper.mockResponse = response
        let finished = expectation(description: "Track completes once")
        finished.assertForOverFulfill = true
        var result: Result?

        RadarTrackTestBridge.track(
            withPreparedPayload: nil,
            verified: true,
            secondary: false,
            location: location,
            reason: "ip reason"
        ) { status, _, events, user, nearbyGeofences, _, token in
            result = Result(status: status, events: events, user: user, nearbyGeofences: nearbyGeofences, token: token)
            finished.fulfill()
        }

        wait(for: [finished], timeout: 5)
        return result ?? Result(status: .errorUnknown, events: nil, user: nil, nearbyGeofences: nil, token: nil)
    }

    private func stateSnapshot() -> [NSObject?] {
        stateKeys.map { RadarUserDefaults.object(forKey: $0) as? NSObject }
    }

    func test_ipRequestSendsNoLocationFields() throws {
        _ = track(response: jwsResponse(), location: nil)

        let params = try XCTUnwrap(helper.lastParams as? [String: Any])
        for field in [
            "latitude", "longitude", "accuracy", "altitude", "verticalAccuracy", "speed",
            "speedAccuracy", "course", "courseAccuracy", "floorLevel", "updatedAtMsDiff",
            "locationMs", "nearbyGeofences",
        ] {
            XCTAssertNil(params[field], "IP request must not send \(field)")
        }
        XCTAssertEqual(params["verificationLevel"] as? String, "ip")
        XCTAssertEqual(params["verified"] as? Bool, true)
        XCTAssertEqual(params["reason"] as? String, "ip reason")
    }

    func test_preciseRequestKeepsLocationFieldsAndNoLevel() throws {
        _ = track(response: jwsResponse(), location: CLLocation(latitude: 40.0, longitude: -73.0))

        let params = try XCTUnwrap(helper.lastParams as? [String: Any])
        XCTAssertEqual(params["latitude"] as? Double, 40.0)
        XCTAssertEqual(params["longitude"] as? Double, -73.0)
        XCTAssertNil(params["verificationLevel"])
    }

    func test_ipJWSResponseDeliversTokenAndEventsWithoutChangingState() {
        let before = stateSnapshot()
        let result = track(response: jwsResponse(), location: nil)

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.token?.verificationLevel, .ip)
        XCTAssertNil(result.nearbyGeofences)
        XCTAssertNotNil(result.user)
        XCTAssertEqual(delegate.tokens.count, 1)
        XCTAssertEqual(delegate.eventUpdates, 1)
        XCTAssertEqual(delegate.locationUpdates, 0)
        XCTAssertTrue(delegate.failures.isEmpty)
        XCTAssertEqual(stateSnapshot(), before)
    }

    func test_ipJWSResponseWithoutUserLocationStillDeliversTokenAndEvents() {
        var response = jwsResponse()
        var user = response["user"] as? [String: Any] ?? [:]
        user["location"] = nil
        response["user"] = user
        let before = stateSnapshot()

        let result = track(response: response, location: nil)

        XCTAssertEqual(result.status, .success)
        XCTAssertNil(result.user)
        XCTAssertEqual(delegate.eventUpdates, 1)
        XCTAssertEqual(delegate.tokens.first?.verificationLevel, .ip)
        XCTAssertEqual(stateSnapshot(), before)
    }

    func test_ipRequestIsNotBatched() throws {
        let options = RadarTrackingOptions.presetContinuous
        options.batchSize = 10
        RadarSettings.trackingOptions = options

        let result = track(response: jwsResponse(), location: nil)

        XCTAssertEqual(result.status, .success)
        XCTAssertNotNil(result.token)
        let params = try XCTUnwrap(helper.lastParams as? [String: Any])
        XCTAssertEqual(params["source"] as? String, "FOREGROUND_LOCATION")
    }

    func test_ipReducedResponsesUseTheIPLevelWhenTheServerOmitsIt() {
        let responses: [[AnyHashable: Any]] = [
            ["format": "id", "_id": "lookup-id", "meta": ["code": 200]],
            [
                "format": "jwe", "_id": "evaluation-id", "token": "opaque-token",
                "expiresAt": "2026-11-12T12:00:00.000Z", "expiresIn": 90, "passed": true,
                "meta": ["code": 200],
            ],
        ]
        for response in responses {
            let result = track(response: response, location: nil)

            XCTAssertEqual(result.status, .success)
            XCTAssertEqual(result.token?.verificationLevel, .ip)
        }
    }

    func test_serverLevelWinsOverTheRequestedLevel() {
        var response = jwsResponse()
        response["verificationLevel"] = "precise"

        let result = track(response: response, location: nil)

        XCTAssertEqual(result.token?.verificationLevel, .precise)
    }

    func test_ipFailureDoesNotReplayOrStoreLocation() {
        let result = track(response: [:], location: nil, status: .errorNetwork)

        XCTAssertEqual(result.status, .errorNetwork)
        XCTAssertTrue(RadarReplayBuffer.sharedInstance.flushableReplays.isEmpty)
        XCTAssertEqual(delegate.failures, [.errorNetwork])
    }

    func test_ipJWSResponseWithoutEventsFails() {
        var response = jwsResponse()
        response["events"] = nil
        let before = stateSnapshot()

        let result = track(response: response, location: nil)

        XCTAssertEqual(result.status, .errorServer)
        XCTAssertTrue(delegate.tokens.isEmpty)
        XCTAssertEqual(stateSnapshot(), before)
    }
}
