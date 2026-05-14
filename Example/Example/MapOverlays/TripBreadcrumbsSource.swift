//
//  TripBreadcrumbsSource.swift
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

final class TripBreadcrumbsSource: MapOverlaySource {
    let id = "tripBreadcrumbs"
    let name = "Trip breadcrumbs"
    let icon = "point.topleft.down.curvedto.point.bottomright.up.fill"
    var isTripModeWhitelisted: Bool { true }

    private let store: TripBuilderStore

    init(store: TripBuilderStore) {
        self.store = store
    }

    @MainActor
    func loadOverlays(near location: CLLocation, span: MKCoordinateSpan) async -> MapOverlayBundle {
        let coords = store.tripBreadcrumbs
        guard !coords.isEmpty else { return .empty }

        var overlays: [MKOverlay] = []
        var annotations: [MKAnnotation] = []

        if coords.count >= 2 {
            var mutable = coords
            let line = BreadcrumbPolyline(coordinates: &mutable, count: mutable.count)
            overlays.append(line)
        }

        for coord in coords {
            let dot = BreadcrumbAnnotation()
            dot.coordinate = coord
            annotations.append(dot)
        }

        return MapOverlayBundle(annotations: annotations, overlays: overlays)
    }

    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        guard let line = overlay as? BreadcrumbPolyline else { return nil }
        let r = MKPolylineRenderer(polyline: line)
        r.strokeColor = .systemBlue
        r.lineWidth = 3
        r.lineJoin = .round
        r.lineCap = .round
        return r
    }

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        guard annotation is BreadcrumbAnnotation else { return nil }
        let identifier = BreadcrumbAnnotationView.identifier
        let view =
            mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? BreadcrumbAnnotationView
            ?? BreadcrumbAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        return view
    }
}

// MARK: - Tagging types

final class BreadcrumbPolyline: MKPolyline {}
final class BreadcrumbAnnotation: MKPointAnnotation {}

/// Small screen-size dot rendered for each captured breadcrumb. Constant size
/// at any zoom level.
final class BreadcrumbAnnotationView: MKAnnotationView {
    static let identifier = "BreadcrumbAnnotation"
    private static let diameter: CGFloat = 8

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        let size = Self.diameter
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        layer.cornerRadius = size / 2
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        canShowCallout = false
        isUserInteractionEnabled = false
        centerOffset = .zero
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not used") }
}
