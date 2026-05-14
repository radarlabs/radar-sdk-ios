//
//  MapViewRepresentable.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import MapKit
import SwiftUI

/// SwiftUI bridge for `MKMapView`. Syncs overlays/annotations from the
/// `MapOverlayRegistry`'s published bundles and forwards MKMapViewDelegate
/// callbacks back into the registry for per-source rendering. Owns map
/// region persistence and the tap-to-build hit-testing path.
struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var registry: MapOverlayRegistry
    @ObservedObject var tripBuilder: TripBuilderStore

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        if let saved = Coordinator.loadRegion() {
            map.setRegion(saved, animated: false)
        } else {
            map.userTrackingMode = .follow
        }
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:)))
        tap.delegate = context.coordinator
        map.addGestureRecognizer(tap)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let desired = registry.allOverlays
        let current = map.overlays
        let toRemove = current.filter { c in !desired.contains(where: { $0 === c as AnyObject }) }
        let toAdd = desired.filter { d in !current.contains(where: { $0 === d as AnyObject }) }
        if !toRemove.isEmpty { map.removeOverlays(toRemove) }
        if !toAdd.isEmpty { map.addOverlays(toAdd) }

        let desiredAnnotations = registry.allAnnotations
        let currentAnnotations = map.annotations.filter { !($0 is MKUserLocation) }
        let annotationsToRemove = currentAnnotations.filter { c in
            !desiredAnnotations.contains(where: { $0 === c as AnyObject })
        }
        let annotationsToAdd = desiredAnnotations.filter { d in
            !currentAnnotations.contains(where: { $0 === d as AnyObject })
        }
        if !annotationsToRemove.isEmpty { map.removeAnnotations(annotationsToRemove) }
        if !annotationsToAdd.isEmpty { map.addAnnotations(annotationsToAdd) }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(registry: registry, tripBuilder: tripBuilder)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        let registry: MapOverlayRegistry
        let tripBuilder: TripBuilderStore
        private var refreshTask: Task<Void, Never>?

        init(registry: MapOverlayRegistry, tripBuilder: TripBuilderStore) {
            self.registry = registry
            self.tripBuilder = tripBuilder
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            return registry.renderer(for: overlay) ?? MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            return registry.view(for: annotation, in: mapView)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            Self.saveRegion(mapView.region)

            refreshTask?.cancel()
            let center = CLLocation(
                latitude: mapView.region.center.latitude,
                longitude: mapView.region.center.longitude
            )
            let span = mapView.region.span
            refreshTask = Task { [registry] in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }
                await registry.refresh(near: center, span: span)
            }
        }

        // MARK: Tap handling

        @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView else { return }
            let tapPoint = recognizer.location(in: mapView)
            let coord = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            if let destination = hitTestGeofence(at: coord, in: mapView) {
                Task { @MainActor in
                    tripBuilder.proposeHit(destination)
                }
            }
        }

        /// Coexist with the map's built-in gestures (pan, zoom). Other taps
        /// (annotation taps, etc.) are not consumed.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            return true
        }

        // MARK: Hit testing

        private func hitTestGeofence(at coord: CLLocationCoordinate2D, in mapView: MKMapView) -> TripDestination? {
            // Top-of-z-order first so overlapping geofences resolve to the topmost one.
            for overlay in mapView.overlays.reversed() {
                guard let geo = overlay as? GeofenceOverlay else { continue }
                if let circle = overlay as? MKCircle,
                    Self.coordinate(coord, isInside: circle)
                {
                    return geo.tripDestination()
                }
                if let polygon = overlay as? MKPolygon,
                    Self.coordinate(coord, isInside: polygon)
                {
                    return geo.tripDestination()
                }
            }
            return nil
        }

        private static func coordinate(_ coord: CLLocationCoordinate2D, isInside circle: MKCircle) -> Bool {
            let center = CLLocation(
                latitude: circle.coordinate.latitude,
                longitude: circle.coordinate.longitude)
            let point = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            return point.distance(from: center) <= circle.radius
        }

        private static func coordinate(_ coord: CLLocationCoordinate2D, isInside polygon: MKPolygon) -> Bool {
            let renderer = MKPolygonRenderer(polygon: polygon)
            let mapPoint = MKMapPoint(coord)
            let rendererPoint = renderer.point(for: mapPoint)
            return renderer.path?.contains(rendererPoint) ?? false
        }

        // MARK: Region persistence

        private static let regionDefaultsKey = "mapView.lastRegion"

        static func saveRegion(_ region: MKCoordinateRegion) {
            let dict: [String: Double] = [
                "lat": region.center.latitude,
                "lng": region.center.longitude,
                "latDelta": region.span.latitudeDelta,
                "lngDelta": region.span.longitudeDelta,
            ]
            UserDefaults.standard.set(dict, forKey: regionDefaultsKey)
        }

        static func loadRegion() -> MKCoordinateRegion? {
            guard let dict = UserDefaults.standard.dictionary(forKey: regionDefaultsKey) as? [String: Double],
                let lat = dict["lat"], let lng = dict["lng"],
                let latDelta = dict["latDelta"], let lngDelta = dict["lngDelta"]
            else {
                return nil
            }
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
            )
        }
    }
}
