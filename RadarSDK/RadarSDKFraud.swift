//
//  RadarFraud.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

final class RadarSDKFraud: @unchecked Sendable {
    
    let instance: NSObject
    
    init(instance: NSObject) {
        self.instance = instance
    }
    
    static let shared: RadarSDKFraud? = {
        guard let RadarSDKFraudClass = NSClassFromString("RadarSDKFraud") as? NSObject.Type else {
            return nil
        }
        guard let instance = RadarSDKFraudClass.value(forKey: "sharedInstance") as? NSObject else {
            return nil
        }
        return RadarSDKFraud(instance: instance)
    }()
    
    public func initialize(options: [String: Any]) {
        let selector = NSSelectorFromString("initializeWithOptions:")
        instance.perform(selector, with: options)
    }
    
    public func getFraudPayload(sdkConfiguration: RadarSdkConfiguration?) async -> (RadarStatus, String?) {
        let selector = NSSelectorFromString("getFraudPayloadWithOptions:completionHandler:")
        let options = sdkConfiguration?.dictionaryValue() ?? [:]
        
        
        let result = await withCheckedContinuation { continuation in
            let completionHandler: @convention(block) ([String: Sendable]?) -> Void = { payload in
                continuation.resume(returning: payload)
            }
            instance.perform(selector, with: options, with: completionHandler)
        }
        
        let error = result?["error"] as? String
        let payload = result?["payload"] as? String
        
        if (result == nil || error != nil || payload == nil) {
            return (.errorUnknown, nil)
        }
        return (.success, payload)
    }
}
