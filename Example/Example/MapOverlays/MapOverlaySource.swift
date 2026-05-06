//
//  MapOverlaySource.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

/// A bundle of map content produced by a single overlay source.
struct MapOverlayBundle {
    var annotations: [MKAnnotation]
    var overlays: [MKOverlay]
    
    static let empty = MapOverlayBundle(annotations: [], overlays: [])
    
    var isEmpty: Bool { annotations.isEmpty && overlays.isEmpty }
}

/// A single producer of map content that can be toggled on/off independently.
///
/// Sources are stateless from the registry's perspective: the registry calls
/// `loadOverlays(near:span:)` whenever it wants fresh data (on enable, on
/// region change, on manual refresh). The source returns an `MapOverlayBundle`
/// of annotations and overlays to render.
///
/// Each source also owns its rendering: the map view's `MKMapViewDelegate`
/// iterates registered sources to find one that produced a given overlay or
/// annotation. This keeps each source self-contained — adding a new source is
/// one new file plus one line in `AppDelegate`.
///
/// Examples:
/// - `MonitoredRegionsSource` — `CLLocationManager.monitoredRegions`
/// - `NearbyGeofencesSource` — `Radar.searchGeofences(...)`
/// - `NearbyPlacesSource` — `Radar.searchPlaces(...)`
/// - `SyncedRegionSource` — SDK-cached sync region + entities
/// - `TripDestinationSource` — active trip's destination(s)
///
/// Note: there is no public `Radar.searchBeacons(...)` API. Synced beacons
/// surface via `SyncedRegionSource`; live-ranged beacons would require a
/// separate source subscribing to `RadarUser.beacons` updates.
protocol MapOverlaySource: AnyObject {
    /// Stable identifier; persisted to UserDefaults for enabled-state.
    var id: String { get }
    
    /// User-facing label for the layer-toggle UI.
    var name: String { get }
    
    /// SF Symbol name for the layer-toggle UI.
    var icon: String { get }
    
    /// Fetch overlays for the given visible region.
    ///
    /// Synchronous sources (CLLocationManager state) return immediately;
    /// async sources (Radar.search*) bridge their completion handlers via
    /// `withCheckedContinuation`. Errors are handled internally — return
    /// `.empty` on failure and surface to the console via LogStream if useful.
    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle
    
    /// Provide a renderer for an overlay this source produced. Return nil if
    /// the overlay was not produced by this source — the registry will try
    /// the next source.
    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer?
    
    /// Provide a view for an annotation this source produced. Return nil if
    /// the annotation was not produced by this source.
    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView?
}

extension MapOverlaySource {
    /// Default: source produces no annotations.
    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? { nil }
}
