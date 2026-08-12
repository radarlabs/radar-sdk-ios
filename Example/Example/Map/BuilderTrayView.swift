//
//  BuilderTrayView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Floating tray that lists trip destinations the user has tapped on the
/// map but not yet started a trip for. Supports drag-to-reorder,
/// swipe-to-delete, bulk clear, and a Start Trip CTA whose label adapts
/// to single- vs multi-leg.
struct BuilderTrayView: View {
    @ObservedObject var tripBuilder: TripBuilderStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            destinationsList
            Divider()
            startTripButton
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subsections

    private var header: some View {
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
    }

    private var destinationsList: some View {
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

    // MARK: - Helpers

    private var startButtonLabel: String {
        let count = tripBuilder.selectedDestinations.count
        if count <= 1 { return "Start trip" }
        return "Start multi-leg trip (\(count) legs)"
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
}
