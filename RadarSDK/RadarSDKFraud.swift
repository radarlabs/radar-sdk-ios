//
//  RadarSDKFraud.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

final class RadarSDKFraud: @unchecked Sendable {

    let instance: NSObject

    init?(instance: NSObject) {
        if !instance.responds(to: RadarSDKFraud.initializeSelector) || !instance.responds(to: RadarSDKFraud.getFraudPayloadSelector) {
            return nil
        }
        self.instance = instance
    }

    static let shared: RadarSDKFraud? = {
        guard let radarSDKFraudClass = NSClassFromString("RadarSDKFraud") as? NSObject.Type else {
            return nil
        }
        let sharedInstanceSelector = NSSelectorFromString("sharedInstance")
        guard radarSDKFraudClass.responds(to: sharedInstanceSelector),
            let result = radarSDKFraudClass.perform(sharedInstanceSelector),
            let instance = result.takeRetainedValue() as? NSObject
        else {
            return nil
        }
        return RadarSDKFraud(instance: instance)
    }()

    static let initializeSelector = NSSelectorFromString("initializeWithOptions:")
    public func initialize(options: [String: Any]) {
        instance.perform(RadarSDKFraud.initializeSelector, with: options)
    }

    static let getFraudPayloadSelector = NSSelectorFromString("getFraudPayloadWithOptions:completionHandler:")
    public func getFraudPayload(sdkConfiguration: RadarSdkConfiguration?) async -> (RadarStatus, String?) {
        let options = sdkConfiguration?.dictionaryValue() ?? [:]

        let result = await withCheckedContinuation { continuation in
            let completionHandler: @convention(block) ([String: Sendable]?) -> Void = { payload in
                continuation.resume(returning: payload)
            }
            instance.perform(RadarSDKFraud.getFraudPayloadSelector, with: options, with: completionHandler)
        }

        let error = result?["error"] as? String
        let payload = result?["payload"] as? String

        if result == nil || error != nil || payload == nil {
            return (.errorUnknown, nil)
        }
        return (.success, payload)
    }
}
