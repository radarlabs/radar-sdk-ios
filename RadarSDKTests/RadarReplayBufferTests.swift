//
//  RadarReplayBufferTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import XCTest

@testable import RadarSDK

final class RadarReplayBufferTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let buffer = RadarReplayBuffer.sharedInstance
        buffer.clearBuffer()
        buffer.cancelBatchTimer()
        buffer.setIsFlushing(false)
    }

    private func setPersistence(_ enabled: Bool) {
        RadarSettings.sdkConfiguration = RadarSdkConfiguration(dict: [
            "logLevel": "warning",
            "startTrackingOnInitialize": false,
            "trackOnceOnAppOpen": false,
            "usePersistence": enabled,
            "extendFlushReplays": false,
            "useLogPersistence": false,
            "useRadarModifiedBeacon": false,
            "syncAfterSetUser": false,
        ])
    }

    func test_clearBuffer_emptiesMemoryAndStore() {
        setPersistence(true)
        let buffer = RadarReplayBuffer.sharedInstance
        buffer.writeNewReplayToBuffer(["i": 1])
        XCTAssertEqual(buffer.batchCount(), 1)

        buffer.clearBuffer()
        XCTAssertEqual(buffer.batchCount(), 0)
        buffer.loadReplaysFromPersistentStore()
        XCTAssertEqual(buffer.batchCount(), 0)
    }

    func test_dropOldestReplay_removesfirst() {
        setPersistence(false)
        let buffer = RadarReplayBuffer.sharedInstance
        buffer.writeNewReplayToBuffer(["i": 1])
        buffer.writeNewReplayToBuffer(["i": 2])
        buffer.dropOldestReplay()
        XCTAssertEqual(buffer.batchCount(), 1)
        XCTAssertEqual(buffer.flushableReplays.first?.replayParams as NSDictionary?, ["i": 2] as NSDictionary)
    }

    func test_writeNewReplay_enforcesMaxBufferSize() {
        setPersistence(false)
        let buffer = RadarReplayBuffer.sharedInstance
        for index in 0..<121 {
            buffer.writeNewReplayToBuffer(["i": index])
        }
        // capped at 120: oldest (i = 0) dropped
        XCTAssertEqual(buffer.batchCount(), 120)
        XCTAssertEqual(buffer.flushableReplays.first?.replayParams as NSDictionary?, ["i": 1] as NSDictionary)
    }

    func test_persistence_prunesEveryFithAbove50() {
        setPersistence(true)
        let buffer = RadarReplayBuffer.sharedInstance
        for index in 0..<51 {
            buffer.writeNewReplayToBuffer(["i": index])
        }
        XCTAssertEqual(buffer.batchCount(), 51)  // in-memory keeps all

        buffer.mutableReplayBuffer = []
        buffer.loadReplaysFromPersistentStore()
        XCTAssertEqual(buffer.batchCount(), 41)  // every 5th of 51 pruned from store
    }

    func test_writeNewReplay_presistenceDisabledDoesNotPersist() {
        setPersistence(false)
        let buffer = RadarReplayBuffer.sharedInstance
        buffer.writeNewReplayToBuffer(["i": 1])
        buffer.mutableReplayBuffer = []
        buffer.loadReplaysFromPersistentStore()
        XCTAssertEqual(buffer.batchCount(), 0)
    }

    func test_flushReplays_emptyBufferReturnsSuccess() {
        let buffer = RadarReplayBuffer.sharedInstance
        var captured: RadarStatus?
        buffer.flushReplays(withCompletionHandler: nil) { status, _ in captured = status }
        XCTAssertEqual(captured, .success)
    }

    func test_flushReplays_alreadyFlushingReturnsError() {
        let buffer = RadarReplayBuffer.sharedInstance
        buffer.setIsFlushing(true)
        var captured: RadarStatus?
        buffer.flushReplays(withCompletionHandler: nil) { status, _ in captured = status }
        XCTAssertEqual(captured, .errorServer)
    }

    func test_writeNewReplay_persistsAndReloads() throws {
        let sdkConfiguration = RadarSdkConfiguration(dict: [
            "logLevel": "warning",
            "startTrackingOnInitialize": false,
            "trackOnceOnAppOpen": false,
            "usePersistence": true,
            "extendFlushReplays": false,
            "useLogPersistence": false,
            "useRadarModifiedBeacon": false,
            "syncAfterSetUser": false,
        ])
        RadarSettings.sdkConfiguration = sdkConfiguration

        let params: [AnyHashable: Any] = [
            "latitude": 0.1,
            "longitude": 0.1,
            "replayed": true,
            "stateCode": "StateCode",
        ]

        let buffer = RadarReplayBuffer.sharedInstance
        buffer.clearBuffer()
        buffer.writeNewReplayToBuffer(params)

        // wipe in-memory only (persistence remains), then reload from the store
        buffer.mutableReplayBuffer = []
        buffer.loadReplaysFromPersistentStore()

        XCTAssertEqual(buffer.mutableReplayBuffer.count, 1)
        XCTAssertEqual(
            buffer.mutableReplayBuffer.first?.replayParams as NSDictionary?,
            params as NSDictionary
        )
    }

    func test_flushReplays_successRemovesReplaysFromBuffer() {
        setPersistence(false)
        let buffer = RadarReplayBuffer.sharedInstance
        buffer.writeNewReplayToBuffer(["i": 1])
        buffer.writeNewReplayToBuffer(["i": 2])

        let mock = MockRadarSwiftBridge()
        mock.flushStatus = .success
        let original = RadarSwift.bridge
        RadarSwift.bridge = mock
        defer { RadarSwift.bridge = original }

        buffer.flushReplays(withCompletionHandler: nil, completionHandler: nil)
        XCTAssertEqual(buffer.batchCount(), 0)
        XCTAssertEqual(mock.lastFlushedReplays?.count, 2)
    }

    func test_flushReplays_failureWritesReplayParamsBack() {
        setPersistence(false)
        let buffer = RadarReplayBuffer.sharedInstance  // starts empty

        let mock = MockRadarSwiftBridge()
        mock.flushStatus = .errorServer
        let original = RadarSwift.bridge
        RadarSwift.bridge = mock
        defer { RadarSwift.bridge = original }

        var captured: RadarStatus?
        buffer.flushReplays(withCompletionHandler: ["i": 99]) { status, _ in captured = status }

        XCTAssertEqual(captured, .errorServer)
        XCTAssertEqual(buffer.batchCount(), 1)  // failed replay written back
    }
}

