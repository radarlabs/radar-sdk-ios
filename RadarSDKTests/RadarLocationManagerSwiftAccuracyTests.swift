//
//  RadarLocationManagerSwiftAccuracyTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarLocationManagerSwiftAccuracyTests")
struct RadarLocationManagerSwiftAccuracyTests {

    // MARK: - clLocationAccuracy(for:)

    @Test("high maps to kCLLocationAccuracyBest")
    func highMapsToBest() {
        #expect(RadarLocationManagerSwift.clLocationAccuracy(for: .high) == kCLLocationAccuracyBest)
    }

    @Test("medium maps to kCLLocationAccuracyHundredMeters")
    func mediumMapsToHundredMeters() {
        #expect(RadarLocationManagerSwift.clLocationAccuracy(for: .medium) == kCLLocationAccuracyHundredMeters)
    }

    @Test("low maps to kCLLocationAccuracyKilometer")
    func lowMapsToKilometer() {
        #expect(RadarLocationManagerSwift.clLocationAccuracy(for: .low) == kCLLocationAccuracyKilometer)
    }
}
