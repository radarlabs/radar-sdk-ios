//
//  MapView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapKit
import CoreLocation

/// User-facing map tab. Hosts the MKMapView via UIViewRepresentable, with a
/// floating layer-toggle button at the bottom-right that presents the
/// `OverlayPickerSheet`.
struct MapView: View {
    @EnvironmentObject var registry: MapOverlayRegistry
    @State private var isShowingPicker = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MapViewRepresentable(registry: registry)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                floatingButton(systemImage: "arrow.clockwise") {
                    Task { await registry.refreshAll() }
                }
                floatingButton(systemImage: "square.stack.3d.up.fill") {
                    isShowingPicker = true
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
}

#Preview {
    MapView()
        .environmentObject(MapOverlayRegistry())
}

// MARK: - UIViewRepresentable wrapper

/// Wraps MKMapView so SwiftUI can host it. Drives overlay/annotation sync
/// from the registry's published bundles, and forwards delegate calls to
/// the registry for per-source rendering.
struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var registry: MapOverlayRegistry
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        if let saved = Coordinator.loadRegion() {
            map.setRegion(saved, animated: false)
        } else {
            map.userTrackingMode = .follow
        }
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
        Coordinator(registry: registry)
    }
    
    final class Coordinator: NSObject, MKMapViewDelegate {
        let registry: MapOverlayRegistry
        private var refreshTask: Task<Void, Never>?
        
        init(registry: MapOverlayRegistry) {
            self.registry = registry
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
        
        // MARK: - Region persistence
        
        private static let regionDefaultsKey = "mapView.lastRegion"
        
        static func saveRegion(_ region: MKCoordinateRegion) {
            let dict: [String: Double] = [
                "lat": region.center.latitude,
                "lng": region.center.longitude,
                "latDelta": region.span.latitudeDelta,
                "lngDelta": region.span.longitudeDelta
            ]
            UserDefaults.standard.set(dict, forKey: regionDefaultsKey)
        }
        
        static func loadRegion() -> MKCoordinateRegion? {
            guard let dict = UserDefaults.standard.dictionary(forKey: regionDefaultsKey) as? [String: Double],
                  let lat = dict["lat"], let lng = dict["lng"],
                  let latDelta = dict["latDelta"], let lngDelta = dict["lngDelta"] else {
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
                        Toggle(isOn: Binding(
                            get: { registry.isEnabled(source) },
                            set: { _ in registry.toggle(source) }
                        )) {
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
