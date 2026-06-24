//
//  NearbyPlacesSource.swift
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

/// Renders places near the map's center via Radar.searchPlaces.
///
/// Pin per place, teal-tinted with a `mappin.circle` glyph. Callout shows the
/// place name as title and category list as subtitle. No filters applied
/// (chains/categories/groups all nil) — for QA we want to see whatever the
/// project considers a place at the scanned coordinates.
///
/// Search radius is derived from the visible map span and capped at the SDK's
/// 10000m maximum. Results capped at 100 (the SDK's typical ceiling).
final class NearbyPlacesSource: MapOverlaySource {
    let id = "nearbyPlaces"
    let name = "Nearby places"
    let icon = "mappin.circle"

    private static let maxRadiusMeters: Double = 10_000
    private static let limit = 100

    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        let radius = Self.searchRadius(for: span)
        let places = await Self.fetchPlaces(near: location, radius: radius)

        let annotations: [MKAnnotation] = places.map { place in
            let pin = NearbyPlaceAnnotation()
            pin.coordinate = place.location.coordinate
            pin.title = place.name
            pin.subtitle = place.categories.joined(separator: ", ")
            pin.placeId = place._id
            return pin
        }
        return MapOverlayBundle(annotations: annotations, overlays: [])
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? { nil }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        guard annotation is NearbyPlaceAnnotation else { return nil }
        let identifier = "NearbyPlaceAnnotation"
        let view =
            mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.markerTintColor = .systemTeal
        view.glyphImage = UIImage(systemName: "mappin.circle.fill")
        view.canShowCallout = true
        return view
    }

    // MARK: - Helpers

    private static func searchRadius(for span: MKCoordinateSpan) -> Int {
        let latMeters = span.latitudeDelta * 111_000
        let halfDiag = latMeters / 2
        return Int(min(maxRadiusMeters, max(100, halfDiag)))
    }

    private static func fetchPlaces(near location: CLLocation, radius: Int) async -> [RadarPlace] {
        await withCheckedContinuation { continuation in
            Radar.searchPlaces(
                near: location,
                radius: Int32(radius),
                chains: nil,
                categories: nil,
                groups: nil,
                countryCodes: nil,
                limit: Int32(limit)
            ) { _, _, places in
                continuation.resume(returning: places ?? [])
            }
        }
    }
}

// MARK: - Tagging subclass

final class NearbyPlaceAnnotation: MKPointAnnotation {
    var placeId: String?
}
