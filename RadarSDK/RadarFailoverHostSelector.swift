//
//  RadarFailoverHostSelector.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// State machine that decides which host in an ordered list should be tried
/// next. Hosts are identified by their integer index; index 0 is the primary
/// by convention and is favored
///
/// - Starts on host[0].
/// - On a non-Radar failure at a non-last host, advances to the next host and
///   arms a 60-second probe timer. Subsequent requests stay on the failed-over
///   host until the timer elapses, at which point the next request probes
///   host[0] again.
/// - A successful Radar response on host[0] (or a host[0] probe) clears the
///   timer and sticks on host[0].
/// - A non-Radar failure on the last host clears the timer so the next request
///   immediately probes host[0] (avoids getting stuck on a dead tail host).
internal final class RadarFailoverHostSelector {

    static let probeInterval: TimeInterval = 60

    let hostCount: Int

    private let lock = NSLock()
    private var currentIndex: Int = 0
    private var nextPrimaryProbeAt: Date?

    private let now: () -> Date

    init(hostCount: Int, now: @escaping () -> Date = Date.init) {
        self.hostCount = hostCount
        self.now = now
    }

    /// Returns the index that should be tried next, along with whether this
    /// attempt counts as a probe of host[0] while the selector is otherwise
    /// failed over.
    func indexForNextRequest() -> (index: Int, isProbe: Bool) {
        lock.lock()
        defer { lock.unlock() }

        if currentIndex == 0 {
            return (0, false)
        }

        if let probeAt = nextPrimaryProbeAt, now() >= probeAt {
            return (0, true)
        }

        return (currentIndex, false)
    }

    /// Records a Radar-origin response (success or an error with `meta`) on
    /// the given index. Clears failover state if the response came from host[0].
    func recordRadarResponse(onIndex index: Int) {
        lock.lock()
        let wasFailedOver = currentIndex != 0
        if index == 0 {
            currentIndex = 0
            nextPrimaryProbeAt = nil
        }
        lock.unlock()

        if index == 0 && wasFailedOver {
            RadarLogger.shared.info("FailoverHostSelector: host[0] recovered, returning to host[0]")
        }
    }

    /// Records a non-Radar failure (transport error or response missing `meta`)
    /// on the given index. Advances to the next host and arms the probe timer.
    /// If the failure was on the last host, clears the probe time so the next
    /// request immediately probes host[0].
    func recordNonRadarFailure(onIndex index: Int) {
        lock.lock()
        let wasOnPrimary = currentIndex == 0
        let isLast = index >= hostCount - 1
        if isLast {
            nextPrimaryProbeAt = .distantPast
        } else {
            currentIndex = index + 1
            nextPrimaryProbeAt = now().addingTimeInterval(Self.probeInterval)
        }
        lock.unlock()

        if !isLast {
            if wasOnPrimary {
                RadarLogger.shared.info(
                    "FailoverHostSelector: host[\(index)] failed, switching to host[\(index + 1)] for \(Int(Self.probeInterval))s"
                )
            } else {
                RadarLogger.shared.info(
                    "FailoverHostSelector: probe of host[0] failed, staying on host[\(index + 1)] for another \(Int(Self.probeInterval))s"
                )
            }
        } else {
            RadarLogger.shared.warning(
                "FailoverHostSelector: host[\(index)] (last) also failed, will probe host[0] on next request"
            )
        }
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        currentIndex = 0
        nextPrimaryProbeAt = nil
    }
}
