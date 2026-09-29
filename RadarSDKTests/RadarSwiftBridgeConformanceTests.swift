//
//  RadarSwiftBridgeConformanceTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import Testing

@testable import RadarSDK

/// `RadarSwiftBridgeProtocol` is declared separately in Swift and Objective-C, and the ObjC
/// `RadarSwiftBridge` class only conforms to the ObjC copy. If a Swift method's generated selector
/// differs from the ObjC implementation, calling it through `RadarSwift.bridge` crashes with an
/// unrecognized selector. Tests that use `MockRadarSwiftBridge` can't catch that, so check the real
/// class against every selector in the Swift protocol.
@Suite("RadarSwiftBridge conformance")
struct RadarSwiftBridgeConformanceTests {

    @Test("RadarSwiftBridge implements every selector in the Swift RadarSwiftBridgeProtocol")
    func objcBridgeImplementsSwiftProtocolSelectors() throws {
        let bridgeClass: AnyClass = try #require(NSClassFromString("RadarSwiftBridge"))
        let swiftProtocol: Protocol = RadarSwiftBridgeProtocol.self

        var count: UInt32 = 0
        let descriptions = try #require(protocol_copyMethodDescriptionList(swiftProtocol, true, true, &count))
        defer { free(descriptions) }

        let selectors = (0..<Int(count)).compactMap { descriptions[$0].name }
        #expect(!selectors.isEmpty)

        let missing = selectors.filter { !bridgeClass.instancesRespond(to: $0) }.map(NSStringFromSelector)
        #expect(missing.isEmpty, "RadarSwiftBridge is missing: \(missing.sorted())")
    }
}
