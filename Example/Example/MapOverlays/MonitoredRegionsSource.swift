//
//  MonitoredRegionsSource.swift
//  Example
//
//  Created by Alan Charles on 5/5/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import MapKit
import UIKit

/// Renders the OS-level monitored regions as colored circles. Replicates the
/// previous MapView's behavior:
/// - identifiers containing "bubble" → blue (sync regions)
/// - everything else → orange (active geofences)
///
/// `CLLocationManager.monitoredRegions` is a snapshot of what the SDK has asked
/// the OS to monitor. The source reads it lazily on each `loadOverlays` call;
/// the registry triggers refreshes on map region change and explicit refresh.
final class MonitoredRegionsSource: MapOverlaySource {
    let id = "monitoredRegions"
    let name = "Monitored regions"
    let icon = "circle.dashed"

    private let locationManager = CLLocationManager()

    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        let regions = locationManager.monitoredRegions.compactMap { $0 as? CLCircularRegion }
        let circles: [MKOverlay] = regions.map { region in
            let circle = MonitoredRegionCircle(center: region.center, radius: region.radius)
            circle.isBubble = region.identifier.contains("bubble")
            return circle
        }
        return MapOverlayBundle(annotations: [], overlays: circles)
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        guard let circle = overlay as? MonitoredRegionCircle else { return nil }
        let renderer = MKCircleRenderer(circle: circle)
        let color: UIColor = circle.isBubble ? .systemBlue : .systemOrange
        renderer.fillColor = color.withAlphaComponent(0.2)
        renderer.strokeColor = color
        renderer.lineWidth = 2
        return renderer
    }
}

/// Tagging subclass so the renderer can distinguish this source's circles
/// from any other source's. Also carries the bubble vs geofence distinction
/// for tinting.
final class MonitoredRegionCircle: MKCircle {
    var isBubble: Bool = false
}
