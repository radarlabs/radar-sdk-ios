//
//  MapView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// User-facing map tab. Hosts the MKMapView via `MapViewRepresentable` and
/// stacks context-sensitive trip-builder overlays on top: pending-hit
/// confirmation → builder tray → active-trip bar.
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
                    PendingHitOverlayView(tripBuilder: tripBuilder, destination: hit)
                } else if let trip = tripBuilder.activeTrip {
                    ActiveTripBarView(tripBuilder: tripBuilder, trip: trip)
                } else if !tripBuilder.selectedDestinations.isEmpty {
                    BuilderTrayView(tripBuilder: tripBuilder)
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
