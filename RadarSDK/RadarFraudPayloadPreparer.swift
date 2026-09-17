//
//  RadarFraudPayloadPreparer.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Security

struct RadarFraudPayloadPreparer {
    let fraudSDK: RadarSDKFraud
    let options: [String: Any]

    func getEncryptedPayload(
        installId: String,
        canonicalRoute: String,
        origin: String? = nil,
        product: String? = nil,
        sdkVersion: String?,
        authorization: String?
    ) async throws -> String {
        var encryptionOptions = options
        encryptionOptions["method"] = "POST"
        encryptionOptions["canonicalRoute"] = canonicalRoute
        encryptionOptions["encryptionAttemptId"] =
            try Self.makeFraudEncryptionAttemptId()
        encryptionOptions["issuedAt"] = Int(Date().timeIntervalSince1970)
        encryptionOptions["installId"] = installId
        encryptionOptions["origin"] = origin
        encryptionOptions["product"] = product
        encryptionOptions["sdkVersion"] = sdkVersion
        encryptionOptions["authorization"] = authorization

        let (status, payload) = await fraudSDK.getEncryptedFraudPayload(
            options: encryptionOptions
        )

        guard status == .success else {
            throw RadarError(status: status)
        }

        guard let payload, !payload.isEmpty else {
            throw RadarError(
                status: .errorUnknown,
                message: "Missing encrypted fraud payload"
            )
        }

        return payload
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
