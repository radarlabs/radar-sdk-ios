//
//  RadarSdkConfiguration.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

extension RadarLogLevel: Codable {
    static func from(string: String) -> RadarLogLevel {
        switch string {
        case "none": return .none
        case "error": return .error
        case "warning": return .warning
        case "info": return .info
        case "debug": return .debug
        default: return .none
        }
    }
    
    func toString() -> String {
        switch self {
            case .none: return "none"
            case .error: return "error"
            case .warning: return "warning"
            case .info: return "info"
            case .debug: return "debug"
            @unknown default:
                return "none"
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        let string = toString()
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = RadarLogLevel.from(string: string)
    }
}

@objc(RadarSdkConfiguration) @objcMembers
class RadarSdkConfiguration: NSObject, Codable {
    let logLevel: RadarLogLevel
    let startTrackingOnInitialize: Bool
    let trackOnceOnAppOpen: Bool
    let usePersistence: Bool
    let extendFlushReplays: Bool
    let useLogPersistence: Bool
    let useRadarModifiedBeacon: Bool
    let useOpenedAppConversion: Bool
    let useForegroundLocationUpdatedAtMsDiff: Bool
    let useNotificationDiff: Bool
    let syncAfterSetUser: Bool
    let useNotificationDiffV2: Bool
    
    public init(dict: [String: Any]?) {
        logLevel = RadarLogLevel.from(string: dict?["logLevel"] as? String ?? "none")
        startTrackingOnInitialize = dict?["startTrackingOnInitialize"] as? Bool ?? false
        trackOnceOnAppOpen = dict?["trackOnceOnAppOpen"] as? Bool ?? false
        usePersistence = dict?["usePersistence"] as? Bool ?? false
        extendFlushReplays = dict?["extendFlushReplays"] as? Bool ?? false
        useLogPersistence = dict?["useLogPersistence"] as? Bool ?? false
        useRadarModifiedBeacon = dict?["useRadarModifiedBeacon"] as? Bool ?? false
        useOpenedAppConversion = dict?["useOpenedAppConversion"] as? Bool ?? false
        useForegroundLocationUpdatedAtMsDiff = dict?["useForegroundLocationUpdatedAtMsDiff"] as? Bool ?? false
        useNotificationDiff = dict?["useNotificationDiff"] as? Bool ?? false
        syncAfterSetUser = dict?["syncAfterSetUser"] as? Bool ?? false
        useNotificationDiffV2 = dict?["useNotificationDiffV2"] as? Bool ?? false
//        useNotificationDiffV2 = true // TODO: for testing only
        
        print("Initialized SDK COND+FIG\(useNotificationDiffV2)")
    }
    
    public func dictionaryValue() -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(self)
            let obj = try JSONSerialization.jsonObject(with: data)
            return obj as? [String: Any] ?? [:]
        } catch {
            RadarLogger.warning("Failed to serialize RadarSdkConfiguration")
            return [:]
        }
    }
}
