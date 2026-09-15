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

    func prepareBody(
        _ body: [String: Any],
        method: String,
        canonicalRoute: String,
        headers: [String: String],
    ) async throws -> [String: Any] {
        guard method == "POST",
            let installId = body["installId"] as? String
        else {
            throw RadarError(
                status: .errorUnknown,
                message: "Invalid fraud encryption request"
            )
        }

        var encryptionOptions = options
        encryptionOptions["method"] = method
        encryptionOptions["canonicalRoute"] = canonicalRoute
        encryptionOptions["encryptionAttemptId"] =
            try RadarUtils.makeFraudEncryptionAttemptId()
        encryptionOptions["issuedAt"] = Int(Date().timeIntervalSince1970)
        encryptionOptions["installId"] = installId
        encryptionOptions["origin"] = header("Origin", in: headers)
        encryptionOptions["product"] = header("X-Radar-Product", in: headers)
        encryptionOptions["sdkVersion"] = header(
            "X-Radar-SDK-Version",
            in: headers
        )
        encryptionOptions["authorization"] = header(
            "Authorization",
            in: headers
        )

        let (status, payload) = await fraudSDK.getEncryptedFraudPayload(options: encryptionOptions)

        guard status == .success else {
            throw RadarError(status: status)
        }

        guard let payload, !payload.isEmpty else {
            throw RadarError(
                status: .errorUnknown,
                message: "Missing encrypted fraud payload"
            )
        }

        var encryptedBody = body
        encryptedBody["fraudPayload"] = payload
        return encryptedBody
    }

    private func header(
        _ name: String,
        in headers: [String: String]
    ) -> String? {
        headers.first {
            $0.key.caseInsensitiveCompare(name) == .orderedSame
        }?.value
    }
}
