//
//  RadarUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/19/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import CoreTelephony
import Foundation
import SystemConfiguration
import UIKit

enum RadarConnectionType: String {
    case unknown = "unknown"
    case wifi = "wifi"
    case cellular5g = "cellular-5g"
    case cellularLte = "cellular-lte"
    case cellular3g = "cellular-3g"
    case cellular2g = "cellular-2g"
    case cellular = "cellular"
}

@objc(RadarUtils) @objcMembers
class RadarUtils: NSObject {

    static let deviceModel = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()

    static var deviceOS: String {
        get async {
            return await MainActor.run(resultType: String.self) {
                UIDevice.current.systemName
            }
        }
    }

    static let country = Locale.current.regionCode
    static let timeZoneOffset = NSNumber(value: TimeZone.current.secondsFromGMT())
    static let sdkVersion = "3.37.1"

    static var deviceId: String? {
        get async {
            return await MainActor.run(resultType: String?.self) {
                UIDevice.current.identifierForVendor?.uuidString
            }
        }
    }

    static let deviceType: String = "iOS"
    static let deviceMake: String = "Apple"
    static var networkType: RadarConnectionType {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com") else {
            return .unknown
        }
        var flags: SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(reachability, &flags)

        // 3. Determine connectivity from the flags
        let isReachable = flags.contains(.reachable)
        if !isReachable {
            return .unknown
        }

        let isWWAN = flags.contains(.isWWAN)
        if !isWWAN {
            return .wifi
        }

        guard let carrierTypes = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology,
            !carrierTypes.isEmpty
        else {
            return .unknown
        }

