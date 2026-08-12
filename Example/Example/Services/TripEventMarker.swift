//
//  TripEventMarker.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import RadarSDK

/// A single trip-related event captured for map-pin rendering. Populated
/// by `TripBuilderStore.captureTripEvents(_:forced:)` from the
/// `LogStream.didReceiveEventsPublisher` feed.
struct TripEventMarker: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: RadarEventType
    let timestamp: Date
}
