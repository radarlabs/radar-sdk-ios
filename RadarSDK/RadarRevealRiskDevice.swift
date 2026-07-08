//
//  RadarRevealRiskDevice.swift
//  radar-sdk-ios-old
//
//  Created by Brian Siebert on 7/8/26.
//

//deviceId: string;
//deviceType: string; // iOS, Android, Web,
//deviceMake: string;
//deviceModel: string;
//deviceOSName: string; // iOS, Android, MacOS, Windows, undefined (web only)
//deviceOSVersion: string;
//sdkVersion: string;
//xPlatformType: string; // cross platform like RN/Flutter/Capacitor etc.
//installId: string;
//
//appId: string;
//appName: string;
//appVersion: string;
//appBuild: string;

struct RadarRevealRiskDevice: Codable, Sendable {
    let deviceId: String
    let deviceType: String
    let deviceMake: String
    let deviceModel: String
    let deviceOSName: String
    let deviceOSVersion: String
    let sdkVersion: String
    let xPlatformType: String
    let installId: String
    let appId: String
    let appName: String
    let appVersion: String
    let appBuild: String

    enum CodingKeys: String, CodingKey {
        case deviceId
        case deviceType
        case deviceMake
        case deviceModel
        case deviceOSName
        case deviceOSVersion
        case sdkVersion
        case xPlatformType
        case installId
        case appId
        case appName
        case appVersion
        case appBuild
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        deviceType = try container.decode(String.self, forKey: .deviceType)
        deviceMake = try container.decode(String.self, forKey: .deviceMake)
        deviceModel = try container.decode(String.self, forKey: .deviceModel)
        deviceOSName = try container.decode(String.self, forKey: .deviceOSName)
        deviceOSVersion = try container.decode(String.self, forKey: .deviceOSVersion)
        sdkVersion = try container.decode(String.self, forKey: .sdkVersion)
        xPlatformType = try container.decode(String.self, forKey: .xPlatformType)
        installId = try container.decode(String.self, forKey: .installId)
        appId = try container.decode(String.self, forKey: .appId)
        appName = try container.decode(String.self, forKey: .appName)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        appBuild = try container.decode(String.self, forKey: .appBuild)
    }

    init(deviceId: String, deviceType: String, deviceMake: String, deviceModel: String, deviceOSName: String, deviceOSVersion: String, sdkVersion: String, xPlatformType: String, installId: String, appId: String, appName: String, appVersion: String, appBuild: String) {
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.deviceMake = deviceMake
        self.deviceModel = deviceModel
        self.deviceOSName = deviceOSName
        self.deviceOSVersion = deviceOSVersion
        self.sdkVersion = sdkVersion
        self.xPlatformType = xPlatformType
        self.installId = installId
        self.appId = appId
        self.appName = appName
        self.appVersion = appVersion
        self.appBuild = appBuild
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(deviceMake, forKey: .deviceMake)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(deviceOSName, forKey: .deviceOSName)
        try container.encode(deviceOSVersion, forKey: .deviceOSVersion)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(xPlatformType, forKey: .xPlatformType)
        try container.encode(installId, forKey: .installId)
        try container.encode(appId, forKey: .appId)
        try container.encode(appName, forKey: .appName)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(appBuild, forKey: .appBuild)
    }
}
