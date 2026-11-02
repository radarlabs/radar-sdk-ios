//
//  LogStream.swift
//  Example
//
//  Created by Alan Charles on 4/30/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Combine
import CoreLocation
import Foundation
import RadarSDK

/// One row in the unified console timeline.
///
/// `summary` is the one-line representation shown in a compact row. `detail` is the
/// optional multi-line payload revealed when the row is expanded (JSON of an event,
/// formatted result of an SDK call, full location vector, etc.).
struct ConsoleEntry: Identifiable {
    enum Kind {
        /// User tapped a button (logged automatically by ActionButton in 6c).
        case action
        /// SDK call returned (status + return value).
        case result
        /// SDK event fired (`didReceiveEvents`).
        case event
        /// SDK location update (`didUpdateLocation`).
        case location
        /// SDK debug message (`didLog`).
        case log
        /// SDK failure (`didFail`).
        case error
    }

    let id: UUID
    let timestamp: Date
    let kind: Kind
    let summary: String
    let detail: String?

    init(
        kind: Kind,
        summary: String,
        detail: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.kind = kind
        self.summary = summary
        self.detail = detail
    }
}

/// Single source of truth for `RadarDelegate` callbacks and user-action logging.
///
/// The Radar SDK allows only one delegate at a time (`Radar.setDelegate(_:)` overwrites
/// any prior registration). `LogStream` is the only thing the example app registers as
/// that delegate; every other consumer subscribes to its `@Published` state (for views)
/// or its `PassthroughSubject` publishers (for non-UI consumers like the Live Activity
/// manager).
///
/// The unified `entries` timeline is the canonical feed. UI consumers (LogsView,
/// the Tests-tab recent-activity preview in 6e) read it directly; non-UI consumers
/// like `TripLiveActivityManager` subscribe to the dedicated PassthroughSubjects.
final class LogStream: NSObject, ObservableObject {

    /// Cap on retained timeline entries. Older entries are dropped FIFO.
    static let maxEntries = 2000

    // MARK: - Published state (for UI consumers)

    @Published private(set) var entries: [ConsoleEntry] = []

    @Published private(set) var lastSyncedLocation: CLLocation?
    @Published private(set) var lastSyncedUser: RadarUser?

    @Published private(set) var lastClientLocation: CLLocation?
    @Published private(set) var lastClientStopped: Bool = false
    @Published private(set) var lastClientSource: RadarLocationSource = .unknown

    @Published private(set) var lastFailure: RadarStatus?

    // MARK: - Event publishers (for non-UI consumers, e.g. TripLiveActivityManager)

    /// Fires once per `didReceiveEvents` callback from the SDK. Subscribers see only
    /// the new batch, not the full historical `events` array.
    let didReceiveEventsPublisher = PassthroughSubject<(events: [RadarEvent], user: RadarUser?), Never>()

    /// Fires once per `didUpdateLocation` callback from the SDK (server-synced updates).
    let didUpdateLocationPublisher = PassthroughSubject<(location: CLLocation, user: RadarUser), Never>()

    // MARK: - Public write API (for action / result logging from views)

    /// Log a user-initiated action (typically from `ActionButton` taps in 6c+).
    func write(action title: String, detail: String? = nil) {
        append(ConsoleEntry(kind: .action, summary: title, detail: detail))
    }

    /// Log the result of an SDK call returning to its completion handler.
    func write(result title: String, detail: String? = nil) {
        append(ConsoleEntry(kind: .result, summary: title, detail: detail))
    }

    /// Log a failure path (callback returned an error status, etc.).
    func write(error title: String, detail: String? = nil) {
        append(ConsoleEntry(kind: .error, summary: title, detail: detail))
    }

    /// Clear the unified timeline.
    func clearEntries() {
        entries.removeAll()
    }

    // MARK: - Private

    /// Main-queue-safe append with FIFO trimming.
    private func append(_ entry: ConsoleEntry) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.entries.append(entry)
            if self.entries.count > Self.maxEntries {
                self.entries.removeFirst(self.entries.count - Self.maxEntries)
            }
        }
    }

    // MARK: - Formatting helpers (used by RadarDelegate callbacks below)

    fileprivate static func summarize(_ event: RadarEvent) -> String {
        let type = RadarEvent.string(for: event.type) ?? "unknown"
        if let externalId = event.geofence?.externalId, !externalId.isEmpty {
            return "\(type) — \(externalId)"
        }
        if let placeName = event.place?.name, !placeName.isEmpty {
            return "\(type) — \(placeName)"
        }
        if let regionName = event.region?.name, !regionName.isEmpty {
            return "\(type) — \(regionName)"
        }
        return type
    }

    fileprivate static func detail(_ event: RadarEvent) -> String? {
        return prettyJSON(event.dictionaryValue())
    }

    fileprivate static func summarize(_ location: CLLocation) -> String {
        let lat = String(format: "%.5f", location.coordinate.latitude)
        let lng = String(format: "%.5f", location.coordinate.longitude)
        let acc = Int(location.horizontalAccuracy)
        return "\(lat), \(lng)  ±\(acc)m"
    }

    fileprivate static func prettyJSON(_ raw: [AnyHashable: Any]?) -> String? {
        guard let raw = raw, JSONSerialization.isValidJSONObject(raw) else { return nil }
        let data = try? JSONSerialization.data(
            withJSONObject: raw,
            options: [.prettyPrinted, .sortedKeys]
        )
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
}

// MARK: - RadarDelegate

extension LogStream: RadarDelegate {

    func didLog(message: String) {
        append(ConsoleEntry(kind: .log, summary: message))
    }

    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let user = user {
                self.lastSyncedUser = user
            }
            self.didReceiveEventsPublisher.send((events: events, user: user))
        }
        for event in events {
            append(
                ConsoleEntry(
                    kind: .event,
                    summary: Self.summarize(event),
                    detail: Self.detail(event)
                ))
        }
    }

    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastSyncedLocation = location
            self.lastSyncedUser = user
            self.didUpdateLocationPublisher.send((location: location, user: user))
        }
        append(
            ConsoleEntry(
                kind: .location,
                summary: "synced  " + Self.summarize(location)
            ))
    }

    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastClientLocation = location
            self.lastClientStopped = stopped
            self.lastClientSource = source
        }
        let stoppedTag = stopped ? "stopped" : "moving"
        append(
            ConsoleEntry(
                kind: .location,
                summary: "\(stoppedTag)  " + Self.summarize(location)
            ))
    }

    func didFail(status: RadarStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.lastFailure = status
        }
        append(
            ConsoleEntry(
                kind: .error,
                summary: "didFail: \(Radar.stringForStatus(status))"
            ))
    }
}

// MARK: - Status-driven convenience

extension LogStream {
    /// Convenience: write a `.result` entry on `.success`, `.error` otherwise.
    /// Used by panels that surface SDK-call completion handlers to the console.
    func write(_ status: RadarStatus, summary: String, detail: String? = nil) {
        if status == .success {
            write(result: summary, detail: detail)
        } else {
            write(error: summary, detail: detail)
        }
    }
}
