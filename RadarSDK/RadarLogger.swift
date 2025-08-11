//
//  RadarLogger.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 8/11/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import OSLog

@objc(RadarLogger_Swift)
public
class RadarLogger : NSObject {
    static let shared = RadarLogger()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    let device = {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current
    }()
    
    // TODO: implement RadarDelegateHolder in Swift, temp implementation to hold delegate here so delegate.didLog can be called
    weak var delegate: RadarDelegate?
    
    @objc public static func setDelegate(_ delegate: RadarDelegate) {
        shared.delegate = delegate
    }
    
    @available(iOS 14.0, *)
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "RadarSDK", category: "RadarSDK")
    
    func info(_ message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        log(level: .info, message: message, type: type, includeDate: includeDate, includeBattery: includeBattery, append: append)
    }
    
    func log(level: RadarLogLevel, message: String, type: RadarLogType = .none, includeDate: Bool = false, includeBattery: Bool = false, append: Bool = false) {
        if (level.rawValue > RadarSettings.logLevel.rawValue) {
            return
        }

        let dateString = dateFormatter.string(from: Date())
        let batteryLevel = device.batteryLevel;
        let message = if (includeDate && includeBattery) {
            String(format: "%@ | at %@ | with %2.f%% battery", message, dateString, batteryLevel*100)
        } else if (includeDate) {
            String(format: "%@ | at %@", message, dateString)
        } else if (includeBattery) {
            String(format: "%@ | with %2.f%% battery", message, batteryLevel*100)
        } else {
            message
        }
        
        // TODO: implement RadarLogBuffer
        Radar.__writeToLogBuffer(with: level, type: type, message: message, forcePersist: append)
        if (!append) {
            DispatchQueue.main.async {
                let backgroundTime = UIApplication.shared.backgroundTimeRemaining >= .greatestFiniteMagnitude ? 180 : UIApplication.shared.backgroundTimeRemaining
                let logMessage = "\(message) | backgroundTimeRemaining = \(backgroundTime)"
                if #available(iOS 14.0, *) {
                    RadarLogger.logger.log("\(logMessage)")
                }
                self.delegate?.didLog(message: logMessage)
            }
        }
    }
}
