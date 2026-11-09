//
//  RadarLocationManager+SwiftCompletion.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Swift port of the completion handler storage in RadarLocationManager.m:
// `addCompletionHandler:`, `cancelTimeouts`, `callCompletionHandlersWithStatus:location:`,
// `completionHandlerCount`, and `timeoutWithCompletionHandler:`. A location request adds its
// completion handler here. The next handled location, a location error, or a 20 second timeout
// calls every waiting handler.
//
// The Objective-C methods dispatch to these twins when `useSwiftLocationManager` is on. Each
// store's timeouts call only that store's handlers. A handler that waits in the Objective-C store
// when the flag turns on still gets a call: from the Objective-C call method, or from its timeout.
extension RadarLocationManagerSwift {

    /// Holds the waiting completion handlers. Tests replace it to record calls or to control timeouts.
    nonisolated(unsafe) static var completionStore: RadarLocationCompletionStoring = RadarLocationCompletionStore()

    @objc(addCompletionHandler:)
    static func addCompletionHandler(_ completionHandler: RadarLocationCompletionHandler?) {
        guard let completionHandler else {
            return
        }

        completionStore.add(completionHandler)
    }

    @objc static func cancelTimeouts() {
        completionStore.cancelTimeouts()
    }

    @objc(callCompletionHandlersWithStatus:location:)
    static func callCompletionHandlers(status: RadarStatus, location: CLLocation?) {
        completionStore.call(status: status, location: location)
    }

    @objc static func completionHandlerCount() -> Int {
        completionStore.count
    }
}

/// Stores the completion handlers of location requests that wait for a location.
protocol RadarLocationCompletionStoring: AnyObject {
    var count: Int { get }

    /// Adds a handler and starts its timeout.
    func add(_ completionHandler: @escaping RadarLocationCompletionHandler)

    /// Cancels the timeouts of the waiting handlers. The handlers stay until the next `call`.
    func cancelTimeouts()

    /// Calls and removes every waiting handler.
    func call(status: RadarStatus, location: CLLocation?)
}

final class RadarLocationCompletionStore: RadarLocationCompletionStoring, @unchecked Sendable {

    typealias ScheduleTimeout = (TimeInterval, DispatchWorkItem) -> Void

    /// Mirror of the timeout in `addCompletionHandler:` in RadarLocationManager.m. Kept in sync by
    /// hand until that file is fully ported.
    static let timeout: TimeInterval = 20

    private struct Pending {
        let completionHandler: RadarLocationCompletionHandler
        let timeout: DispatchWorkItem
    }

    private let lock = NSLock()
    private var pending: [Pending] = []
    private let scheduleTimeout: ScheduleTimeout
    private let isStopped: () -> Bool

    init(
        scheduleTimeout: @escaping ScheduleTimeout = { delay, timeout in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: timeout)
        },
        isStopped: @escaping () -> Bool = { RadarSwift.bridge?.isStopped() ?? false }
    ) {
        self.scheduleTimeout = scheduleTimeout
        self.isStopped = isStopped
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return pending.count
    }

    func add(_ completionHandler: @escaping RadarLocationCompletionHandler) {
        let timeout = DispatchWorkItem { [weak self] in
            RadarLogger.shared.debug("🦅 Location timeout")
            self?.call(status: .errorLocation, location: nil)
        }

        lock.lock()
        pending.append(Pending(completionHandler: completionHandler, timeout: timeout))
        lock.unlock()

        scheduleTimeout(Self.timeout, timeout)
    }

    func cancelTimeouts() {
        lock.lock()
        defer { lock.unlock() }
        pending.forEach { $0.timeout.cancel() }
    }

    func call(status: RadarStatus, location: CLLocation?) {
        lock.lock()
        let waiting = pending
        pending.removeAll()
        lock.unlock()

        guard !waiting.isEmpty else {
            return
        }

        RadarLogger.shared.debug("🦅 Calling completion handlers | count = \(waiting.count)")

        // Call the handlers outside the lock, so a handler can start a new location request.
        let stopped = isStopped()
        for entry in waiting {
            entry.timeout.cancel()
            entry.completionHandler(status, location, stopped)
        }
    }
}
