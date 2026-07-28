//
//  StubCLHeading.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Test-only `CLHeading` subclass that overrides the read-only heading fields so the
/// Swift twin can be exercised without real Core Location. Subclassing CLHeading is
/// officially unsupported by Apple, but this is the same technique
/// `TrackingCLLocationManager` uses for `CLLocationManager`.
final class StubCLHeading: CLHeading, @unchecked Sendable {
    private let storedMagneticHeading: CLLocationDirection
    private let storedTrueHeading: CLLocationDirection
    private let storedHeadingAccuracy: CLLocationDirection
    private let storedX: CLHeadingComponentValue
    private let storedY: CLHeadingComponentValue
    private let storedZ: CLHeadingComponentValue
    private let storedTimestamp: Date

    init(
        magneticHeading: CLLocationDirection,
        trueHeading: CLLocationDirection,
        headingAccuracy: CLLocationDirection,
        x: CLHeadingComponentValue,
        y: CLHeadingComponentValue,
        z: CLHeadingComponentValue,
        timestamp: Date
    ) {
        storedMagneticHeading = magneticHeading
        storedTrueHeading = trueHeading
        storedHeadingAccuracy = headingAccuracy
        storedX = x
        storedY = y
        storedZ = z
        storedTimestamp = timestamp
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used by tests")
    }

    override var magneticHeading: CLLocationDirection { storedMagneticHeading }
    override var trueHeading: CLLocationDirection { storedTrueHeading }
    override var headingAccuracy: CLLocationDirection { storedHeadingAccuracy }
    override var x: CLHeadingComponentValue { storedX }
    override var y: CLHeadingComponentValue { storedY }
    override var z: CLHeadingComponentValue { storedZ }
    override var timestamp: Date { storedTimestamp }
}
