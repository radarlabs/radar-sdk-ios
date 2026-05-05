//
//  MapOverlayRegistry.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Combine
import MapKit
import CoreLocation

/// Central registry of map overlay sources. The MapView observes this object
/// to know what to render. AppDelegate populates it at launch by calling
/// `register(_:)` for each source.
///
/// Enabled-state is persisted to UserDefaults so the user's layer choices
/// survive app restarts.
@MainActor
final class MapOverlayRegistry: ObservableObject {
    
    @Published private(set) var sources: [MapOverlaySource] = []
    @Published var enabledSourceIds: Set<String>
    @Published private(set) var bundlesById: [String: MapOverlayBundle] = [:]
    
    private static let defaultsKey = "mapOverlayRegistry.enabledSourceIds"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let raw = UserDefaults.standard.stringArray(forKey: Self.defaultsKey) ?? []
        self.enabledSourceIds = Set(raw)
        
        $enabledSourceIds
            .dropFirst()
            .sink { ids in
                UserDefaults.standard.set(Array(ids), forKey: Self.defaultsKey)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Source registration
    
    func register(_ source: MapOverlaySource) {
        guard !sources.contains(where: { $0.id == source.id }) else { return }
        sources.append(source)
    }
    
    // MARK: - Enable/disable
    
    func isEnabled(_ source: MapOverlaySource) -> Bool {
        enabledSourceIds.contains(source.id)
    }
    
    func toggle(_ source: MapOverlaySource) {
        if enabledSourceIds.contains(source.id) {
            enabledSourceIds.remove(source.id)
            bundlesById[source.id] = nil
        } else {
            enabledSourceIds.insert(source.id)
        }
    }
    
    // MARK: - Refresh
    
    /// Reload bundles for all enabled sources. Sequential; sources are usually
    /// fast enough that parallelism isn't worth the complexity.
    func refresh(near location: CLLocation, span: MKCoordinateSpan) async {
        for source in sources where enabledSourceIds.contains(source.id) {
            let bundle = await source.loadOverlays(near: location, span: span)
            bundlesById[source.id] = bundle
        }
    }
    
    // MARK: - Aggregated content
    
    var allAnnotations: [MKAnnotation] {
        sources.flatMap { source -> [MKAnnotation] in
            guard enabledSourceIds.contains(source.id) else { return [] }
            return bundlesById[source.id]?.annotations ?? []
        }
    }
    
    var allOverlays: [MKOverlay] {
        sources.flatMap { source -> [MKOverlay] in
            guard enabledSourceIds.contains(source.id) else { return [] }
            return bundlesById[source.id]?.overlays ?? []
        }
    }
    
    // MARK: - Rendering dispatch (called by MapView's delegate)
    
    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        for source in sources where enabledSourceIds.contains(source.id) {
            if let renderer = source.renderer(for: overlay) {
                return renderer
            }
        }
        return nil
    }
    
    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        for source in sources where enabledSourceIds.contains(source.id) {
            if let view = source.view(for: annotation, in: mapView) {
                return view
            }
        }
        return nil
    }
}
