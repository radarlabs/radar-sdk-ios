//
//  VerifiedResponse.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import RadarSDK

/// Presents SDK results for QA. Access decisions belong to the receiving backend.
struct VerifiedResponse {
    let format: RadarResponseFormat
    let evaluationID: String?
    let token: String?
    let expiresAt: Date?
    let expiresIn: TimeInterval?
    let passed: Bool?
    let beaconCount: Int?
    private let response: [AnyHashable: Any]

    init(_ result: RadarVerifiedLocationToken) {
        format = result.format
        evaluationID = result._id
        token = result.token
        expiresAt = result.expiresAt
        expiresIn = result.format == .id ? nil : result.expiresIn
        passed = result.format == .id ? nil : result.passed
        beaconCount = result.format == .jws ? result.user?.beacons?.count ?? 0 : nil
        response = result.dictionaryValue()
    }

    init(_ result: RadarRevealRiskToken) {
        format = result.format
        evaluationID = result._id
        token = result.token
        expiresAt = result.expiresAt
        expiresIn = result.expiresIn?.doubleValue
        passed = nil
        beaconCount = nil
        response = result.dictionaryValue()
    }

    var formatName: String {
        switch format {
        case .jws: return "jws"
        case .jwe: return "jwe"
        case .id: return "id"
        @unknown default: return "unknown"
        }
    }

    /// Every response format relays only the opaque token and/or evaluation ID to the backend.
    var relayJSON: String? {
        guard token != nil || evaluationID != nil else { return nil }
        var payload: [AnyHashable: Any] = [:]
        if let token { payload["token"] = token }
        if let evaluationID { payload["_id"] = evaluationID }
        return Self.json(payload)
    }

    var summary: String {
        "\(formatName), ID: \(evaluationID ?? "unavailable")"
    }

    var beaconSummary: String {
        if let beaconCount { return "\(beaconCount) beacons" }
        return "beacons unavailable in \(formatName) responses"
    }

    var detail: String {
        let expiration = expiresAt.map { ISO8601DateFormatter().string(from: $0) } ?? "unavailable"
        let lifetime = expiresIn.map { "\($0) seconds" } ?? "unavailable"
        var lines = [
            "Format: \(formatName)",
            "Evaluation ID: \(evaluationID ?? "unavailable")",
            "Expires at: \(expiration)",
            "Expires in: \(lifetime)",
        ]
        if let passed { lines.append("Passed (unverified): \(passed)") }
        lines.append("The backend must verify the result before allowing access.")
        if let relayJSON {
            lines += [
                "", "Backend relay JSON (long-press this entry to copy):", relayJSON,
            ]
        }
        lines += ["", "SDK response:", Self.json(response) ?? "unavailable"]
        return lines.joined(separator: "\n")
    }

    private static func json(_ dictionary: [AnyHashable: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dictionary),
            let data = try? JSONSerialization.data(
                withJSONObject: dictionary,
                options: [.prettyPrinted, .sortedKeys]
            )
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
