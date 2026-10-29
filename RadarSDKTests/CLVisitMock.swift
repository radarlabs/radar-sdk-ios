//
//  CLVisitMock.swift
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

/// A `CLVisit` with the given values, since Core Location doesn't let apps create visits.
final class CLVisitMock: CLVisit, @unchecked Sendable {
    private let mockCoordinate: CLLocationCoordinate2D
    private let mockHorizontalAccuracy: CLLocationAccuracy
    private let mockArrivalDate: Date
    private let mockDepartureDate: Date

    init(
        coordinate: CLLocationCoordinate2D,
        horizontalAccuracy: CLLocationAccuracy,
        arrivalDate: Date,
        departureDate: Date
    ) {
        mockCoordinate = coordinate
        mockHorizontalAccuracy = horizontalAccuracy
        mockArrivalDate = arrivalDate
        mockDepartureDate = departureDate
        super.init()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var coordinate: CLLocationCoordinate2D { mockCoordinate }
    override var horizontalAccuracy: CLLocationAccuracy { mockHorizontalAccuracy }
    override var arrivalDate: Date { mockArrivalDate }
    override var departureDate: Date { mockDepartureDate }
}
