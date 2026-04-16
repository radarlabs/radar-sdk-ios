//
//  RadarHostFailover.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

final class RadarHostFailover {

    private static let initialBackoff: TimeInterval = 30.0
    private static let maxBackoff: TimeInterval = 300.0

    private let stateQueue = DispatchQueue(label: "io.radar.hostfailover")
    private let hosts: [String]

    // Internal for testability
    var activeHostIndex: Int = 0
    var lastFailureTime: Date? = nil
    var currentBackoff: TimeInterval = RadarHostFailover.initialBackoff
    var isProbingPrimary: Bool = false

    /// Initialize with an ordered list of hosts. Index 0 is the primary host.
    init(hosts: [String]) {
        precondition(!hosts.isEmpty, "RadarHostFailover requires at least one host")
        self.hosts = hosts
    }

    /// Returns the host to use for the next request.
    /// In normal mode, returns the primary host.
    /// In failover mode with backoff not elapsed, returns the current fallback host.
    /// In failover mode with backoff elapsed, returns the primary host (probe attempt).
    var currentHost: String {
        stateQueue.sync {
            if activeHostIndex == 0 {
                isProbingPrimary = false
                return hosts[0]
            }
            let elapsed = Date().timeIntervalSince(lastFailureTime ?? Date())
            if elapsed >= currentBackoff {
                let host = hosts[0]
                isProbingPrimary = true
                RadarLogger.shared.debug("Host failover: probing primary host \(host)")
                return host
            } else {
                isProbingPrimary = false
                return hosts[activeHostIndex]
            }
        }
    }

    /// Call after a successful request. If we were probing the primary, resets to normal mode.
    func reportSuccess() {
        stateQueue.sync {
            if isProbingPrimary {
                RadarLogger.shared.debug("Host failover: primary host recovered, switching back")
                activeHostIndex = 0
                lastFailureTime = nil
                currentBackoff = RadarHostFailover.initialBackoff
            }
            isProbingPrimary = false
        }
    }

    /// Call after a network error that should trigger failover.
    /// Advances to the next host if available.
    /// Returns true if a different host is available to retry on.
    @discardableResult
    func reportFailure() -> Bool {
        stateQueue.sync {
            if isProbingPrimary {
                currentBackoff = min(currentBackoff * 2, RadarHostFailover.maxBackoff)
                RadarLogger.shared.debug("Host failover: primary probe failed, next probe in \(Int(currentBackoff))s")
                lastFailureTime = Date()
                isProbingPrimary = false
                return true
            } else if activeHostIndex + 1 < hosts.count {
                activeHostIndex += 1
                lastFailureTime = Date()
                isProbingPrimary = false
                RadarLogger.shared.debug("Host failover: switching to fallback host \(hosts[activeHostIndex])")
                return true
            }
            return false
        }
    }
}
