//
//  RadarSDKFraud.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Security

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

    static let getEncryptedFraudPayloadSelector = NSSelectorFromString(
        "getEncryptedFraudPayloadWithOptions:completionHandler:"
    )

    public func getEncryptedFraudPayload(
        options: [String: Any]
    ) async -> (RadarStatus, String?) {
        guard instance.responds(to: RadarSDKFraud.getEncryptedFraudPayloadSelector) else {
            return (.errorPlugin, nil)
        }

        let result = await withCheckedContinuation { continuation in
            let completionHandler: @convention(block) ([String: Sendable]?) -> Void = {
                payload in
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

    static func encryptionEnvironment(forHost host: String) -> String? {
        let normalizedHost = host.trimmingCharacters(
            in: CharacterSet(charactersIn: "/")
        )

        switch normalizedHost {
        case "https://api.radar.io",
             "https://api-verified.radar.io",
             "https://api-verified.radar.com":
            return "production"

        case "https://api.radar-staging.com",
             "https://api-verified.radar-staging.io":
            return "staging"

        default:
            return nil
        }
    }

    static func makeEncryptionAttemptId() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 16)

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            throw RadarError(
                status: .errorUnknown,
                message: "Failed to generate encryption attempt ID"
            )
        }

        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
