//
//  LogStream.swift
//  Example
//
//  Created by Alan Charles on 4/30/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import Combine
import RadarSDK

/// A single timestamped debug-log entry, surfaced via `RadarDelegate.didLog(message)`.
struct LogEntry: Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let message: String
    
    init(timestamp: Date = Date(), message: String) {
        self.id = UUID()
        self.timestamp = timestamp
        self.message = message
    }
}

/// Single source of truth for `RadarDelegate` callbacks.
///
/// The Radar SDK allows only one delegate at a time (`Radar.setDelegate(_:)` overwrites
/// any prior registration). `LogStream` is the only thing the example app registers as
/// that delegate; every other consumer subscribes to its `@Published` state (for views)
/// or its `PassthroughSubject` publishers (for non-UI consumers like the Live Activity
/// manager).
final class LogStream: NSObject, ObservableObject {
    
    /// Cap on retained log entries. Older entries are dropped FIFO.
    static let maxLogs = 1000
    
    /// Cap on retained events. Older events are dropped FIFO.
    static let maxEvents = 500
    
    // MARK: - Published state (for UI consumers)
    
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var events: [RadarEvent] = []
    
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
    let didUpdateLocationPublisher = PassthroughSubject<(location:CLLocation, user: RadarUser), Never>()
    
    // MARK: - Mutation
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func clearEvents() {
        events.removeAll()
    }
}

// MARK: - RadarDelegate

extension LogStream: RadarDelegate {
    
    func didLog(message: String) {
        let entry = LogEntry(message: message)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(entry)
            if self.logs.count > Self.maxLogs {
                self.logs.removeFirst(self.logs.count - Self.maxLogs)
            }
        }
    }
    
    func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.events.append(contentsOf: events)
            if self.events.count > Self.maxEvents {
                self.events.removeFirst(self.events.count - Self.maxEvents)
            }
            if let user = user {
                self.lastSyncedUser = user
            }
            self.didReceiveEventsPublisher.send((events: events, user: user))
        }
    }
    
    func didUpdateLocation(_ location: CLLocation, user: RadarUser) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastSyncedLocation = location
            self.lastSyncedUser = user
            self.didUpdateLocationPublisher.send((location: location, user: user))
        }
    }
    
    func didUpdateClientLocation(_ location: CLLocation, stopped: Bool, source: RadarLocationSource) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastClientLocation = location
            self.lastClientStopped = stopped
            self.lastClientSource = source
        }
    }
    
    func didFail(status: RadarStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.lastFailure = status
        }
    }
}
