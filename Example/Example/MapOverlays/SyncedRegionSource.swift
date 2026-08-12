//
//  SyncedRegionSource.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import RadarSDK
import UIKit

/// Renders the SDK's locally-cached synced region and the entities inside it.
///
/// "Synced data" is the SDK's local mirror of nearby geofences/places/beacons,
/// fetched on-device for sync-based event detection (`syncLocations: .events`
/// mode). It's distinct from `Radar.searchGeofences(...)` (server query) —
/// for that, use `NearbyGeofencesSource`.
///
/// All synced overlays/annotations share a purple accent so the layer reads
/// as a single conceptual group. The region boundary itself uses a dashed
/// gray stroke (it's a boundary, not a detection zone).
final class SyncedRegionSource: MapOverlaySource {
    let id = "syncedRegion"
    let name = "Synced region & entities"
    let icon = "circle.dotted"

    private static let accent = UIColor.systemPurple

    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        var annotations: [MKAnnotation] = []
        var overlays: [MKOverlay] = []

        // Region boundary
        if let region = RadarSyncManager.getSyncedRegion() {
            overlays.append(SyncedRegionBoundaryCircle(center: region.center, radius: region.radius))
        }

        // Synced geofences (circles + polygons)
        for geofence in RadarSyncManager.getSyncedGeofences() {
            let displayName = geofence.description
            switch geofence.geometry {
            case .circle(let center, let radius):
                let circle = SyncedGeofenceCircle(center: center, radius: radius)
                circle.geofenceId = geofence.id
                circle.tag = geofence.tag
                circle.externalId = geofence.externalId
                circle.displayName = displayName
                circle.centerCoord = center
                overlays.append(circle)
            case .polygon(let coords, let center, _):
                guard !coords.isEmpty else { continue }
                let polygon = SyncedGeofencePolygon(coordinates: coords, count: coords.count)
                polygon.geofenceId = geofence.id
                polygon.tag = geofence.tag
                polygon.externalId = geofence.externalId
                polygon.displayName = displayName
                polygon.centerCoord = center
                overlays.append(polygon)
            }
        }

        // Synced places
        for place in RadarSyncManager.getSyncedPlaces() {
            let pin = SyncedPlaceAnnotation()
            pin.coordinate = place.location
            pin.title = place.name
            pin.subtitle = place.categories.joined(separator: ", ")
            pin.placeId = place.id
            annotations.append(pin)
        }

        // Synced beacons (skip those without a location — nothing to plot)
        for beacon in RadarSyncManager.getSyncedBeacons() {
            guard let coordinate = beacon.location else { continue }
            let pin = SyncedBeaconAnnotation()
            pin.coordinate = coordinate
            pin.title = beacon.description ?? "Beacon"
            pin.subtitle = "\(beacon.uuid):\(beacon.major):\(beacon.minor)"
            pin.beaconId = beacon.id
            annotations.append(pin)
        }

        return MapOverlayBundle(annotations: annotations, overlays: overlays)
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        if let boundary = overlay as? SyncedRegionBoundaryCircle {
            let renderer = MKCircleRenderer(circle: boundary)
            renderer.fillColor = nil
            renderer.strokeColor = .systemGray
            renderer.lineWidth = 3
            renderer.lineDashPattern = [8, 6]
            return renderer
        }
        if let circle = overlay as? SyncedGeofenceCircle {
            return tinted(MKCircleRenderer(circle: circle))
        }
        if let polygon = overlay as? SyncedGeofencePolygon {
            return tinted(MKPolygonRenderer(polygon: polygon))
        }
        return nil
    }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        if annotation is SyncedGeofenceAnnotation {
            return makeMarker(
                for: annotation, in: mapView,
                identifier: "SyncedGeofencePin", glyph: "mappin")
        }
        if annotation is SyncedPlaceAnnotation {
            return makeMarker(
                for: annotation, in: mapView,
                identifier: "SyncedPlacePin", glyph: "star.fill")
        }
        if annotation is SyncedBeaconAnnotation {
            return makeMarker(
                for: annotation, in: mapView,
                identifier: "SyncedBeaconPin", glyph: "wifi")
        }
        return nil
    }

    // MARK: - Helpers

    private func makeGeofencePin(
        at coordinate: CLLocationCoordinate2D,
        geofence: RadarSyncedGeofenceSnapshot
    ) -> SyncedGeofenceAnnotation {
        let pin = SyncedGeofenceAnnotation()
        pin.coordinate = coordinate
        pin.title = geofence.description
        pin.subtitle = geofence.tag
        pin.geofenceId = geofence.id
        return pin
    }

    private func tinted<R: MKOverlayPathRenderer>(_ renderer: R) -> R {
        renderer.fillColor = Self.accent.withAlphaComponent(0.15)
        renderer.strokeColor = Self.accent
        renderer.lineWidth = 2
        return renderer
    }

    private func makeMarker(
        for annotation: MKAnnotation,
        in mapView: MKMapView,
        identifier: String,
        glyph: String
    ) -> MKAnnotationView? {
        let view =
            mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.markerTintColor = Self.accent
        view.glyphImage = UIImage(systemName: glyph)
        view.canShowCallout = true
        return view
    }
}

// MARK: - Tagging subclasses

/// The big dashed-gray boundary circle for the synced region itself.
final class SyncedRegionBoundaryCircle: MKCircle {}

final class SyncedGeofenceCircle: MKCircle, GeofenceOverlay {
    var geofenceId: String?
    var tag: String?
    var externalId: String?
    var displayName: String?
    var centerCoord: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
}

final class SyncedGeofencePolygon: MKPolygon, GeofenceOverlay {
    var geofenceId: String?
    var tag: String?
    var externalId: String?
    var displayName: String?
    var centerCoord: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
}

final class SyncedGeofenceAnnotation: MKPointAnnotation {
    var geofenceId: String?
}

final class SyncedPlaceAnnotation: MKPointAnnotation {
    var placeId: String?
}

final class SyncedBeaconAnnotation: MKPointAnnotation {
    var beaconId: String?
}
