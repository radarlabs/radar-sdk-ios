//
//  RadarTrackBeaconRegionRegistrationTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import XCTest

@testable import RadarSDK

/// nearbyBeaconRegions is not verdict-bearing, so it stays in the plaintext response in both
/// formats. These tests pin that beacon-region registration happens before the JWS/JWE response
/// branches in RadarAPIClient — a protected (JWE) response must register regions even though it
/// returns early with nil user and events.
final class RadarTrackBeaconRegionRegistrationTests: XCTestCase {

    private static let beaconUUID = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"

    private static var nearbyBeaconRegions: [[String: Any]] {
        [
            [
                "uuid": beaconUUID,
                "metadata": ["radar:campaignId": "campaign-1"],
            ]
        ]
    }

    private var apiHelperMock: RadarAPIHelperMock!

    override func setUp() {
        super.setUp()
        Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

        apiHelperMock = RadarAPIHelperMock()
        apiHelperMock.mockStatus = .success
        RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
    }

    /// Replaces the implementation of the beacon-region registration method with a capturing
    /// block for the duration of `body`. The production call site is Objective-C, so the call
    /// dispatches through objc_msgSend and is guaranteed to hit the swapped implementation.
    private func captureRegisteredBeaconRegions(during body: () -> Void) -> [[String: Any]]? {
        let selector = NSSelectorFromString("registerBeaconRegionNotificationsFromArray:")
        guard let method = class_getInstanceMethod(RadarBeaconManagerSwift.self, selector) else {
            XCTFail("registerBeaconRegionNotificationsFromArray: not found on RadarBeaconManagerSwift")
            return nil
        }

        var captured: [[String: Any]]?
        let block: @convention(block) (AnyObject, NSArray) -> Void = { _, regions in
            captured = regions as? [[String: Any]]
        }
        let originalIMP = method_setImplementation(method, imp_implementationWithBlock(block))
        defer { method_setImplementation(method, originalIMP) }

        body()
        return captured
    }

    private func track(completionHandler: @escaping RadarTrackAPICompletionHandler) {
        RadarAPIClient.sharedInstance().track(
            with: CLLocation(latitude: 40.7043, longitude: -73.9867),
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: nil,
            verified: true,
            fraudPayload: nil,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            reason: nil,
            transactionId: nil,
            useSecondaryVerifiedHost: false,
            completionHandler: completionHandler
        )
    }

    func test_track_jweResponse_registersNearbyBeaconRegions() {
        // protected mode: user and events only exist inside the encrypted token,
        // but nearbyBeaconRegions is still present in plaintext
        apiHelperMock.mockResponse = [
            "meta": ["code": 200],
            "_id": "location-789",
            "token": "aaa.bbb.ccc.ddd.eee",
            "expiresAt": "2026-08-20T12:00:00.000Z",
            "expiresIn": 1200,
            "passed": true,
            "format": "JWE",
            "nearbyBeaconRegions": Self.nearbyBeaconRegions,
        ]

        let exp = expectation(description: "track completes")
        var capturedStatus: RadarStatus?
        var capturedToken: RadarVerifiedLocationToken?
        var capturedUser: RadarUser?
        var capturedEvents: [RadarEvent]?

        let registeredRegions = captureRegisteredBeaconRegions {
            track { status, _, events, user, _, _, token in
                capturedStatus = status
                capturedToken = token
                capturedUser = user
                capturedEvents = events
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1)
        }

        XCTAssertEqual(capturedStatus, .success)
        XCTAssertEqual(capturedToken?.format, .jwe)
        XCTAssertNil(capturedUser)
        XCTAssertNil(capturedEvents)

        XCTAssertEqual(registeredRegions?.count, 1)
        XCTAssertEqual(registeredRegions?.first?["uuid"] as? String, Self.beaconUUID)
    }

    func test_track_jwsResponse_stillRegistersNearbyBeaconRegions() {
        apiHelperMock.mockResponse = [
            "meta": ["code": 200],
            "user": [
                "_id": "user-123",
                "userId": "verified-user",
                "location": ["type": "Point", "coordinates": [-73.9867, 40.7043]],
                "locationAccuracy": 20,
            ],
            "events": [],
            "nearbyBeaconRegions": Self.nearbyBeaconRegions,
        ]

        let exp = expectation(description: "track completes")
        var capturedStatus: RadarStatus?
        var capturedUser: RadarUser?

        let registeredRegions = captureRegisteredBeaconRegions {
            track { status, _, _, user, _, _, _ in
                capturedStatus = status
                capturedUser = user
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1)
        }

        XCTAssertEqual(capturedStatus, .success)
        XCTAssertNotNil(capturedUser)

        XCTAssertEqual(registeredRegions?.count, 1)
        XCTAssertEqual(registeredRegions?.first?["uuid"] as? String, Self.beaconUUID)
    }
}
