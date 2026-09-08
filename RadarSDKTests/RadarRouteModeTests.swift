//
//  RadarRouteModeTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarRouteModeTests")
struct RadarRouteModeTests {

    @Test("Maps every travel mode to its wire string")
    func mapsEveryMode() {
        let cases: [(RadarRouteMode, String)] = [
            (.foot, "foot"),
            (.bike, "bike"),
            (.car, "car"),
            (.truck, "truck"),
            (.motorbike, "motorbike"),
        ]

        for (mode, expected) in cases {
            #expect(RadarRouteModeUtils.stringForMode(mode) == expected)
        }
    }

    @Test("Returns unknown for a value outside the declared modes")
    func returnsUnknownForUnrecognizedValue() {
        #expect(RadarRouteModeUtils.stringForMode(RadarRouteMode(rawValue: 0)) == "unknown")
        #expect(RadarRouteModeUtils.stringForMode(RadarRouteMode(rawValue: 1 << 5)) == "unknown")
    }

    @Test("Returns unknown for a combined mask rather than picking one bit")
    func returnsUnknownForCombinedMask() {
        #expect(RadarRouteModeUtils.stringForMode([.foot, .car]) == "unknown")
        #expect(RadarRouteModeUtils.stringForMode([.foot, .bike, .car, .truck, .motorbike]) == "unknown")
    }

    @Test("Keeps the RadarRouteModeUtils Objective-C runtime name and selector")
    func preservesObjectiveCContract() throws {
        let utilsClass: AnyClass = try #require(NSClassFromString("RadarRouteModeUtils"))

        #expect(NSStringFromClass(RadarRouteModeUtils.self) == "RadarRouteModeUtils")
        #expect(utilsClass === RadarRouteModeUtils.self)
        #expect(utilsClass.responds(to: NSSelectorFromString("stringForMode:")))
    }

    @Test("Radar.stringForMode still routes through the migrated implementation")
    func radarFacadeMatches() {
        let cases: [(RadarRouteMode, String)] = [
            (.foot, "foot"),
            (.bike, "bike"),
            (.car, "car"),
            (.truck, "truck"),
            (.motorbike, "motorbike"),
        ]

        for (mode, expected) in cases {
            #expect(Radar.stringForMode(mode) == expected)
        }
    }
}
