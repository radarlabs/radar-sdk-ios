//
//  RadarFraud.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation


class RadarSDKFraud: @unchecked Sendable {
    
    static let shared = RadarSDKFraud(shared: true)
    
    let instance: NSObject?
    init(shared: Bool = false) {
        guard let cls = NSClassFromString("RadarSDKFraud") as? NSObject.Type else {
            instance = nil
            return
        }
        if shared {
            guard let bridge = RadarSwift.bridge else {
                instance = nil
                return
            }
            instance = bridge.getSharedInstance(target: cls)
        } else {
            instance = cls.init()
        }
    }
    
    public func initialize(options: [String: Any]) {
        guard let bridge = RadarSwift.bridge, let instance else { return }
        
        let selector = NSSelectorFromString("initializeWithOptions:")
        bridge.invoke(target:instance, selector:selector, args: [options])
    }
    
    public func getFraudPayload(sdkConfiguration: RadarSdkConfiguration?) async -> (RadarStatus, String?) {
        guard let bridge = RadarSwift.bridge, let instance else {
            return (.errorPlugin, nil)
        }
        let options = sdkConfiguration?.dictionaryValue() ?? [:]
        let result = await withCheckedContinuation { continuation in
            let completion: @convention(block) ([String: Sendable]?) -> Void = { result in
                continuation.resume(returning: result)
            }
            let selector = NSSelectorFromString("getFraudPayloadWithOptions:completionHandler:")
            bridge.invoke(target:instance, selector:selector, args: [options, completion])
        }

        let error = result?["error"] as? String
        let payload = result?["payload"] as? String
        
        if (result == nil || error != nil || payload == nil) {
            return (.errorUnknown, nil)
        }
        return (.success, payload)
    }
}
