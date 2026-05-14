//
//  GeofenceOverlay.swift
//  Example
//
//  Created by Alan Charles on 5/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

/// Common metadata exposed by any map overlay that represents a geofence,
/// regardless of which source produced it or whether it renders as a circle
/// or polygon. Tap-handling in `MapView` uses this to convert a hit overlay
/// into a `TripDestination` without caring about the concrete subclass.
protocol GeofenceOverlay: AnyObject {
    var geofenceId: String? { get }
    var tag: String? { get }
    var externalId: String? { get }
    var displayName: String? { get }
    var centerCoord: CLLocationCoordinate2D { get }
}

extension GeofenceOverlay {
    /// Returns a TripDestination for this geofence, or nil if essential
    /// metadata (the Radar id) is missing.
    func tripDestination() -> TripDestination? {
        guard let id = geofenceId else { return nil }
        let name = displayName ?? tag ?? externalId ?? id
        return .geofence(
            id: id,
            tag: tag,
            externalId: externalId,
            displayName: name,
            coord: centerCoord
        )
    }
}
