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
        guard instance.responds(to: Self.initializeSelector),
            instance.responds(to: Self.prepareFraudPayloadSelector),
            instance.responds(to: Self.isSharingSelector),
            instance.responds(to: Self.clearSharingSelector)
        else {
            RadarLogger.shared.warning(
                "RadarSDKFraud is incompatible with this Core SDK; update the fraud SDK to a compatible version."
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

    static let isSharingSelector = NSSelectorFromString("isSharing")
    public func isSharing() -> Bool {
        let imp = instance.method(for: RadarSDKFraud.isSharingSelector)

        typealias Function = @convention(c) (AnyObject, Selector) -> Bool
        let function = unsafeBitCast(imp, to: Function.self)

        let result = function(instance, RadarSDKFraud.isSharingSelector)
        return result
    }

    static let clearSharingSelector = NSSelectorFromString("clearSharing")
    public func clearSharing() {
        instance.perform(RadarSDKFraud.clearSharingSelector)
    }

    static let prepareFraudPayloadSelector = NSSelectorFromString(
        "prepareFraudPayloadWithOptions:completionHandler:"
    )

    func prepareFraudPayload(
        options: [String: Any]
    ) async throws -> RadarPreparedFraudPayload {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RadarPreparedFraudPayload, Error>) in

            let completionHandler: @convention(block) ([String: Any]?) -> Void = { result in
                guard
                    result?["error"] == nil,
                    let instance = result?["preparedPayload"] as? NSObject,
                    let prepared = RadarPreparedFraudPayload(instance: instance)
                else {
                    continuation.resume(
                        throwing: RadarError(status: .errorUnknown)
                    )
                    return
                }

                continuation.resume(returning: prepared)
            }

            instance.perform(
                Self.prepareFraudPayloadSelector,
                with: options,
                with: completionHandler
            )
        }
    }
}

// The fraud SDK object holds immutable collected signals.
// Each seal creates its own encryption state.
@objc(RadarPreparedFraudPayloadWrapper)
final class RadarPreparedFraudPayload: NSObject, @unchecked Sendable {
    private let instance: NSObject

    private static let sealSelector = NSSelectorFromString(
        "sealWithOptions:"
    )

    init?(instance: NSObject) {
        guard instance.responds(to: Self.sealSelector) else {
            return nil
        }
        self.instance = instance
        super.init()
    }

    func seal(options: [String: Any]) throws -> String {
        let result = instance.perform(
            Self.sealSelector,
            with: options
        )?.takeUnretainedValue() as? [String: Any]

        guard
            result?["error"] == nil,
            let payload = result?["payload"] as? String,
            !payload.isEmpty
        else {
            throw RadarError(status: .errorUnknown)
        }

        return payload
    }

    func getEncryptedPayload(
        installId: String,
        canonicalRoute: String,
        origin: String? = nil,
        product: String? = nil,
        sdkVersion: String?,
        authorization: String?
    ) throws -> String {
        var options: [String: Any] = [
            "method": "POST",
            "canonicalRoute": canonicalRoute,
            "encryptionAttemptId":
                try Self.makeFraudEncryptionAttemptId(),
            "issuedAt": Int(Date().timeIntervalSince1970),
            "installId": installId
        ]
        options["origin"] = origin
        options["product"] = product
        options["sdkVersion"] = sdkVersion
        options["authorization"] = authorization

        return try seal(options: options)
    }

    @objc(prepareRequest:error:)
    func prepareRequest(_ request: URLRequest) throws -> URLRequest {
        guard
            request.httpMethod == "POST",
            let route = request.url?.path,
            let data = request.httpBody,
            var body = try JSONSerialization.jsonObject(with: data)
                as? [String: Any],
            let installId = body["installId"] as? String
        else {
            throw RadarError(status: .errorUnknown)
        }

        body["fraudPayload"] = try getEncryptedPayload(
            installId: installId,
            canonicalRoute: route,
            origin: request.value(forHTTPHeaderField: "X-Radar-Mobile-Origin"),
            product: request.value(forHTTPHeaderField: "X-Radar-Product"),
            sdkVersion: request.value(forHTTPHeaderField: "X-Radar-SDK-Version"),
            authorization: request.value(forHTTPHeaderField: "Authorization")
        )

        var preparedRequest = request
        preparedRequest.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )
        return preparedRequest
    }

    static func makeFraudEncryptionAttemptId() throws -> String {
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
