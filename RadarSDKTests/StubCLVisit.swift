//
//  StubCLVisit.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// `departureDate` defaults to `Date.distantFuture`, which is how Core Location represents a
/// visit that is still in progress — i.e. an arrival.
final class StubCLVisit: CLVisit, @unchecked Sendable {
    private let storedArrivalDate: Date
    private let storedDepartureDate: Date
    private let storedCoordinate: CLLocationCoordinate2D
    private let storedHorizontalAccuracy: CLLocationAccuracy

    init(
        arrivalDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
        departureDate: Date = Date.distantFuture,
        coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.7, longitude: -74.0),
        horizontalAccuracy: CLLocationAccuracy = 10
    ) {
        storedArrivalDate = arrivalDate
        storedDepartureDate = departureDate
        storedCoordinate = coordinate
        storedHorizontalAccuracy = horizontalAccuracy
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used by tests")
    }

    override var arrivalDate: Date { storedArrivalDate }
    override var departureDate: Date { storedDepartureDate }
    override var coordinate: CLLocationCoordinate2D { storedCoordinate }
    override var horizontalAccuracy: CLLocationAccuracy { storedHorizontalAccuracy }
}
