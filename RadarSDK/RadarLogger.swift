//
//  RadarLogger.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import OSLog

@objc(RadarLogger)
final class RadarLogger: NSObject, @unchecked Sendable {

    @objc(sharedInstance)
    static let shared = RadarLogger()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    // in testing mode, allow changing logLevel directly
    var logLevelOverride: RadarLogLevel?
    var logLevel: RadarLogLevel {
        logLevelOverride ?? RadarSettings.logLevel
    }

    // Test-only bookkeeping: each `log(...)` call spawns a detached Task that delivers the
    // message to the delegate asynchronously. Tests need to deterministically await that
    // delivery instead of racing a wall-clock timeout (which is flaky under CI load). When
    // `logLevelOverride` is set (test mode) we retain the in-flight tasks so `awaitPendingLogs()`
    // can await them. In production `logLevelOverride` is nil, so this stays a no-op.
    private let pendingLogTasksLock = NSLock()
    private var pendingLogTasks = [Task<Void, Never>]()

    @MainActor
    let device = {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current
    }()

    // TODO: implement RadarDelegateHolder in Swift, temp implementation to hold delegate here so delegate.didLog can be called
    @MainActor
    weak var delegate: RadarDelegate?

    @MainActor
    @objc public func setDelegate(_ delegate: RadarDelegate?) {
        self.delegate = delegate
    }

    @available(iOS 14.0, *)
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "RadarSDK", category: "RadarSDK")

    func debug(_ message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        log(level: .debug, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: append)
    }

    func info(_ message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        log(level: .info, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: append)
    }

    func warning(_ message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        log(level: .warning, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: append)
    }

    func error(_ message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        log(level: .error, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: append)
    }

    func log(level: RadarLogLevel, message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        if level.rawValue > logLevel.rawValue {
            return
        }

        let task = Task {
            let log = RadarLog(level: level, message: message, type: type, createdAt: Date(), includeDate: includeDate, battery: includeBattery ? await self.device.batteryLevel : nil)

            await RadarLogBuffer.shared.log(log)

            let backgroundTime = await RadarUtils.backgroundTimeRemaining
            let logMessage = "\(log) | backgroundTimeRemaining = \(backgroundTime)"

            if #available(iOS 14.0, *),
                logLevelOverride == nil
            {  // if logLevelOverride != nil, we are in test mode, don't output to console
                RadarLogger.logger.log("\(logMessage)")
            }
            await MainActor.run {
                self.delegate?.didLog?(message: logMessage)
            }
        }

        // Only retain tasks in test mode to keep production allocation-free.
        if logLevelOverride != nil {
            pendingLogTasksLock.lock()
            pendingLogTasks.append(task)
            pendingLogTasksLock.unlock()
        }
    }

    /// Test hook: awaits every log task spawned so far, guaranteeing their delegate
    /// callbacks have run. Lets tests assert on delivered messages deterministically
    /// instead of polling against a wall-clock timeout.
    func awaitPendingLogs() async {
        // Drain under the lock in a synchronous helper so the lock is never held across an
        // `await` (NSLock.lock/unlock are unavailable from async contexts).
        for task in drainPendingLogTasks() {
            await task.value
        }
    }

    private func drainPendingLogTasks() -> [Task<Void, Never>] {
        pendingLogTasksLock.lock()
        defer { pendingLogTasksLock.unlock() }
        let tasks = pendingLogTasks
        pendingLogTasks.removeAll()
        return tasks
    }

    // ObjC interface, which will be deprecated
    @objc
    func log(level: RadarLogLevel, message: String) {
        log(level: level, message: message, type: .none, includeDate: false, includeBattery: false, append: false)
    }
    @objc
    func log(level: RadarLogLevel, type: RadarLogType, message: String) {
        log(level: level, message: message, type: type, includeDate: false, includeBattery: false, append: false)
    }
    @objc
    func log(level: RadarLogLevel, type: RadarLogType, message: String, includeDate: Bool, includeBattery: Bool) {
        log(level: level, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: false)
    }
    @objc
    // swiftlint:disable:next function_parameter_count
    func log(level: RadarLogLevel, type: RadarLogType, message: String, includeDate: Bool, includeBattery: Bool, append: Bool) {
        log(level: level, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: append)
    }
    // ObjC interface from RadarLog.h consolidated into [RadarLogger ...] replaceing [RadarLog ...]
    @objc
    static func levelFromString(_ string: String) -> RadarLogLevel {
        return RadarLogLevel.from(string: string)
    }
    @objc
    static func stringForLogLevel(_ level: RadarLogLevel) -> String {
        return level.toString()
    }
    // ObjC interface from RadarLogBuffer.h consolidated
    @objc
    static func flushLogs() {
        Task {
            await RadarLogBuffer.shared.flush()
        }
    }
    @objc
    static func write(_ level: RadarLogLevel, type: RadarLogType, message: String) {
        Task {
            let log = RadarLog(level: level, message: message, type: type, createdAt: Date(), includeDate: false, battery: nil)
            await RadarLogBuffer.shared.log(log)
        }
    }
    static func debug(_ message: String, type: RadarLogType = .none) {
        RadarLogger.shared.debug(message, type: type)
    }
    static func info(_ message: String, type: RadarLogType = .none) {
        RadarLogger.shared.info(message, type: type)
    }
    static func warning(_ message: String, type: RadarLogType = .none) {
        RadarLogger.shared.warning(message, type: type)
    }
}
