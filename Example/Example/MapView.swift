//
//  MapView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import MapKit
import RadarSDK
import SwiftUI

/// User-facing map tab. Hosts the MKMapView via UIViewRepresentable, with a
/// floating layer-toggle button at the bottom-right that presents the
/// `OverlayPickerSheet`.
struct MapView: View {
    @EnvironmentObject var registry: MapOverlayRegistry
    @EnvironmentObject var tripBuilder: TripBuilderStore
    @EnvironmentObject var logStream: LogStream
    @State private var isShowingPicker = false

    var body: some View {
        ZStack {
            MapViewRepresentable(registry: registry, tripBuilder: tripBuilder)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()

                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        floatingButton(systemImage: "arrow.clockwise") {
                            Task { await registry.refreshAll() }
                        }
                        floatingButton(systemImage: "square.stack.3d.up.fill") {
                            isShowingPicker = true
                        }
                    }
                }

                if let hit = tripBuilder.pendingHit {
                    pendingHitOverlay(for: hit)
                } else if let trip = tripBuilder.activeTrip {
                    activeTripBar(for: trip)
                } else if !tripBuilder.selectedDestinations.isEmpty {
                    builderTray
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingPicker) {
            OverlayPickerSheet()
                .environmentObject(registry)
        }
    }

    @ViewBuilder
    private func floatingButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }

    private var startTripButton: some View {
        Button {
            tripBuilder.startTrip()
        } label: {
            Text(startButtonLabel)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(12)
    }

    private var startButtonLabel: String {
        let count = tripBuilder.selectedDestinations.count
        if count <= 1 { return "Start trip" }
        return "Start multi-leg trip (\(count) legs)"
    }

    // MARK: - Builder tray

    private var builderTray: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Destinations (\(tripBuilder.selectedDestinations.count))")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Clear all") {
                    tripBuilder.clear()
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()

            List {
                ForEach(Array(tripBuilder.selectedDestinations.enumerated()), id: \.element.id) { index, dest in
                    HStack(alignment: .center, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                            .frame(width: 16, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(dest.displayName)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let subtitle = subtitle(for: dest) {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                .onMove { from, to in
                    tripBuilder.move(from: from, to: to)
                }
                .onDelete { offsets in
                    tripBuilder.remove(at: offsets)
                }
            }
            .listStyle(.plain)
            .frame(maxHeight: 240)

            Divider()
            startTripButton
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    private func subtitle(for dest: TripDestination) -> String? {
        if case .geofence(_, let tag, let externalId, _, _) = dest {
            var parts: [String] = []
            if let tag = tag, !tag.isEmpty { parts.append("tag: \(tag)") }
            if let extId = externalId, !extId.isEmpty { parts.append("id: \(extId)") }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }

        return nil
    }

    // MARK: - Pending hit overlay

    private func pendingHitOverlay(for dest: TripDestination) -> some View {
        let isSelected = tripBuilder.isSelected(dest.id)
        let primaryLabel = isSelected ? "Remove from trip" : "Add to trip"
        let primaryColor: Color = isSelected ? .red : .accentColor

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dest.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if let message = pendingHitMessage(for: dest) {
                        Text(message)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    tripBuilder.dismissPendingHit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 10)

            Divider()

            HStack(spacing: 8) {
                Button {
                    tripBuilder.dismissPendingHit()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                Button {
                    tripBuilder.confirmPendingHit()
                } label: {
                    Text(primaryLabel)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    private func pendingHitMessage(for dest: TripDestination) -> String? {
        if case .geofence(let id, let tag, let extId, _, _) = dest {
            var parts: [String] = []
            if let tag = tag, !tag.isEmpty { parts.append("tag: \(tag)") }
            if let extId = extId, !extId.isEmpty { parts.append("externalId: \(extId)") }
            parts.append("id: \(id)")
            return parts.joined(separator: "\n")
        }
        return nil
    }

    // MARK: - Active trip bar

    private func activeTripBar(for trip: RadarTrip) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.externalId ?? trip._id)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(Radar.stringForTripStatus(trip.status))
                        .font(.caption)
                        .foregroundColor(tripStatusColor(trip.status))
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            if let leg = currentLeg(for: trip),
                let legs = trip.legs,
                let index = legs.firstIndex(where: { $0._id == leg._id })
            {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Leg \(index + 1) of \(legs.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(RadarTripLeg.string(for: leg.status))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(legStatusColor(leg.status))
                    }
                    Text(legDescription(leg))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()
                HStack(spacing: 6) {
                    advanceButton("→ approaching", status: .approaching)
                    advanceButton("→ arrived", status: .arrived)
                    advanceButton("→ completed", status: .completed)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            if let legs = trip.legs, legs.count > 1 {
                Divider()
                legsDisclosure(legs: legs)
            }

            Divider()
            HStack(spacing: 8) {
                Button {
                    tripBuilder.completeTrip()
                } label: {
                    Text("Complete trip")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
                Button {
                    tripBuilder.cancelTrip()
                } label: {
                    Text("Cancel trip")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    private func advanceButton(_ title: String, status: RadarTripLegStatus) -> some View {
        Button {
            tripBuilder.advanceCurrentLeg(status)
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trip / leg helpers

    private func currentLeg(for trip: RadarTrip) -> RadarTripLeg? {
        guard let currentLegId = trip.currentLegId,
            let legs = trip.legs
        else { return nil }
        return legs.first { $0._id == currentLegId }
    }

    private func legDescription(_ leg: RadarTripLeg) -> String {
        if let tag = leg.destinationGeofenceTag,
            !tag.isEmpty
        {
            let extId = leg.destinationGeofenceExternalId ?? "?"
            return "geofence \(tag)/\(extId)"
        }
        if let address = leg.address {
            return "address \"\(address)\""
        }
        if leg.hasCoordinates {
            return String(
                format: "coords %.5f, %.5f",
                leg.coordinates.latitude,
                leg.coordinates.longitude)
        }
        return "—"
    }

    private func tripStatusColor(_ status: RadarTripStatus) -> Color {
        switch status {
        case .started, .approaching, .arrived: return .blue
        case .completed: return .green
        case .canceled, .expired: return .red
        case .unknown: return .secondary
        @unknown default: return .secondary
        }
    }

    private func legStatusColor(_ status: RadarTripLegStatus) -> Color {
        switch status {
        case .started, .approaching, .arrived: return .blue
        case .completed: return .green
        case .canceled, .expired: return .red
        case .pending, .unknown: return .secondary
        @unknown default: return .secondary
        }
    }

    // MARK: - Legs disclosure

    @ViewBuilder
    private func legsDisclosure(legs: [RadarTripLeg]) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(legs.enumerated()), id: \.offset) { index, leg in
                    legRow(index: index, leg: leg, legs: legs)
                    if index < legs.count - 1 {
                        Divider().padding(.leading, 28)
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            Text("Legs (\(legs.count))")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func legRow(index: Int, leg: RadarTripLeg, legs: [RadarTripLeg]) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(index + 1)")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .frame(width: 16, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(legDescription(leg))
                    .font(.caption)
                    .lineLimit(1)
                Text(RadarTripLeg.string(for: leg.status))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(legStatusColor(leg.status))
            }

            Spacer(minLength: 0)

            if leg.status == .pending, let legId = leg._id {
                HStack(spacing: 4) {
                    legMoveButton(
                        symbol: "arrow.up",
                        enabled: canMoveUp(legIndex: index, in: legs)
                    ) {
                        tripBuilder.moveLeg(legId: legId, direction: .up)
                    }
                    legMoveButton(
                        symbol: "arrow.down",
                        enabled: canMoveDown(legIndex: index, in: legs)
                    ) {
                        tripBuilder.moveLeg(legId: legId, direction: .down)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func legMoveButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.35)
    }

    private func canMoveUp(legIndex: Int, in legs: [RadarTripLeg]) -> Bool {
        guard legIndex > 0 else { return false }
        return legs[legIndex].status == .pending && legs[legIndex - 1].status == .pending
    }

    private func canMoveDown(legIndex: Int, in legs: [RadarTripLeg]) -> Bool {
        guard legIndex < legs.count - 1 else { return false }
        return legs[legIndex].status == .pending && legs[legIndex + 1].status == .pending
    }
}

// MARK: - UIViewRepresentable wrapper

/// Wraps MKMapView so SwiftUI can host it. Drives overlay/annotation sync
/// from the registry's published bundles, and forwards delegate calls to
/// the registry for per-source rendering.
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
        // Sync overlays
        let desired = registry.allOverlays
        let current = map.overlays
        let toRemove = current.filter { c in !desired.contains(where: { $0 === c as AnyObject }) }
        let toAdd = desired.filter { d in !current.contains(where: { $0 === d as AnyObject }) }
        if !toRemove.isEmpty { map.removeOverlays(toRemove) }
        if !toAdd.isEmpty { map.addOverlays(toAdd) }

        // Sync annotations (skip user-location)
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

    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        let registry: MapOverlayRegistry
        let tripBuilder: TripBuilderStore
        private var refreshTask: Task<Void, Never>?

        init(registry: MapOverlayRegistry, tripBuilder: TripBuilderStore) {
            self.registry = registry
            self.tripBuilder = tripBuilder
        }

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

        // MARK: - Tap handling

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
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }

        // MARK: - Hit testing

        private func hitTestGeofence(at coord: CLLocationCoordinate2D, in mapView: MKMapView) -> TripDestination? {
            // Iterate top-of-z-order first so visually overlapping geofences
            // resolve to the topmost one.
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

        // MARK: - Region persistence

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

// MARK: - Layer picker sheet

/// Modal sheet listing every registered source as a Toggle row.
struct OverlayPickerSheet: View {
    @EnvironmentObject var registry: MapOverlayRegistry
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Layers"), footer: footer) {
                    ForEach(registry.sources, id: \.id) { source in
                        Toggle(
                            isOn: Binding(
                                get: { registry.isEnabled(source) },
                                set: { _ in registry.toggle(source) }
                            )
                        ) {
                            Label(source.name, systemImage: source.icon)
                        }
                    }
                }
            }
            .navigationTitle("Map Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var footer: some View {
        Text("Toggle individual data sources. Layer state is persisted across launches.")
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}
