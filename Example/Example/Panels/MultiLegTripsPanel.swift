//
//  MultiLegTripsPanel.swift
//  Example
//
//  Created by Alan Charles on 5/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import RadarSDK

struct MultiLegTripsPanel: View {
    @EnvironmentObject var logStream: LogStream
    
    var body: some View {
        TogglePanel("Multi-leg Trips", initiallyExpanded: false) {
            startGroup
            Divider().padding(.vertical, 4)
            advanceGroup
            Divider().padding(.vertical, 4)
            inspectGroup
        }
    }
    
    private var startGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            ActionButton("startTrip (3 coord legs — NYC)", style: .primary) { startCoordinateTrip() }
            ActionButton("startTrip (3 geofence legs)") { startGeofenceTrip() }
            ActionButton("startTrip (mixed: geofence + address + coord)") { startMixedTrip() }
        }
    }
    
    private var advanceGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Advance current leg").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            ActionButton("→ approaching") { updateCurrentLeg(.approaching) }
            ActionButton("→ arrived")     { updateCurrentLeg(.arrived)     }
            ActionButton("→ completed")   { updateCurrentLeg(.completed)   }
            ActionButton("→ canceled", style: .destructive) { updateCurrentLeg(.canceled) }
        }
    }
    
    private var inspectGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inspect & reorder").font(.caption.weight(.semibold)).foregroundColor(.secondary)
            ActionButton("Show current legs") { showCurrentLegs() }
            ActionButton("Reverse leg order") { reverseLegOrder() }
        }
    }
    
    private func startCoordinateTrip() {
        let externalId = "multileg_coord_\(Int(Date().timeIntervalSince1970))"
        let legs = [
            RadarTripLeg(coordinates: CLLocationCoordinate2D(latitude: 40.78382, longitude: -73.97536)),
            RadarTripLeg(coordinates: CLLocationCoordinate2D(latitude: 40.70390, longitude: -73.98670)),
            RadarTripLeg(coordinates: CLLocationCoordinate2D(latitude: 40.64189, longitude: -73.78779))
        ]
        legs.forEach {$0.arrivalRadius = 100 }
        let options = RadarTripOptions(externalId: externalId,
                                        destinationGeofenceTag: nil,
                                        destinationGeofenceExternalId: nil)
        options.mode = .car
        options.legs = legs
        Radar.startTrip(options: options) { status, trip, _ in
            logStream.write(status,
                            summary: "startTrip (multi-leg coords): \(Radar.stringForStatus(status))",
                            detail: tripDetail(trip))
        }
    }
    
    private func startGeofenceTrip() {
        let externalId = "multileg_geo_\(Int(Date().timeIntervalSince1970))"
        let legs = [
            RadarTripLeg(destinationGeofenceTag: "a", destinationGeofenceExternalId: "a"),
            RadarTripLeg(destinationGeofenceTag: "b", destinationGeofenceExternalId: "b"),
            RadarTripLeg(destinationGeofenceTag: "c", destinationGeofenceExternalId: "c")
        ]
        let options = RadarTripOptions(externalId: externalId,
                                        destinationGeofenceTag: nil,
                                        destinationGeofenceExternalId: nil)
        options.mode = .car
        options.legs = legs
        Radar.startTrip(options: options) { status, trip, _ in
            logStream.write(status,
                            summary: "startTrip (multi-leg geofence): \(Radar.stringForStatus(status))",
                            detail: tripDetail(trip))
        }
    }

    private func startMixedTrip() {
        let externalId = "multileg_mixed_\(Int(Date().timeIntervalSince1970))"
        let legs: [RadarTripLeg] = [
            RadarTripLeg(destinationGeofenceTag: "a", destinationGeofenceExternalId: "a"),
            RadarTripLeg(address: "20 Jay St, Brooklyn, NY"),
            RadarTripLeg(coordinates: CLLocationCoordinate2D(latitude: 40.64189, longitude: -73.78779))
        ]
        let options = RadarTripOptions(externalId: externalId,
                                        destinationGeofenceTag: nil,
                                        destinationGeofenceExternalId: nil)
        options.mode = .car
        options.legs = legs
        Radar.startTrip(options: options) { status, trip, _ in
            logStream.write(status,
                            summary: "startTrip (multi-leg mixed): \(Radar.stringForStatus(status))",
                            detail: tripDetail(trip))
        }
    }
    
    private func updateCurrentLeg(_ status: RadarTripLegStatus) {
        Radar.updateCurrentTripLeg(status: status) { sdkStatus, trip, leg, _ in
            logStream.write(sdkStatus,
                            summary: "updateCurrentTripLeg(\(RadarTripLeg.string(for: status))): \(Radar.stringForStatus(sdkStatus))",
                            detail: legDetail(leg, trip: trip))
        }
    }

    private func showCurrentLegs() {
        guard let trip = Radar.getTrip() else {
            logStream.write(result: "Show current legs", detail: "no active trip")
            return
        }
        logStream.write(result: "Current trip: \(trip.externalId ?? trip._id)",
                        detail: tripDetail(trip))
    }

    private func reverseLegOrder() {
        guard let legIds = Radar.getTrip()?.legs?.compactMap({ $0._id }), legIds.count > 1 else {
            logStream.write(error: "Reverse legs", detail: "need 2+ legs with ids")
            return
        }
        let reversed = Array(legIds.reversed())
        Radar.reorderTripLegs(legIds: reversed) { status, trip, _ in
            logStream.write(status,
                            summary: "reorderTripLegs(reversed): \(Radar.stringForStatus(status))",
                            detail: tripDetail(trip))
        }
    }

    // MARK: - Detail formatters

    private func tripDetail(_ trip: RadarTrip?) -> String? {
        guard let trip = trip else { return nil }
        var lines = [
            "externalId: \(trip.externalId ?? "—")",
            "status: \(Radar.stringForTripStatus(trip.status))",
            "currentLegId: \(trip.currentLegId ?? "—")"
        ]
        if let legs = trip.legs {
            lines.append("legs (\(legs.count)):")
            for (i, leg) in legs.enumerated() {
                let dest = legDestinationDescription(leg)
                let status = RadarTripLeg.string(for: leg.status)
                let marker = (leg._id == trip.currentLegId) ? "▶" : " "
                lines.append("  \(marker) [\(i)] \(status) — \(dest)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func legDetail(_ leg: RadarTripLeg?, trip: RadarTrip?) -> String? {
        guard let leg = leg else { return tripDetail(trip) }
        return """
        leg.status: \(RadarTripLeg.string(for: leg.status))
        leg.destination: \(legDestinationDescription(leg))
        trip.currentLegId: \(trip?.currentLegId ?? "—")
        """
    }

    private func legDestinationDescription(_ leg: RadarTripLeg) -> String {
        if let tag = leg.destinationGeofenceTag {
            return "geofence \(tag)/\(leg.destinationGeofenceExternalId ?? "?")"
        }
        if let address = leg.address {
            return "address \"\(address)\""
        }
        if leg.hasCoordinates {
            return String(format: "coords %.5f,%.5f", leg.coordinates.latitude, leg.coordinates.longitude)
        }
        return "unknown"
    }
}
