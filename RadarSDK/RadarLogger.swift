//
//  RadarLogger.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import OSLog

@objc(RadarLogger_Swift)
public final class RadarLogger : NSObject, Sendable {
    
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
        
        DispatchQueue.main.async {
            let log = RadarLog(level: level, message: message, type: type, createdAt: Date(), includeDate: includeDate, battery: includeBattery ? self.device.batteryLevel : nil)
            

            // TODO: implement RadarLogBuffer
            RadarSwift.bridge?.writeToLogBuffer(level: level, type: type, message: message, forcePersist: append)
            if (!append) {
                let backgroundTime = UIApplication.shared.backgroundTimeRemaining >= .greatestFiniteMagnitude ? 180 : UIApplication.shared.backgroundTimeRemaining
                let logMessage = "\(message) | backgroundTimeRemaining = \(backgroundTime)"
                if #available(iOS 14.0, *) {
                    RadarLogger.logger.log("\(logMessage)")
                }
                self.delegate?.didLog?(message: logMessage)
            }
        }
    }
}
