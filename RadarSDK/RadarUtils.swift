//
//  RadarUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/2/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SystemConfiguration
import CoreTelephony

class RadarUtils {

    public static let deviceMake: String = "Apple"
    public static let deviceType: String = "iOS"
    public static let sdkVersion: String = "3.23.2"

    nonisolated(unsafe) public static var deviceOS: String = ""
    nonisolated(unsafe) public static var deviceModel: String = ""

    public static var appInfo: [String: String] {
        get {
            let infoDict = Bundle.main.infoDictionary ?? [:]
            let localized = Bundle.main.localizedInfoDictionary ?? [:]
            let info = infoDict.merging(localized) { (_, new) in new }
            var appInfo = [String:String]()

            appInfo["name"] = info["CFBundleDisplayName"] as? String
            appInfo["version"] = info["CFBundleShortVersionString"] as? String
            appInfo["build"] = info["CFBundleVersion"] as? String
            appInfo["namespace"] = Bundle.main.bundleIdentifier

            return appInfo
        }
    }

    @MainActor
    public static func initalize() {
        deviceOS = UIDevice.current.systemVersion
        deviceModel = {
            var systemInfo = utsname()
            uname(&systemInfo)

            let identifier = withUnsafePointer(to: systemInfo.machine) { ptr -> String in
                ptr.withMemoryRebound(to: CChar.self, capacity: 1) { cptr in
                    String(validatingCString: cptr) ?? ""
                }
            }
            return identifier
        }()
    }
    
    public static func toJSONString(dict: [String: Any]) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            return String(data: data, encoding: .utf8) ?? "{}"
        } else {
            return "{}"
        }
    }
    
    public static var networkType: RadarConnectionType {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com") else {
            return .unknown
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return .unknown
        }
        // Evaluate flags
        if !flags.contains(.reachable) {
            return .unknown
        }
        if !flags.contains(.isWWAN) {
            return .wifi
        }
        // cellular type
        // Check if current radio technology exists
        guard let radioTech = CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?.values.first else {
            return .unknown
        }
        
        switch radioTech {
        case CTRadioAccessTechnologyLTE:
            return .cellularLTE;
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .cellular3G
                
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return .cellular2G
        default:
            if #available(iOS 14.1, *) {
                switch radioTech {
                case CTRadioAccessTechnologyNR,
                     CTRadioAccessTechnologyNRNSA:
                    return .cellular5G;
                default:
                    return .cellular
                }
            }
            return .cellular
        }
    }
    
    public static var networkTypeString: String {
        switch(networkType) {
        case .wifi:
            return "wifi";
        case .cellular:
            return "cellular";
        case .cellular2G:
            return "cellular2G";
        case .cellular3G:
            return "cellular3G";
        case .cellularLTE:
            return "cellularLTE";
        case .cellular5G:
            return "cellular5G";
        case .unknown:
            return "unknown";
        default:
            return "unknown";
        }
    }
}
