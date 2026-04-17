//
//  RadarHostFailover.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

final class RadarHostFailover {

    private static let initialBackoffSeconds: TimeInterval = 30.0
    private static let maxBackoffSeconds: TimeInterval = 300.0

    // Serial queue to synchronize access to mutable state across concurrent network threads.
    private let stateQueue: DispatchQueue = DispatchQueue(label: "io.radar.hostfailover")
    private let hosts: [String]
    private let now: () -> Date

    private var activeHostIndex: Int = 0
    private var lastFailureTime: Date? = nil
    private var currentBackoffSeconds: TimeInterval = RadarHostFailover.initialBackoffSeconds
    private var isRetryingPrimary: Bool = false

    /// Initialize with an ordered list of hosts. Index 0 is the primary host.
    init(hosts: [String], now: @escaping () -> Date = { Date() }) {
        precondition(!hosts.isEmpty, "RadarHostFailover requires at least one host")
        self.hosts = hosts
        self.now = now
    }

    /// Returns the host to use for the next request.
    /// In normal mode, returns the primary host.
    /// In failover mode with backoff not elapsed, returns the current fallback host.
    /// In failover mode with backoff elapsed, returns the primary host (retry attempt).
    var currentHost: String {
        stateQueue.sync {
            if activeHostIndex == 0 {
                isRetryingPrimary = false
                return hosts[0]
            }
            let elapsed = now().timeIntervalSince(lastFailureTime ?? now())
            if elapsed >= currentBackoffSeconds {
                let host = hosts[0]
                isRetryingPrimary = true
                return host
            } else {
                isRetryingPrimary = false
                return hosts[activeHostIndex]
            }
        }
    }

    /// Call after a successful request. If we were retrying the primary, resets to normal mode.
    func reportSuccess() {
        stateQueue.sync {
            if isRetryingPrimary {
                RadarLogger.shared.debug("Host failover: primary host recovered, switching back")
                activeHostIndex = 0
                lastFailureTime = nil
                currentBackoffSeconds = RadarHostFailover.initialBackoffSeconds
            }
            isRetryingPrimary = false
        }
    }

    /// Call after a network error that should trigger failover.
    /// Advances to the next host if available.
    /// Returns true if a different host is available to retry on.
    @discardableResult
    func reportFailure() -> Bool {
        stateQueue.sync {
            if isRetryingPrimary {
                currentBackoffSeconds = min(currentBackoffSeconds * 2, RadarHostFailover.maxBackoffSeconds)
                lastFailureTime = now()
                isRetryingPrimary = false
                return true
            } else if activeHostIndex + 1 < hosts.count {
                activeHostIndex += 1
                lastFailureTime = now()
                isRetryingPrimary = false
                return true
            }
            return false
        }
    }
}
