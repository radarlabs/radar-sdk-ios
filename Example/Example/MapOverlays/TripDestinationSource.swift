//
//  TripDestinationSource.swift
//  Example
//
//  Created by Alan Charles on 5/6/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import RadarSDK
import UIKit

/// Renders the active trip's destination(s) as red flag pins.
///
/// - Single-destination trips: one pin at `trip.destinationLocation` with the
///   destination geofence tag/externalId in the callout.
/// - Multi-destination trips: one pin per leg with a destination location.
///   The active leg (matching `trip.currentLegId`) is shown filled; other
///   legs are dimmer.
///
/// Trip data is read on each `loadOverlays` call via `Radar.getTrip()`. Pan
/// the map to refresh, or use the floating refresh button (10f). Live trip
/// state changes from SDK callbacks would benefit from an
/// invalidation-publisher hook; deferred polish.
final class TripDestinationSource: MapOverlaySource {
    let id = "tripDestination"
    let name = "Active trip"
    let icon = "flag.fill"

    var isTripModeWhitelisted: Bool { true }

    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        guard let trip = Radar.getTrip() else { return .empty }

        var annotations: [MKAnnotation] = []

        if let legs = trip.legs, !legs.isEmpty {
            // Multi-destination trip — one pin per leg with a known destination.
            // Today, only coordinate-based legs expose a known location at the
            // example-app surface (geofence/address legs would need extra
            // resolution). Render whatever's available.
            for (index, leg) in legs.enumerated() {
                guard leg.hasCoordinates else { continue }
                let pin = TripDestinationAnnotation()
                pin.coordinate = leg.coordinates
                pin.title = "Leg \(index + 1)"
                pin.subtitle = legSubtitle(for: leg)
                pin.legId = leg._id
                pin.isActive = (leg._id != nil && leg._id == trip.currentLegId)
                annotations.append(pin)
            }
        } else if let dest = trip.destinationLocation {
            // Single-destination trip.
            let pin = TripDestinationAnnotation()
            pin.coordinate = dest.coordinate
            pin.title = trip.destinationGeofenceTag ?? "Destination"
            pin.subtitle = trip.destinationGeofenceExternalId ?? trip._id
            pin.isActive = true
            annotations.append(pin)
        }

        return MapOverlayBundle(annotations: annotations, overlays: [])
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? { nil }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        guard let pin = annotation as? TripDestinationAnnotation else { return nil }
        let identifier = "TripDestinationAnnotation"
        let view =
            mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.markerTintColor = pin.isActive ? .systemRed : UIColor.systemRed.withAlphaComponent(0.5)
        view.glyphImage = UIImage(systemName: "flag.fill")
        view.canShowCallout = true
        return view
    }

    // MARK: - Helpers

    private func legSubtitle(for leg: RadarTripLeg) -> String {
        let statusName = RadarTripLeg.string(for: leg.status)
        if let geofenceTag = leg.destinationGeofenceTag {
            return "\(statusName) · \(geofenceTag)"
        }
        if let address = leg.address {
            return "\(statusName) · \(address)"
        }
        return statusName
    }
}

// MARK: - Tagging subclass

final class TripDestinationAnnotation: MKPointAnnotation {
    var legId: String?
    var isActive: Bool = false
}
