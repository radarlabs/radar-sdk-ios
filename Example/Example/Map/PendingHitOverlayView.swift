//
//  PendingHitOverlay.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI

/// Confirmation card shown when the user taps a geofence on the map.
/// Lets them add or remove the destination from the trip builder, or cancel.
struct PendingHitOverlayView: View {
    @ObservedObject var tripBuilder: TripBuilderStore
    let destination: TripDestination

    var body: some View {
        let isSelected = tripBuilder.isSelected(destination.id)
        let primaryLabel = isSelected ? "Remove from trip" : "Add to trip"
        let primaryColor: Color = isSelected ? .red : .accentColor

        return VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            actionRow(primaryLabel: primaryLabel, primaryColor: primaryColor)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subsections

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let message = pendingHitMessage(for: destination) {
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
    }

    private func actionRow(primaryLabel: String, primaryColor: Color) -> some View {
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

    // MARK: - Helpers

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
}
