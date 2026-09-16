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
        // Encryption and sharing are independent capabilities. Older fraud SDKs
        // can still provide sharing even when they cannot encrypt payloads.
        guard instance.responds(to: Self.initializeSelector) else {
            RadarLogger.shared.warning(
                "RadarSDKFraud is incompatible: missing required initialization method."
            )
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

    static let getEncryptedFraudPayloadSelector = NSSelectorFromString(
        "getEncryptedFraudPayloadWithOptions:completionHandler:"
    )

    public func getEncryptedFraudPayload(
        options: [String: Any]
    ) async -> (RadarStatus, String?) {
        guard instance.responds(to: Self.getEncryptedFraudPayloadSelector) else {
            RadarLogger.shared.warning("RadarSDKFraud does not support encrypted payloads; update the fraud SDK.")
            return (.errorPlugin, nil)
        }

        let result = await withCheckedContinuation { continuation in
            let completionHandler: @convention(block) ([String: Sendable]?) -> Void = { payload in
                continuation.resume(returning: payload)
            }

            instance.perform(
                RadarSDKFraud.getEncryptedFraudPayloadSelector,
                with: options,
                with: completionHandler
            )
        }

        let error = result?["error"] as? String
        let payload = result?["payload"] as? String

        if result == nil || error != nil || payload == nil {
            return (.errorUnknown, nil)
        }

        return (.success, payload)
    }

    static let isSharingSelector = NSSelectorFromString("isSharing")
    public func isSharing() -> Bool {
        guard instance.responds(to: Self.isSharingSelector) else {
            return false
        }
        let imp = instance.method(for: RadarSDKFraud.isSharingSelector)

        typealias Function = @convention(c) (AnyObject, Selector) -> Bool
        let function = unsafeBitCast(imp, to: Function.self)

        let result = function(instance, RadarSDKFraud.isSharingSelector)
        return result
    }

    static let clearSharingSelector = NSSelectorFromString("clearSharing")
    public func clearSharing() {
        guard instance.responds(to: Self.clearSharingSelector) else {
            return
        }
        instance.perform(RadarSDKFraud.clearSharingSelector)
    }
}
