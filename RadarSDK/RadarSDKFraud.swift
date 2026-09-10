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

    func prepareEncryptedRequest(
        _ request: URLRequest,
        canonicalRoute: String,
        options fraudOptions: [String: Any]
    ) async throws -> URLRequest {
        guard
            let url = request.url,
            request.httpMethod == "POST",
            url.path == canonicalRoute,
            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            ),
            let bodyData = request.httpBody,
            var body = try JSONSerialization.jsonObject(
                with: bodyData
            ) as? [String: Any],
            let installId = body["installId"] as? String
        else {
            throw RadarError(
                status: .errorUnknown,
                message: "Invalid fraud encryption request"
            )
        }

        let environment = try Self.encryptionEnvironment(for: components)

        let options = try Self.encryptionOptions(
            for: request,
            canonicalRoute: canonicalRoute,
            installId: installId,
            environment: environment,
            options: fraudOptions
        )
        let (status, payload) = await getEncryptedFraudPayload(options: options)

        guard status == .success else {
            throw RadarError(status: status)
        }

        guard let payload, !payload.isEmpty else {
            throw RadarError(
                status: .errorUnknown,
                message: "Missing encrypted fraud payload"
            )
        }

        body["fraudPayload"] = payload

        var encryptedRequest = request
        encryptedRequest.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )

        return encryptedRequest
    }

    private static func encryptionEnvironment(for components: URLComponents) throws -> String {
        var components = components
        components.path = ""
        components.query = nil
        components.fragment = nil

        guard let requestHost = components.string,
            let environment = encryptionEnvironment(forHost: requestHost)
        else {
            throw RadarError(status: .errorPlugin, message: "Unsupported fraud encryption host")
        }
        return environment
    }

    private static func encryptionOptions(
        for request: URLRequest,
        canonicalRoute: String,
        installId: String,
        environment: String,
        options fraudOptions: [String: Any]
    ) throws -> [String: Any] {
        var options = fraudOptions
        options["method"] = request.httpMethod
        options["canonicalRoute"] = canonicalRoute
        options["environment"] = environment
        options["encryptionAttemptId"] =
            try RadarUtils.makeFraudEncryptionAttemptId()
        options["issuedAt"] = Int(Date().timeIntervalSince1970)
        options["installId"] = installId
        options["origin"] =
            request.value(forHTTPHeaderField: "Origin")
        options["product"] =
            request.value(forHTTPHeaderField: "X-Radar-Product")
        options["sdkVersion"] =
            request.value(forHTTPHeaderField: "X-Radar-SDK-Version")
        options["authorization"] =
            request.value(forHTTPHeaderField: "Authorization")

        return options
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

}