        let networkInfo = CTTelephonyNetworkInfo()
        if let technology = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            if technology == "CTRadioAccessTechnologyNR" {
                return .cellular5g
            } else if technology == "CTRadioAccessTechnologyLTE" {
                return .cellularLte
            } else if technology.contains("UMTS") || technology.contains("WCDMA") {
                return .cellular3g
            } else if technology.contains("GSM") || technology.contains("EDGE") {
                return .cellular2g
            }
        }
        return .cellular
    }
    @available(*, deprecated, renamed: "networkType.rawValue")
    static var networkTypeString: String {
        return networkType.rawValue
    }

    static var appInfo: [String: String] {
        var info = Bundle.main.infoDictionary ?? [:]
        info.merge(Bundle.main.localizedInfoDictionary ?? [:]) { (_, new) in new }

        return info.isEmpty
            ? [:]
            : [
                "name": info["CFBundleDisplayName"] as? String ?? "",
                "version": info["CFBundleShortVersionString"] as? String ?? "",
                "build": info["CFBundleVersion"] as? String ?? "",
                "namespace": Bundle.main.bundleIdentifier ?? "",
            ]
    }

    #if targetEnvironment(simulator)
        static let isSimulator: Bool = true
    #else
        static let isSimulator: Bool = false
    #endif

    static let locationBackgroundMode: Bool = {
        guard let info = Bundle.main.infoDictionary,
            let backgroundModes = info["UIBackgroundModes"] as? [String]
        else {
            return false
        }
        return backgroundModes.contains("location")
    }()

    static var locationAuthorization: String {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            let locationManager = CLLocationManager()
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .authorizedWhenInUse:
            return "GRANTED_FOREGROUND"
        case .authorizedAlways:
            return "GRANTED_BACKGROUND"
        case .denied:
            return "DENIED"
        case .restricted:
            return "DENIED"
        case .notDetermined:
            return "NOT_DETERMINED"
        @unknown default:
            return "NOT_DETERMINED"
        }
    }

    static var locationAccuracyAuthorization: String {
        if #available(iOS 14.0, *) {
            let locationManager = CLLocationManager()
            let accuracy = locationManager.accuracyAuthorization
            switch accuracy {
            case .reducedAccuracy:
                return "REDUCED"
            case .fullAccuracy:
                return "FULL"
            @unknown default:
                return "FULL"
            }
        } else {
            return "FULL"
        }
    }

    static var foreground: Bool {
        get async {
            return await MainActor.run(resultType: Bool.self) {
                UIApplication.shared.applicationState != .background
            }
        }
    }

    static var backgroundTimeRemaining: TimeInterval {
        get async {
            return await MainActor.run(resultType: TimeInterval.self) {
                let remaining = UIApplication.shared.backgroundTimeRemaining
                return remaining == TimeInterval.greatestFiniteMagnitude ? 180 : remaining
            }
        }
    }

    static func dictionaryToJson(_ dict: [String: Any]?) -> String {
        guard let dict = dict else { return "{}" }

        let jsonObject: Any
        if JSONSerialization.isValidJSONObject(dict) {
            jsonObject = dict
        } else {
            // Drop only the offending values rather than discarding the whole payload.
            // JSONSerialization throws an NSException (not a Swift error) for these, which
            // Swift do/catch can't catch — so we must sanitize *before* serializing.
            RadarLogger.shared.warning("RadarUtils.dictionaryToJson: input contained non-JSON values; sanitizing")
            jsonObject = jsonSanitized(dict) ?? [:]
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            RadarLogger.shared.warning("RadarUtils.dictionaryToJson failed: \(error.localizedDescription)")
            return "{}"
        }
    }

    static func dictionaryForLocation(_ location: CLLocation) -> [String: Any] {
        return location.toDict()
    }

    static func locationForDictionary(_ dict: [String: Any]?) -> CLLocation {
        if let dict {
            return CLLocation.from(dict: dict) ?? CLLocation(latitude: 0, longitude: 0)
        } else {
            return CLLocation(latitude: 0, longitude: 0)
        }
    }

    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func escapeNonAsciiCharacters(_ string: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(string.utf16.count)
        for codeUnit in string.utf16 {
            if codeUnit < 0x80, let scalar = Unicode.Scalar(codeUnit) {
                escaped.unicodeScalars.append(scalar)
            } else {
                escaped += String(format: "\\u%04x", codeUnit)
            }
        }
        return escaped
    }

    static func jsonSanitized(_ value: Any) -> Any? {
        switch value {
        case let dict as [AnyHashable: Any]:
            return dict.reduce(into: [String: Any]()) { result, pair in
                guard let key = pair.key as? String else { return }  // drop non-string keys
                if let sanitized = jsonSanitized(pair.value) {
                    result[key] = sanitized
                }
            }
        case let array as [Any]:
            return array.compactMap { jsonSanitized($0) }
        case is String, is NSNull:
            return value
        case let number as NSNumber:
            return number.doubleValue.isFinite ? number : nil  // reject NaN/±Inf
        default:
            return nil  // Data, Date, URL, custom objects
        }
    }

    static func jsonData(_ dict: NSDictionary?) -> Data? {
        guard let dict = dict else { return nil }
        let jsonObject: Any = JSONSerialization.isValidJSONObject(dict) ? dict : (jsonSanitized(dict) ?? [:])
        return try? JSONSerialization.data(withJSONObject: jsonObject)
    }
}

internal extension CLLocation {
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "horizontalAccuracy": horizontalAccuracy,
            "verticalAccuracy": verticalAccuracy,
            "timestamp": timestamp,
        ]
        if #available(iOS 15.0, *) {
            if let sourceInformation = sourceInformation {
                dict["mocked"] = (sourceInformation.isSimulatedBySoftware || sourceInformation.isProducedByAccessory)
            }
        }
        return dict
    }

    static func from(dict: [String: Any]) -> CLLocation? {
        guard let latitude = dict["latitude"] as? CLLocationDegrees,
            let longitude = dict["longitude"] as? CLLocationDegrees
        else {
            return nil
        }
        let horizontalAccuracy = dict["horizontalAccuracy"] as? CLLocationAccuracy ?? 0
        let verticalAccuracy = dict["verticalAccuracy"] as? CLLocationAccuracy ?? 0
        let timestamp = dict["timestamp"] as? Date ?? Date()

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, timestamp: timestamp)

        return location
    }
}

struct RadarError: Error {
    let status: RadarStatus
    let message: String?

    init(status: RadarStatus) {
        self.status = status
        self.message = nil
    }
    init(status: RadarStatus, message: String) {
        self.status = status
        self.message = message
    }
}
