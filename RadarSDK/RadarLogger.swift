//
//  RadarLogger.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import OSLog

@objc(RadarLogger)
final class RadarLogger : NSObject, Sendable {
    
    @objc(sharedInstance)
    static let shared = RadarLogger()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    @MainActor
    let device = {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current
    }()

    // TODO: implement RadarDelegateHolder in Swift, temp implementation to hold delegate here so delegate.didLog can be called
    @MainActor
    weak var delegate: RadarDelegate?

    @MainActor
    @objc public static func setDelegate(_ delegate: RadarDelegate) {
        shared.delegate = delegate
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
    
    func log(level: RadarLogLevel, message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        if (level.rawValue > RadarSettings.logLevel.rawValue) {
            return
        }
        // if you're still on iOS 13.0, that's your problem, you won't get logs. We need async
        guard #available(iOS 13.0, *) else {
            return
        }
        
        Task {
            let log = RadarLog(level: level, message: message, type: type, createdAt: Date(), includeDate: includeDate, battery: includeBattery ? await self.device.batteryLevel : nil)
            
            await RadarLogBuffer.shared.log(log)
            
            let backgroundTime = await RadarUtils.backgroundTimeRemaining
            let logMessage = "\(message) | backgroundTimeRemaining = \(backgroundTime)"
            
            if #available(iOS 14.0, *) {
                RadarLogger.logger.log("\(logMessage)")
            }
            DispatchQueue.main.async {
                self.delegate?.didLog?(message: logMessage)
            }
        }
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
        guard #available(iOS 13.0, *) else {
            return
        }
        Task {
            await RadarLogBuffer.shared.flush()
        }
    }
    @objc
    static func write(_ level: RadarLogLevel, type: RadarLogType, message: String) {
        guard #available(iOS 13.0, *) else {
            return
        }
        Task {
            let log = RadarLog(level: level, message: message, type: type, createdAt: Date(), includeDate: false, battery: nil)
            await RadarLogBuffer.shared.log(log)
        }
    }
}
