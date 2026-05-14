//
//  TripBuilderStore.swift
//  Example
//
//  Created by Alan Charles on 5/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import RadarSDK

@MainActor
final class TripBuilderStore: ObservableObject {

    // MARK: - Selection state

    @Published private(set) var selectedDestinations: [TripDestination] = []
    @Published var pendingHit: TripDestination?

    @discardableResult
    func add(_ destination: TripDestination) -> Bool {
        guard !selectedDestinations.contains(where: { $0.id == destination.id }) else { return false }
        selectedDestinations.append(destination)
        return true
    }

    func remove(at index: Int) {
        guard selectedDestinations.indices.contains(index) else { return }
        selectedDestinations.remove(at: index)
    }

    func move(from offsets: IndexSet, to destination: Int) {
        selectedDestinations.move(fromOffsets: offsets, toOffset: destination)
    }

    func remove(at offsets: IndexSet) {
        selectedDestinations.remove(atOffsets: offsets)
    }

    func clear() {
        selectedDestinations.removeAll()
    }

    func proposeHit(_ destination: TripDestination) {
        pendingHit = destination
    }

    func confirmPendingHit() {
        guard let dest = pendingHit else { return }
        if isSelected(dest.id) {
            selectedDestinations.removeAll { $0.id == dest.id }
        } else {
            add(dest)
        }
        pendingHit = nil
    }

    func dismissPendingHit() {
        pendingHit = nil
    }

    func isSelected(_ id: String) -> Bool {
        selectedDestinations.contains { $0.id == id }
    }

    // MARK: - Active trip mirror

    @Published private(set) var activeTrip: RadarTrip?
    @Published private(set) var tripBreadcrumbs: [CLLocationCoordinate2D] = []

    var hasActiveTrip: Bool { activeTrip != nil }

    private var cancellables = Set<AnyCancellable>()
    private weak var logStream: LogStream?
    private weak var registry: MapOverlayRegistry?
    private static let breadcrumbDedupeMeters: CLLocationDistance = 10

    func bind(logStream: LogStream, registry: MapOverlayRegistry) {
        self.logStream = logStream
        self.registry = registry

        logStream.didReceiveEventsPublisher
            .sink { [weak self] payload in
                Task { @MainActor in
                    self?.refreshActiveTrip()
                    self?.captureTripEvents(payload.events)
                }
            }
            .store(in: &cancellables)

        logStream.didUpdateLocationPublisher
            .sink { [weak self] payload in
                Task { @MainActor in
                    self?.appendBreadcrumb(payload.location)
                }
            }
            .store(in: &cancellables)
    }

    func refreshActiveTrip() {
        let wasActive = activeTrip != nil
        activeTrip = Radar.getTrip()
        let nowActive = activeTrip != nil
        registry?.isInTripMode = nowActive

        if wasActive && !nowActive {
            clearTripVisualization()
        }

        Task { @MainActor [weak registry] in
            await registry?.refreshSource("tripGeofences")
            await registry?.refreshSource("tripDestination")
        }
    }

    private static let tripEventTypes: Set<RadarEventType> = [
        .userStartedTrip,
        .userApproachingTripDestination,
        .userArrivedAtTripDestination,
        .userStoppedTrip,
        // Note: `userUpdatedTrip` is intentionally excluded. Background location
        // updates trigger frequent `updated_trip` events which would spam the map
        // with pins. Reorder actions still get captured by passing `forced: true`
        // through the reorderTripLegs completion handler.
    ]

    private func captureTripEvents(_ events: [RadarEvent], forced: Bool = false) {
        var appended = false

        for event in events {
            let allowed = forced || Self.tripEventTypes.contains(event.type)
            guard allowed else { continue }
            if tripEventMarkers.contains(where: { $0.id == event._id }) { continue }
            let marker = TripEventMarker(
                id: event._id,
                coordinate: event.location.coordinate,
                type: event.type,
                timestamp: event.createdAt
            )
            tripEventMarkers.append(marker)
            appended = true
        }

        if appended {
            Task { @MainActor [weak registry] in
                await registry?.refreshSource("tripEvents")
            }
        }
    }

    // MARK: - Trip lifecycle actions

