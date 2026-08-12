//
//  MapOverlayRegistry.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import MapKit

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
    @Published var isInTripMode: Bool = false

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

    /// Whether a source should render right now, taking trip-mode override into account.
    private func isActuallyEnabled(_ source: MapOverlaySource) -> Bool {
        if isInTripMode {
            return source.isTripModeWhitelisted
        }
        return enabledSourceIds.contains(source.id)
    }

    // MARK: - Refresh

    private(set) var lastKnownLocation: CLLocation?
    private(set) var lastKnownSpan: MKCoordinateSpan?

    func refreshAll() async {
        guard let location = lastKnownLocation, let span = lastKnownSpan else { return }
        await refresh(near: location, span: span)
    }

    func refresh(near location: CLLocation, span: MKCoordinateSpan) async {
        lastKnownLocation = location
        lastKnownSpan = span
        for source in sources where isActuallyEnabled(source) {
            let bundle = await source.loadOverlays(near: location, span: span)
            bundlesById[source.id] = bundle
        }
    }

    func refreshSource(_ id: String) async {
        guard let source = sources.first(where: { $0.id == id }),
            isActuallyEnabled(source),
            let location = lastKnownLocation,
            let span = lastKnownSpan
        else { return }
        let bundle = await source.loadOverlays(near: location, span: span)
        bundlesById[id] = bundle
    }

    // MARK: - Aggregated content

    var allAnnotations: [MKAnnotation] {
        sources.flatMap { source -> [MKAnnotation] in
            guard isActuallyEnabled(source) else { return [] }
            return bundlesById[source.id]?.annotations ?? []
        }
    }

    var allOverlays: [MKOverlay] {
        sources.flatMap { source -> [MKOverlay] in
            guard isActuallyEnabled(source) else { return [] }
            return bundlesById[source.id]?.overlays ?? []
        }
    }

    // MARK: - Rendering dispatch (called by MapView's delegate)

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        for source in sources where isActuallyEnabled(source) {
            if let renderer = source.renderer(for: overlay) {
                return renderer
            }
        }
        return nil
    }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        for source in sources where isActuallyEnabled(source) {
            if let view = source.view(for: annotation, in: mapView) {
                return view
            }
        }
        return nil
    }

    /// Drop any cached bundle for a source. Used when a data-driven source's
    /// state is reset (e.g., trip ends and visualization arrays are cleared).
    func clearBundle(for id: String) {
        bundlesById[id] = nil
    }
}
