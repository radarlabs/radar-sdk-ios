//
//  RadarUtils.swift
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

@objc(RadarUtils) class RadarUtils: NSObject {

    @objc static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    @objc static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let machineString = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return machineString
    }

    @objc static var deviceOS: String {
        return UIDevice.current.systemVersion
    }

    @objc static var country: String? {
        return Locale.current.regionCode
    }

    @objc static var timeZoneOffset: NSNumber {
        return NSNumber(value: TimeZone.current.secondsFromGMT())
    }

    @objc static var sdkVersion: String {
        return "3.16.0"
    }

    @objc static var deviceId: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }

    @objc static var deviceType: String {
        return "iOS"
    }

    @objc static var deviceMake: String {
        return "Apple"
    }

    @objc static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    @objc static var locationBackgroundMode: Bool {
        guard let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] else {
            return false
        }
        return backgroundModes.contains("location")
    }

    @objc static var locationAuthorization: String {
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

    @objc static var locationAccuracyAuthorization: String {
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

    @objc static var foreground: Bool {
        return UIApplication.shared.applicationState != .background
    }

    @objc static var backgroundTimeRemaining: TimeInterval {
        let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        return (backgroundTimeRemaining == TimeInterval.infinity) ? 180 : backgroundTimeRemaining
    }

    @objc static func locationFor(dictionary: [String: Any]) -> CLLocation? {
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

    @objc static func dictionaryFor(location: CLLocation) -> [String: Any] {
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

    @objc static func dictionaryToJson(_ dict: [String: Any]?) -> String {
        guard let dict = dict else { return "{}" }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            return "{}"
        }
    }

    @objc static func extractGeofenceIdAndTimestampFrom(identifier: String) -> Dictionary<String, String>? {
        let components = identifier.components(separatedBy: "_");
        
        if (components.count != 4) {
            return nil; // Invalid format
        }
            
        let geofenceId = components[2];
        let registeredAt = components[3];

        return ["geofenceId": geofenceId, "registeredAt": registeredAt];
    }
    
    // MARK: - Threading
    
    @objc static func runOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
