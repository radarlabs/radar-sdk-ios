//
//  TripDestination.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// A user-selected stop in the map-driven trip builder. May come from a
/// tapped geofence (with optional tag/externalId for the SDK call path)
/// or from a raw coordinate.
enum TripDestination: Identifiable, Equatable {
    case geofence(
        id: String,
        tag: String?,
        externalId: String?,
        displayName: String,
        coord: CLLocationCoordinate2D
    )
    case coordinate(CLLocationCoordinate2D, label: String?)

    var id: String {
        switch self {
        case .geofence(let id, _, _, _, _):
            return "geofence:\(id)"
        case .coordinate(let coord, _):
            return String(format: "coord:%.6f:%.6f", coord.latitude, coord.longitude)
        }
    }

    var displayName: String {
        switch self {
        case .geofence(_, _, _, let name, _):
            return name
        case .coordinate(let coord, let label):
            return label ?? String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .geofence(_, _, _, _, let coord): return coord
        case .coordinate(let coord, _): return coord
        }
    }

    static func == (lhs: TripDestination, rhs: TripDestination) -> Bool {
        lhs.id == rhs.id
    }
}
