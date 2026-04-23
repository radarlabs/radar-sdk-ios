//
//  RadarVerifiedHostSelector.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarVerifiedHost)
enum RadarVerifiedHost: Int {
    case primary
    case secondary
}

/// State machine that decides whether the next verified request should go to
/// the primary or the secondary host.
///
/// - Starts on primary.
/// - On a non-Radar failure against the primary, flips to secondary and arms a
///   60-second probe timer; subsequent requests go to secondary until the timer
///   elapses, at which point the next request probes primary again.
/// - A successful Radar response on primary (or a primary probe) clears the
///   timer and sticks on primary.
/// - A non-Radar failure on the secondary clears the timer so the next request
///   immediately probes primary again (avoids getting stuck on a dead secondary).
@objc(RadarVerifiedHostSelector)
final class RadarVerifiedHostSelector: NSObject {

    static let probeInterval: TimeInterval = 60

    static let shared = RadarVerifiedHostSelector()

    private let lock = NSLock()
    private var currentHost: RadarVerifiedHost = .primary
    private var nextPrimaryProbeAt: Date?

    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
        super.init()
    }

    /// Returns the host that should be tried next, along with whether this
    /// attempt counts as a "probe" of the primary while the selector is
    /// otherwise failed over.
    func hostForNextRequest() -> (host: RadarVerifiedHost, isProbe: Bool) {
        lock.lock()
        defer { lock.unlock() }

        if currentHost == .primary {
            return (.primary, false)
        }

        if let probeAt = nextPrimaryProbeAt, now() >= probeAt {
            return (.primary, true)
        }

        return (.secondary, false)
    }

    /// Records a Radar-origin response (success or an error with `meta`) on
    /// the given host. Clears failover state if the response came from primary.
    func recordRadarResponse(on host: RadarVerifiedHost) {
        lock.lock()
        defer { lock.unlock() }

        if host == .primary {
            currentHost = .primary
            nextPrimaryProbeAt = nil
        }
    }

    /// Records a non-Radar failure (transport error or response missing `meta`)
    /// on the given host. Moves the selector to secondary and arms/resets the
    /// probe timer. If the failure was on secondary, clears the probe time so
    /// the next request probes primary immediately.
    func recordNonRadarFailure(on host: RadarVerifiedHost) {
        lock.lock()
        defer { lock.unlock() }

        if host == .primary {
            currentHost = .secondary
            nextPrimaryProbeAt = now().addingTimeInterval(Self.probeInterval)
        } else {
            nextPrimaryProbeAt = .distantPast
        }
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        currentHost = .primary
        nextPrimaryProbeAt = nil
    }
}