    func startTrip() {
        guard !selectedDestinations.isEmpty else { return }

        let externalId = "map_trip_\(Int(Date().timeIntervalSince1970))"
        let options: RadarTripOptions
        let label: String

        if selectedDestinations.count == 1,
            case .geofence(_, let tag, let extId, _, _) = selectedDestinations[0],
            let tag = tag, !tag.isEmpty,
            let extId = extId, !extId.isEmpty
        {
            options = RadarTripOptions(
                externalId: externalId,
                destinationGeofenceTag: tag,
                destinationGeofenceExternalId: extId
            )
            label = "startTrip (map, single destination)"
        } else {
            let legs = selectedDestinations.map(buildLeg(for:))
            options = RadarTripOptions(
                externalId: externalId,
                destinationGeofenceTag: nil,
                destinationGeofenceExternalId: nil
            )
            options.legs = legs
            label =
                legs.count == 1
                ? "startTrip (map, 1 leg)"
                : "startTrip (map, \(legs.count) legs)"
        }
        options.mode = .car

        logStream?.write(action: label)

        Radar.startTrip(options: options) { [weak self] status, trip, _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.refreshActiveTrip()
                if status == .success {
                    self.selectedDestinations.removeAll()
                }
                self.logStream?.write(
                    status,
                    summary: "\(label): \(Radar.stringForStatus(status))",
                    detail: self.tripDetail(trip)
                )
            }
        }
    }

    func advanceCurrentLeg(_ status: RadarTripLegStatus) {
        let label = "updateCurrentTripLeg(\(RadarTripLeg.string(for: status))) (map)"
        logStream?.write(action: label)
        Radar.updateCurrentTripLeg(status: status) { [weak self] sdkStatus, trip, leg, _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.refreshActiveTrip()
                self.logStream?.write(
                    sdkStatus,
                    summary: "\(label): \(Radar.stringForStatus(sdkStatus))",
                    detail: self.tripDetail(trip, leg: leg)
                )
            }
        }
    }

    func completeTrip() {
        let label = "completeTrip (map)"
        logStream?.write(action: label)
        Radar.completeTrip { [weak self] status, trip, _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.refreshActiveTrip()
                self.logStream?.write(
                    status,
                    summary: "\(label): \(Radar.stringForStatus(status))",
                    detail: self.tripDetail(trip)
                )
            }
        }
    }

    func cancelTrip() {
        let label = "cancelTrip (map)"
        logStream?.write(action: label)
        Radar.cancelTrip { [weak self] status, trip, _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.refreshActiveTrip()
                self.logStream?.write(
                    status,
                    summary: "\(label): \(Radar.stringForStatus(status))",
                    detail: self.tripDetail(trip)
                )
            }
        }
    }

    enum LegMoveDirection {
        case up, down
    }

    func moveLeg(legId: String, direction: LegMoveDirection) {
        guard let trip = activeTrip,
            let legs = trip.legs,
            let currentIndex = legs.firstIndex(where: { $0._id == legId })
        else { return }

        let targetIndex: Int
        switch direction {
        case .up: targetIndex = currentIndex - 1
        case .down: targetIndex = currentIndex + 1
        }

        guard legs.indices.contains(targetIndex),
            legs[targetIndex].status == .pending
        else { return }

        var newLegIds = legs.compactMap { $0._id }
        guard newLegIds.count == legs.count else { return }
        newLegIds.swapAt(currentIndex, targetIndex)

        let arrow = direction == .up ? "↑" : "↓"
        let label = "reorderTripLegs (map, \(arrow))"
        logStream?.write(action: label)

        Radar.reorderTripLegs(legIds: newLegIds) { [weak self] status, trip, events in
            Task { @MainActor in
                guard let self = self else { return }
                self.refreshActiveTrip()
                if let events = events, !events.isEmpty {
                    self.captureTripEvents(events, forced: true)
                }
                self.logStream?.write(
                    status,
                    summary: "\(label): \(Radar.stringForStatus(status))",
                    detail: self.tripDetail(trip)
                )
            }
        }
    }

    // MARK: - Trip visualization state
    @Published private(set) var tripEventMarkers: [TripEventMarker] = []

    private func appendBreadcrumb(_ location: CLLocation) {
        guard activeTrip != nil else { return }

        if let last = tripBreadcrumbs.last {
            let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
            if location.distance(from: lastLoc) < Self.breadcrumbDedupeMeters {
                return
            }
        }
        tripBreadcrumbs.append(location.coordinate)

        Task { @MainActor [weak registry] in
            await registry?.refreshSource("tripBreadcrumbs")
        }
    }

    private func clearTripVisualization() {
        tripBreadcrumbs.removeAll()
        tripEventMarkers.removeAll()
        registry?.clearBundle(for: "tripBreadcrumbs")
        registry?.clearBundle(for: "tripEvents")
    }

    // MARK: - Helpers

    private func buildLeg(for destination: TripDestination) -> RadarTripLeg {
        switch destination {
        case .geofence(let id, let tag, let extId, _, _):
            if let tag = tag, !tag.isEmpty,
                let extId = extId, !extId.isEmpty
            {
                return RadarTripLeg(
                    destinationGeofenceTag: tag,
                    destinationGeofenceExternalId: extId
                )
            } else {
                return RadarTripLeg(destinationGeofenceId: id)
            }
        case .coordinate(let coord, _):
            let leg = RadarTripLeg(coordinates: coord)
            leg.arrivalRadius = 100
            return leg
        }
    }

    private func tripDetail(_ trip: RadarTrip?, leg: RadarTripLeg? = nil) -> String {
        guard let trip = trip else { return "no trip" }
        var lines = [
            "externalId: \(trip.externalId ?? "—")",
            "trip.status: \(Radar.stringForTripStatus(trip.status))",
            "currentLegId: \(trip.currentLegId ?? "—")",
        ]
        if let legs = trip.legs {
            lines.append("legs: \(legs.count)")
        }
        if let leg = leg {
            lines.append("leg.status: \(RadarTripLeg.string(for: leg.status))")
        }
        return lines.joined(separator: "\n")
    }
}
