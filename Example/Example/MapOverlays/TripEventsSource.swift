//
//  TripEventsSource.swift
//  Example
//
//  Created by Alan Charles on 5/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import RadarSDK
import UIKit

/// Renders one map pin per captured trip event (started, approaching, arrived,
/// stopped, updated). Tapping a pin reveals a callout with the event type and
/// timestamp.
///
/// State lives in `TripBuilderStore.tripEventMarkers`; this source projects it
/// onto the map and is refreshed by the store on each capture.
final class TripEventsSource: MapOverlaySource {
    let id = "tripEvents"
    let name = "Trip events"
    let icon = "mappin.and.ellipse"
    var isTripModeWhitelisted: Bool { true }

    private let store: TripBuilderStore

    init(store: TripBuilderStore) {
        self.store = store
    }

    @MainActor
    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        let markers = store.tripEventMarkers
        guard !markers.isEmpty else { return .empty }

        let annotations: [MKAnnotation] = markers.map { marker in
            let pin = TripEventAnnotation()
            pin.coordinate = marker.coordinate
            pin.title = Self.title(for: marker.type)
            pin.subtitle = Self.subtitle(for: marker)
            pin.markerId = marker.id
            pin.eventType = marker.type
            return pin
        }

        return MapOverlayBundle(annotations: annotations, overlays: [])
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? { nil }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        guard let pin = annotation as? TripEventAnnotation else { return nil }
        let identifier = "TripEventAnnotation"
        let view =
            mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.canShowCallout = true
        view.markerTintColor = .systemPurple
        view.glyphImage = UIImage(systemName: "mappin")
        return view
    }

    // MARK: - Formatting

    private static func title(for type: RadarEventType) -> String {
        let raw = RadarEvent.string(for: type) ?? "event"
        // Strip the "user." prefix, replace underscores with spaces. e.g.
        // "user.started_trip" -> "started trip"
        return
            raw
            .replacingOccurrences(of: "user.", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    private static func subtitle(for marker: TripEventMarker) -> String {
        timestampFormatter.string(from: marker.timestamp)
    }
}

// MARK: - Tagging subclass

final class TripEventAnnotation: MKPointAnnotation {
    var markerId: String?
    var eventType: RadarEventType = .unknown
}
