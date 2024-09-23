//
//  RadarUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/23/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

@objc public class RadarUtils: NSObject {

    @objc public static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    @objc public static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let machineString = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return machineString
    }

    @MainActor
    @objc public static var deviceOS: String {
        return UIDevice.current.systemVersion
    }

    @objc public static var country: String? {
        return Locale.current.regionCode
    }

    @objc public static var timeZoneOffset: NSNumber {
        return NSNumber(value: TimeZone.current.secondsFromGMT())
    }

    @objc public static var sdkVersion: String {
        return "3.16.0"
    }

    @MainActor
    @objc public static var deviceId: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }

    @objc public static var deviceType: String {
        return "iOS"
    }

    @objc public static var deviceMake: String {
        return "Apple"
    }

    @objc public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    @objc public static var locationBackgroundMode: Bool {
        guard let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else {
            return false
        }
        return backgroundModes.contains("location")
    }

    @objc public static var locationAuthorization: String {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .authorizedWhenInUse:
            return "GRANTED_FOREGROUND"
        case .authorizedAlways:
            return "GRANTED_BACKGROUND"
        case .denied, .restricted:
            return "DENIED"
        default:
            return "NOT_DETERMINED"
        }
    }

    @objc public static var locationAccuracyAuthorization: String {
        let locationManager = CLLocationManager()
        if #available(iOS 14.0, *) {
            let accuracyAuthorization = locationManager.accuracyAuthorization
            switch accuracyAuthorization {
            case .reducedAccuracy:
                return "REDUCED"
            default:
                return "FULL"
            }
        } else {
            return "FULL"
        }
    }

    @MainActor
    @objc public static var foreground: Bool {
        return UIApplication.shared.applicationState != .background
    }

    @MainActor
    @objc public static var backgroundTimeRemaining: TimeInterval {
        let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        return (backgroundTimeRemaining == TimeInterval.infinity) ? 180 : backgroundTimeRemaining
    }

    @objc public static func locationFor(dictionary: [String: Any]) -> CLLocation? {
        guard let latitude = dictionary["latitude"] as? CLLocationDegrees,
              let longitude = dictionary["longitude"] as? CLLocationDegrees else {
            return nil
        }
        let altitude = dictionary["altitude"] as? CLLocationDistance ?? 0
        let horizontalAccuracy = dictionary["horizontalAccuracy"] as? CLLocationAccuracy ?? kCLLocationAccuracyBest
        let verticalAccuracy = dictionary["verticalAccuracy"] as? CLLocationAccuracy ?? kCLLocationAccuracyBest
        let timestamp = dictionary["timestamp"] as? Date ?? Date()

        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          timestamp: timestamp)
    }

    @objc public static func dictionaryFor(location: CLLocation) -> [String: Any] {
        var dict: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "horizontalAccuracy": location.horizontalAccuracy,
            "verticalAccuracy": location.verticalAccuracy,
            "timestamp": location.timestamp
        ]
        
        if #available(iOS 15.0, *) {
            if let sourceInformation = location.sourceInformation {
                dict["mocked"] = sourceInformation.isSimulatedBySoftware || sourceInformation.isProducedByAccessory
            }
        }
        return dict
    }

    @objc public static func dictionaryToJson(_ dict: [String: Any]?) -> String {
        guard let dict = dict else { return "{}" }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            return "{}"
        }
    }

    // MARK: - Threading

    @MainActor // probably can't be here, we'll see
    @objc public static func runOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