final class MockRadarSwiftBridge: NSObject, RadarSwiftBridgeProtocol, @unchecked Sendable {
    var flushStatus: RadarStatus = .success
    private(set) var lastFlushedReplays: [[AnyHashable: Any]]?

    func flushReplaysRequest(
        _ replays: [[AnyHashable: Any]],
        completionHandler: ((RadarStatus, [AnyHashable: Any]?) -> Void)?
    ) {
        lastFlushedReplays = replays
        completionHandler?(flushStatus, nil)
    }

    func flushReplays() {}
    func logOpenedAppConversion() {}
    func geofenceIds() -> [String]? { nil }
    func beaconIds() -> [String]? { nil }
    func placeId() -> String? { nil }
    func lastLocation() -> CLLocation? { nil }
    func isStopped() -> Bool { false }
    func getTripOptions() -> RadarTripOptions? { nil }
    func logCampaignConversion(name: String, metadata: [String: Any], campaign: String?) {}
    func createEvent(dict: [String: Any]) -> RadarEvent? { nil }
    func createUser(dict: [String: Any]) -> RadarUser? { nil }
    func createGeofence(dict: [String: Any]) -> RadarGeofence? { nil }
    func isForeground() -> Bool { false }
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser) {}
    func radarUser() -> RadarUser? { nil }
}
