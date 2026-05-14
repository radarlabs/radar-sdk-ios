//
//  ActiveTripBarView.swift
//  Example
//
//  Created by Alan Charles on 5/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

/// Floating control surface for an in-flight trip. Shows the trip header,
/// the current leg with advance-status buttons, an expandable list of all
/// legs (with move-up/down controls for pending ones), and complete/cancel
/// actions.
struct ActiveTripBarView: View {
    @ObservedObject var tripBuilder: TripBuilderStore
    let trip: RadarTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tripHeader

            if let leg = currentLeg,
                let legs = trip.legs,
                let index = legs.firstIndex(where: { $0._id == leg._id })
            {
                Divider()
                currentLegRow(leg: leg, index: index, total: legs.count)
                Divider()
                advanceLegRow
            }

            if let legs = trip.legs, legs.count > 1 {
                Divider()
                legsDisclosure(legs: legs)
            }

            Divider()
            actionRow
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subsections

    private var tripHeader: some View {
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
    }

    private func currentLegRow(leg: RadarTripLeg, index: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Leg \(index + 1) of \(total)")
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
    }

    private var advanceLegRow: some View {
        HStack(spacing: 6) {
            advanceButton("→ approaching", status: .approaching)
            advanceButton("→ arrived", status: .arrived)
            advanceButton("→ completed", status: .completed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var actionRow: some View {
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

    // MARK: - Small buttons

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

    // MARK: - Helpers

    private var currentLeg: RadarTripLeg? {
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

    private func canMoveUp(legIndex: Int, in legs: [RadarTripLeg]) -> Bool {
        guard legIndex > 0 else { return false }
        return legs[legIndex].status == .pending && legs[legIndex - 1].status == .pending
    }

    private func canMoveDown(legIndex: Int, in legs: [RadarTripLeg]) -> Bool {
        guard legIndex < legs.count - 1 else { return false }
        return legs[legIndex].status == .pending && legs[legIndex + 1].status == .pending
    }
}
