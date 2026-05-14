//
//  NearbyGeofencesSource.swift
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

/// Renders geofences near the map's center via Radar.searchGeofences.
///
/// Both circular and polygonal geofences are supported — the SDK returns
/// `RadarCircleGeometry` or `RadarPolygonGeometry` and this source casts
/// accordingly. Each geofence also gets a green pin annotation at its center
/// with the description as the callout title and the tag as the subtitle.
///
/// Search radius is derived from the visible map span and capped at the SDK's
/// 10000m maximum. Results are capped at 100 (the SDK ceiling when
/// `includeGeometry: true`); pan to a different area to discover more.
final class NearbyGeofencesSource: MapOverlaySource {
    let id = "nearbyGeofences"
    let name = "Nearby geofences"
    let icon = "mappin.and.ellipse"

    /// SDK's max accepted radius.
    private static let maxRadiusMeters: Double = 10_000

    /// SDK's max result count when geometry is included.
    private static let limit = 100

    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        let radius = Self.searchRadius(for: span)
        let geofences = await Self.fetchGeofences(near: location, radius: radius)

        var annotations: [MKAnnotation] = []
        var overlays: [MKOverlay] = []

        for geofence in geofences {
            switch geofence.geometry {
            case let circle as RadarCircleGeometry:
                let mkCircle = NearbyGeofenceCircle(
                    center: circle.center.coordinate,
                    radius: circle.radius
                )
                mkCircle.geofenceId = geofence._id
                mkCircle.tag = geofence.tag
                mkCircle.externalId = geofence.externalId
                mkCircle.displayName = geofence.__description
                mkCircle.centerCoord = circle.center.coordinate
                overlays.append(mkCircle)
            case let polygon as RadarPolygonGeometry:
                if let coords = polygon._coordinates, !coords.isEmpty {
                    let mapCoords = coords.map { $0.coordinate }
                    let mkPoly = NearbyGeofencePolygon(coordinates: mapCoords, count: mapCoords.count)
                    mkPoly.geofenceId = geofence._id
                    mkPoly.tag = geofence.tag
                    mkPoly.externalId = geofence.externalId
                    mkPoly.displayName = geofence.__description
                    mkPoly.centerCoord = polygon.center.coordinate
                    overlays.append(mkPoly)
                }
            default:
                break
            }
        }

        return MapOverlayBundle(annotations: annotations, overlays: overlays)
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        if let circle = overlay as? NearbyGeofenceCircle {
            return tinted(MKCircleRenderer(circle: circle))
        }
        if let polygon = overlay as? NearbyGeofencePolygon {
            return tinted(MKPolygonRenderer(polygon: polygon))
        }
        return nil
    }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        guard annotation is NearbyGeofenceAnnotation else { return nil }
        let identifier = "NearbyGeofenceAnnotation"
        let view =
            mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.markerTintColor = .systemGreen
        view.glyphImage = UIImage(systemName: "mappin")
        view.canShowCallout = true
        return view
    }

    // MARK: - Helpers

    private func makePin(at coordinate: CLLocationCoordinate2D, geofence: RadarGeofence) -> NearbyGeofenceAnnotation {
        let pin = NearbyGeofenceAnnotation()
        pin.coordinate = coordinate
        pin.title = geofence.__description
        pin.subtitle = geofence.tag
        pin.geofenceId = geofence._id
        return pin
    }

    /// Apply the source's standard green tint to any MKOverlayPathRenderer.
    private func tinted<R: MKOverlayPathRenderer>(_ renderer: R) -> R {
        renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.15)
        renderer.strokeColor = .systemGreen
        renderer.lineWidth = 2
        return renderer
    }

    /// Convert visible-region span to a search radius in meters, capped at the
    /// SDK's max. Span deltas are in degrees; 1° latitude ≈ 111km. Using
    /// latitude is conservative (longitude shrinks at higher latitudes); we
    /// want roughly half the visible diagonal so the fetch covers what's on
    /// screen plus a small margin.
    private static func searchRadius(for span: MKCoordinateSpan) -> Int {
        let latMeters = span.latitudeDelta * 111_000
        let halfDiag = latMeters / 2
        return Int(min(maxRadiusMeters, max(100, halfDiag)))
    }

    /// Bridge the SDK's callback to async via continuation.
    private static func fetchGeofences(near location: CLLocation, radius: Int) async -> [RadarGeofence] {
        await withCheckedContinuation { continuation in
            Radar.searchGeofences(
                near: location,
                radius: Int32(radius),
                tags: nil,
                metadata: nil,
                limit: Int32(limit),
                includeGeometry: true
            ) { _, _, geofences in
                continuation.resume(returning: geofences ?? [])
            }
        }
    }
}

// MARK: - Tagging subclasses

/// MKCircle subclass that identifies overlays produced by NearbyGeofencesSource.
final class NearbyGeofenceCircle: MKCircle, GeofenceOverlay {
    var geofenceId: String?
    var tag: String?
    var externalId: String?
    var displayName: String?
    var centerCoord: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
}

/// MKPolygon subclass that identifies overlays produced by NearbyGeofencesSource.
final class NearbyGeofencePolygon: MKPolygon, GeofenceOverlay {
    var geofenceId: String?
    var tag: String?
    var externalId: String?
    var displayName: String?
    var centerCoord: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
}

/// MKPointAnnotation subclass for callout marker pins.
final class NearbyGeofenceAnnotation: MKPointAnnotation {
    var geofenceId: String?
}
