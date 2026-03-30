//
//  RadarLog.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 3/27/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import OSLog

extension RadarLogLevel: Codable {
    public func toString() -> String {
        switch self {
        case .none:
            return "none"
        case .error:
            return "error"
        case .warning:
            return "warning"
        case .info:
            return"info"
        case .debug:
            return "debug"
        @unknown default:
            return "none"
        }
    }
    
    public static func from(string: String) -> RadarLogLevel {
        switch string {
        case "none":
            return .none
        case "error":
            return .error
        case "warning":
            return .warning
        case "info":
            return .info
        case "debug":
            return .debug
        default:
            return .none
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toString())
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = RadarLogLevel.from(string: value)
    }
}

extension RadarLogType: Codable {
    public func toString() -> String {
        switch self {
        case .none:
            return "NONE"
        case .sdkCall:
            return "SDK_CALL"
        case .sdkError:
            return "SDK_ERROR"
        case .sdkException:
            return "SDK_EXCEPTION"
        case .appLifecycleEvent:
            return "APP_LIFECYCLE_EVENT"
        case .permissionEvent:
            return "PERMISSION_EVENT"
        @unknown default:
            return "NONE"
        }
    }
    
    public static func from(string: String) -> RadarLogType {
        switch string {
        case "NONE":
            return .none
        case "SDK_CALL":
            return .sdkCall
        case "SDK_ERROR":
            return .sdkError
        case "SDK_EXCEPTION":
            return .sdkException
        case "APP_LIFECYCLE_EVENT":
            return .appLifecycleEvent
        case "PERMISSION_EVENT":
            return .permissionEvent
        default:
            return .none
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toString())
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = RadarLogType.from(string: value)
    }
}

struct RadarLog: Codable, CustomStringConvertible {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    let level: RadarLogLevel
    let message: String
    let type: RadarLogType
    let createdAt: Date
    let includeDate: Bool
    let battery: Float?
    
    var description: String {
        var str = message
        if includeDate {
            let dateString = RadarLog.dateFormatter.string(from: createdAt)
            str += " | at \(dateString)"
        }
        if let battery {
            let batteryString = String(format: "%.2f", battery)
            str += " | with \(batteryString) battery"
        }
        return str
    }
    
    var osLogType: OSLogType {
        switch level {
        case .none:
            return .default
        case .error:
            return .error
        case .warning:
            return .error
        case .info:
            return .info
        case .debug:
            return .debug
        @unknown default:
            return .default
        }
    }
    
    func dict() -> [String: Any] {
        return [
            "message": description,
            "level": level.toString(),
            "type": type.toString(),
            "createdAt": RadarUtils.isoDateFormatter.string(from: createdAt),
        ]
    }
}
