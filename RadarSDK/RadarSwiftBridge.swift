//
//  RadarSwiftBridge.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc
protocol RadarSwiftBridgeProtocol {
    func writeToLogBuffer(level: RadarLogLevel, type: RadarLogType, message: String, forcePersist: Bool)
    func setLogBufferPersistantLog(_ value: Bool)
}

@objc(RadarSwift) @objcMembers
class RadarSwift: NSObject {
    nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
}
