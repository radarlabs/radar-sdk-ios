//
//  RadarReplayTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/30/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import XCTest

@testable import RadarSDK

final class RadarReplayTests: XCTestCase {

    func test_init_storesReplayParams() {
        let params: [AnyHashable: Any] = ["a": 1, "b": "two"]
        let replay = RadarReplay(params: params)
        XCTAssertEqual(replay.replayParams as NSDictionary, params as NSDictionary)
    }

    func test_arrayForReplays_mapsParams() {
        let replays = [RadarReplay(params: ["i": 1]), RadarReplay(params: ["i": 2])]
        let arr = RadarReplay.arrayForReplays(replays)
        XCTAssertEqual(arr?.count, 2)
        XCTAssertEqual(arr?.first as NSDictionary?, ["i": 1] as NSDictionary)
    }

    func test_arrayForReplays_nilReturnsNil() {
        XCTAssertNil(RadarReplay.arrayForReplays(nil))
    }

    func test_isEqual_sameParamsAreEqual() {
        let a = RadarReplay(params: ["x": 1, "y": "z"])
        let b = RadarReplay(params: ["x": 1, "y": "z"])
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hash, b.hash)
    }

    func test_isEqual_differentParamsNotEqual() {
        let a = RadarReplay(params: ["x": 1])
        let b = RadarReplay(params: ["x": 2])
        XCTAssertNotEqual(a, b)
    }

    func test_supportsSecureCoding() {
        XCTAssertTrue(RadarReplay.supportsSecureCoding)
    }

    func test_secureCoding_roundTrip() throws {
        let params: [AnyHashable: Any] = ["lat": 0.1, "replayed": true, "code": "AB"]
        let replay = RadarReplay(params: params)

        let data = try NSKeyedArchiver.archivedData(withRootObject: replay, requiringSecureCoding: true)
        let allowed: [AnyClass] = [RadarReplay.self, NSDictionary.self, NSString.self, NSNumber.self]
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowed, from: data) as? RadarReplay

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.replayParams as NSDictionary?, params as NSDictionary)
    }
}
