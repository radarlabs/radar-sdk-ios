//
//  RadarUtils.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/2/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

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
}
