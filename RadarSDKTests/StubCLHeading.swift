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
    private let _magneticHeading: CLLocationDirection
    private let _trueHeading: CLLocationDirection
    private let _headingAccuracy: CLLocationDirection
    private let _x: CLHeadingComponentValue
    private let _y: CLHeadingComponentValue
    private let _z: CLHeadingComponentValue
    private let _timestamp: Date

    init(
        magneticHeading: CLLocationDirection,
        trueHeading: CLLocationDirection,
        headingAccuracy: CLLocationDirection,
        x: CLHeadingComponentValue,
        y: CLHeadingComponentValue,
        z: CLHeadingComponentValue,
        timestamp: Date
    ) {
        _magneticHeading = magneticHeading
        _trueHeading = trueHeading
        _headingAccuracy = headingAccuracy
        _x = x
        _y = y
        _z = z
        _timestamp = timestamp
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used by tests")
    }

    override var magneticHeading: CLLocationDirection { _magneticHeading }
    override var trueHeading: CLLocationDirection { _trueHeading }
    override var headingAccuracy: CLLocationDirection { _headingAccuracy }
    override var x: CLHeadingComponentValue { _x }
    override var y: CLHeadingComponentValue { _y }
    override var z: CLHeadingComponentValue { _z }
    override var timestamp: Date { _timestamp }
}
