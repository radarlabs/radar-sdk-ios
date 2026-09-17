//
//  RadarFraudPayloadPreparer.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/15/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

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
            try RadarUtils.makeFraudEncryptionAttemptId()
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
}
