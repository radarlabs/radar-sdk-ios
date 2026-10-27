//
//  RadarLocationManagerSwiftHostConformanceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import Testing

@testable import RadarSDK

/// `RadarLocationManager` conforms to the Swift `RadarLocationManagerSwiftHost` protocol from
/// Objective-C, and several members map to existing ObjC methods only through hand-written
/// `@objc(...)` selectors. Clang only warns when a class extension misses a protocol method, and the
/// Swift-twin tests use `TrackingRadarLocationManagerHost`, so a selector mismatch would crash with
/// an unrecognized selector only at runtime. Check the real class against every selector instead.
@Suite("RadarLocationManagerSwiftHost conformance")
struct RadarLocationManagerHostConformanceTests {

    @Test("RadarLocationManager implements every selector in RadarLocationManagerSwiftHost")
    func locationManagerImplementsHostSelectors() throws {
        let swiftProtocol: Protocol = RadarLocationManagerSwiftHost.self

        var count: UInt32 = 0
        let descriptions = try #require(protocol_copyMethodDescriptionList(swiftProtocol, true, true, &count))
        defer { free(descriptions) }

        let selectors = (0..<Int(count)).compactMap { descriptions[$0].name }
        #expect(!selectors.isEmpty)

        let missing = selectors.filter { !RadarLocationManager.instancesRespond(to: $0) }.map(NSStringFromSelector)
        #expect(missing.isEmpty, "RadarLocationManager is missing: \(missing.sorted())")
    }
}
