//
//  RadarSwiftBridge.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

/**
 This protocol is defined in both swift and Objective-C and should match, it is implemented in objc and set as the bridge variable in swift during initialize, so swift can call private objc functionality without using module maps.
 
 usage: RadarSwift.bridge?.<function>()
 */
@objc
protocol RadarSwiftBridgeProtocol {
    func writeToLogBuffer(level: RadarLogLevel, type: RadarLogType, message: String, forcePersist: Bool)
    func setLogBufferPersistantLog(_ value: Bool)
}

@objc(RadarSwift) @objcMembers
class RadarSwift: NSObject {
    nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
}
