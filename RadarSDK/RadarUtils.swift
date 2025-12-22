//
//  RadarUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/19/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration
import CoreTelephony

let SDK_VERSION = "3.25.0"

enum RadarConnectionType: Int {
    case unknown
    case wifi
    case cellular
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
            if #available(iOS 13.0, *) {
                return await MainActor.run(resultType: String.self) {
                    UIDevice.current.systemName
                }
            }
        }
    }
    
    static let country = Locale.current.regionCode
    static let timezoneOffset = TimeZone.current.secondsFromGMT()
    static let sdkVersion = SDK_VERSION
    static var deviceId: String? {
        get async {
            if #available(iOS 13.0, *) {
                return await MainActor.run(resultType: String?.self) {
                    UIDevice.current.identifierForVendor?.uuidString
                }
            }
        }
    }
    
    static let deviceType: String = "iOS"
    static let deviceMake: String = "Apple"
    static var networkType: RadarConnectionType {
        get {
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
               carrierTypes.count == 0 else {
                return .unknown
            }
            
            return .cellular
        }
    }
    
#if targetEnvironment(simulator)
    static let isSimulator: Bool = true
#else
    static let isSimulator: Bool = false
#endif
    
    static let locationBackgorundMode: Bool = {
        guard let info = Bundle.main.infoDictionary,
            let backgroundModes = info["UIBackgroundModes"] as? [String] else {
            return false
        }
        return backgroundModes.contains("location");
    }()
    
    static var locationAuthorization: String {
        get {
            let status: CLAuthorizationStatus
            if #available(iOS 14.0, *) {
                let locationManager = CLLocationManager()
                status = locationManager.authorizationStatus
            } else {
                status = CLLocationManager.authorizationStatus()
            }
            switch status {
            case .authorizedWhenInUse:
                return "GRANTED_FOREGROUND";
            case .authorizedAlways:
                return "GRANTED_BACKGROUND";
            case .denied:
                return "DENIED";
            case .restricted:
                return "DENIED";
            case .notDetermined:
                return "NOT_DETERMINED";
            @unknown default:
                return "NOT_DETERMINED";
            }
            
        }
    }
    
    static var locationAccuracyAuthorization: String {
        get {
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
    }
    
    static var foreground: Bool {
        get async {
            if #available(iOS 13.0, *) {
                return await MainActor.run(resultType: Bool.self) {
                    UIApplication.shared.applicationState != .background
                }
            }
        }
    }
    
    static var backgroundTimeRemaining: TimeInterval {
        get async {
            if #available(iOS 13.0, *) {
                return await MainActor.run(resultType: TimeInterval.self) {
                    max(180, UIApplication.shared.backgroundTimeRemaining)
                }
            }
        }
    }
    
    static func dictToJson(_ dict: [String: Any]?) -> String {
        guard let dict else { return "{}" }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            guard let string = String(data: data, encoding: .utf8) else {
                // data could not be converted to string
                return "{}"
            }
            return string
        } catch {
            // failed to json serialize
            RadarLogger.shared.warning("RadarUtils.dictToJson failed: \(error.localizedDescription)")
            return "{}"
        }
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
    }
    
    static func from(dict: [String: Any]) -> CLLocation {
        let latitude = dict["latitude"] as! CLLocationDegrees
        let longitude = dict["longitude"] as! CLLocationDegrees
        let horizontalAccuracy = dict["horizontalAccuracy"] as! CLLocationAccuracy
        let verticalAccuracy = dict["verticalAccuracy"] as! CLLocationAccuracy
        let timestamp = dict["timestamp"] as! Date
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, timestamp: timestamp)
        
        return location
    }
}

+ (CLLocation *)locationForDictionary:(NSDictionary *_Nonnull)dict;
+ (NSDictionary *)dictionaryForLocation:(CLLocation *)location;
+ (NSString *)dictionaryToJson:(NSDictionary *)dict;
+ (void)runOnMainThread:(dispatch_block_t)block;

+ (RadarConnectionType)networkType;
+ (NSString *)networkTypeString;

+ (NSDictionary *)appInfo;
