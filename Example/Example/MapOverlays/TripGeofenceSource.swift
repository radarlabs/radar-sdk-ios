//
//  TripGeofenceSource.swift
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

/// Resolves and renders the actual geofence shapes for an active trip's legs,
/// colored by leg status:
///
/// - Current leg: bright orange, thick stroke, solid.
/// - Pending legs (future): muted blue, normal stroke.
/// - Completed legs: gray, thin dashed stroke.
/// - Canceled / expired legs: muted red, thin dashed stroke.
///
/// Geofence shapes aren't returned in the trip payload itself — we fetch them
/// once per unique tag via `Radar.searchGeofences(tags:)`, filter by
/// externalId client-side, and cache the result for the trip's lifetime.
final class TripGeofencesSource: MapOverlaySource {
    let id = "tripGeofences"
    let name = "Trip leg geofences"
    let icon = "circle.dashed"
    var isTripModeWhitelisted: Bool { true }

    private let store: TripBuilderStore

    /// Per-trip cache. Key = "tag|externalId". Invalidated whenever
    /// `trip._id` changes.
    private var resolved: [String: RadarGeofence] = [:]
    private var cachedForTripId: String?

    init(store: TripBuilderStore) {
        self.store = store
    }

    @MainActor
    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        guard let trip = store.activeTrip else {
            invalidateCache(for: nil)
            return .empty
        }

        invalidateCache(for: trip._id)
        let needs = collectNeeds(from: trip)
        await resolveMissing(needs: needs, near: location)

        var overlays: [MKOverlay] = []
        for need in needs {
            let key = cacheKey(tag: need.tag, externalId: need.externalId)
            guard let geo = resolved[key] else { continue }

            switch geo.geometry {
            case let circle as RadarCircleGeometry:
                let mk = TripLegCircle(
                    center: circle.center.coordinate,
                    radius: circle.radius
                )
                mk.legStatus = need.status
                mk.isCurrentLeg = need.isCurrentLeg
                overlays.append(mk)
            case let polygon as RadarPolygonGeometry:
                if let coords = polygon._coordinates, !coords.isEmpty {
                    let mapCoords = coords.map { $0.coordinate }
                    let mk = TripLegPolygon(coordinates: mapCoords, count: mapCoords.count)
                    mk.legStatus = need.status
                    mk.isCurrentLeg = need.isCurrentLeg
                    overlays.append(mk)
                }
            default:
                break
            }
        }

        return MapOverlayBundle(annotations: [], overlays: overlays)
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        if let circle = overlay as? TripLegCircle {
            return styled(
                MKCircleRenderer(circle: circle),
                status: circle.legStatus,
                isCurrent: circle.isCurrentLeg
            )
        }
        if let polygon = overlay as? TripLegPolygon {
            return styled(
                MKPolygonRenderer(polygon: polygon),
                status: polygon.legStatus,
                isCurrent: polygon.isCurrentLeg
            )
        }
        return nil
    }

    // MARK: - Cache

    private func invalidateCache(for tripId: String?) {
        if cachedForTripId != tripId {
            resolved.removeAll()
            cachedForTripId = tripId
        }
    }

    private func cacheKey(tag: String, externalId: String) -> String {
        "\(tag)|\(externalId)"
    }

    // MARK: - Needs

    private struct LegNeed {
        let tag: String
        let externalId: String
        let status: RadarTripLegStatus
        let isCurrentLeg: Bool
    }

    private func collectNeeds(from trip: RadarTrip) -> [LegNeed] {
        var needs: [LegNeed] = []

        if let legs = trip.legs, !legs.isEmpty {
            for leg in legs {
                guard let tag = leg.destinationGeofenceTag, !tag.isEmpty,
                    let extId = leg.destinationGeofenceExternalId, !extId.isEmpty
                else { continue }
                let isCurrent = leg._id != nil && leg._id == trip.currentLegId
                needs.append(
                    LegNeed(
                        tag: tag,
                        externalId: extId,
                        status: leg.status,
                        isCurrentLeg: isCurrent
                    ))
            }
        } else if let tag = trip.destinationGeofenceTag, !tag.isEmpty,
            let extId = trip.destinationGeofenceExternalId, !extId.isEmpty
        {
            // Single-destination trip — treat as current.
            needs.append(
                LegNeed(
                    tag: tag,
                    externalId: extId,
                    status: .started,
                    isCurrentLeg: true
                ))
        }

        return needs
    }

    // MARK: - Fetching

    private func resolveMissing(needs: [LegNeed], near location: CLLocation) async {
        let missingTags: Set<String> = Set(
            needs.compactMap { need -> String? in
                let key = cacheKey(tag: need.tag, externalId: need.externalId)
                return resolved[key] == nil ? need.tag : nil
            })

        for tag in missingTags {
            await fetchGeofences(tag: tag, near: location)
        }
    }

    private func fetchGeofences(tag: String, near location: CLLocation) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Radar.searchGeofences(
                near: location,
                radius: Int32(10_000),
                tags: [tag],
                metadata: nil,
                limit: Int32(100),
                includeGeometry: true
            ) { _, _, geofences in
                Task { @MainActor in
                    for geo in geofences ?? [] {
                        guard let extId = geo.externalId else { continue }
                        self.resolved[self.cacheKey(tag: tag, externalId: extId)] = geo
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Styling

    private func styled<R: MKOverlayPathRenderer>(_ renderer: R, status: RadarTripLegStatus, isCurrent: Bool) -> R {
        let style = self.style(for: status, isCurrent: isCurrent)
        renderer.fillColor = style.fill
        renderer.strokeColor = style.stroke
        renderer.lineWidth = style.lineWidth
        if style.dashed {
            renderer.lineDashPattern = [6, 4]
        }
        return renderer
    }

    private struct LegStyle {
        let fill: UIColor
        let stroke: UIColor
        let lineWidth: CGFloat
        let dashed: Bool
    }

    private func style(for status: RadarTripLegStatus, isCurrent: Bool) -> LegStyle {
        if isCurrent {
            let stroke = UIColor.systemOrange
            return LegStyle(
                fill: stroke.withAlphaComponent(0.25),
                stroke: stroke,
                lineWidth: 3,
                dashed: false
            )
        }
        switch status {
        case .completed:
            let stroke = UIColor.systemGray
            return LegStyle(
                fill: stroke.withAlphaComponent(0.10),
                stroke: stroke,
                lineWidth: 1.5,
                dashed: true
            )
        case .canceled, .expired:
            let stroke = UIColor.systemRed.withAlphaComponent(0.6)
            return LegStyle(
                fill: stroke.withAlphaComponent(0.10),
                stroke: stroke,
                lineWidth: 1.5,
                dashed: true
            )
        case .pending, .started, .approaching, .arrived, .unknown:
            let stroke = UIColor.systemBlue.withAlphaComponent(0.7)
            return LegStyle(
                fill: stroke.withAlphaComponent(0.10),
                stroke: stroke,
                lineWidth: 2,
                dashed: false
            )
        @unknown default:
            let stroke = UIColor.systemBlue.withAlphaComponent(0.7)
            return LegStyle(
                fill: stroke.withAlphaComponent(0.10),
                stroke: stroke,
                lineWidth: 2,
                dashed: false
            )
        }
    }
}

// MARK: - Tagging subclasses

final class TripLegCircle: MKCircle {
    var legStatus: RadarTripLegStatus = .unknown
    var isCurrentLeg: Bool = false
}

final class TripLegPolygon: MKPolygon {
    var legStatus: RadarTripLegStatus = .unknown
    var isCurrentLeg: Bool = false
}
