//
//  ExampleVerifiedResponseTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("Example verified response presentation")
struct ExampleVerifiedResponseTests {
    private func trackObject(format: String? = nil) -> [String: Any] {
        var object: [String: Any] = [
            "_id": "evaluation-id",
            "token": "opaque-token",
            "expiresAt": "2030-01-01T00:00:00.000Z",
            "expiresIn": 90,
            "passed": true,
            "user": [
                "_id": "user-id",
                "location": ["coordinates": [-73.9, 40.7]],
            ],
            "events": [],
            "failureReasons": [],
        ]
        if let format { object["format"] = format }
        return object
    }

    private func relay(_ response: VerifiedResponse) throws -> [String: Any] {
        let json = try #require(response.relayJSON)
        let data = try #require(json.data(using: .utf8))
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test(arguments: [false, true])
    func legacyResponsesHaveANormalizedRelayFormat(explicit: Bool) throws {
        let token = try #require(
            RadarVerifiedLocationToken(object: trackObject(format: explicit ? "jws" : nil))
        )
        let response = VerifiedResponse(token)

        #expect(response.formatName == "jws")
        #expect(response.summary == "jws, ID: evaluation-id")
        #expect(response.expiresAt == token.expiresAt)
        #expect(response.expiresIn == 90)
        #expect(response.passed == true)
        #expect(response.detail.contains("Passed (unverified): true"))
        #expect(response.detail.contains("The backend must verify the result before allowing access."))
        #expect(
            NSDictionary(dictionary: try relay(response)).isEqual(to: [
                "format": "jws", "token": "opaque-token", "_id": "evaluation-id",
            ])
        )
    }

    @Test(arguments: [true, false])
    func jweShowsRefreshMetadataWithoutMakingAnAccessDecision(passed: Bool) throws {
        var object = trackObject(format: "jwe")
        object["passed"] = passed
        let token = try #require(RadarVerifiedLocationToken(object: object))
        let response = VerifiedResponse(token)

        #expect(response.formatName == "jwe")
        #expect(response.expiresIn == 90)
        #expect(response.passed == passed)
        #expect(response.detail.contains("Passed (unverified): \(passed)"))
        #expect(response.beaconCount == nil)
        #expect(response.beaconSummary == "beacons unavailable in jwe responses")
        #expect(
            NSDictionary(dictionary: try relay(response)).isEqual(to: [
                "format": "jwe", "token": "opaque-token", "_id": "evaluation-id",
            ])
        )
        #expect(!response.detail.contains("\"user\""))
    }

    @Test
    func idDoesNotPresentPlaceholderVerdictOrExpiration() throws {
        let token = try #require(
            RadarVerifiedLocationToken(object: [
                "format": "id", "_id": "lookup-id",
            ]))
        let response = VerifiedResponse(token)

        #expect(response.passed == nil)
        #expect(response.expiresAt == nil)
        #expect(response.expiresIn == nil)
        #expect(response.detail.contains("Expires at: unavailable"))
        #expect(response.detail.contains("Expires in: unavailable"))
        #expect(!response.detail.contains("Passed (unverified)"))
        #expect(!response.detail.contains("0.0 seconds"))
        #expect(response.beaconSummary == "beacons unavailable in id responses")
        #expect(
            NSDictionary(dictionary: try relay(response)).isEqual(to: [
                "format": "id", "_id": "lookup-id",
            ])
        )
    }

    @Test(arguments: [0, 1, 2])
    func legacyBeaconCountsRemainAvailable(count: Int) throws {
        var object = trackObject()
        var user = try #require(object["user"] as? [String: Any])
        user["beacons"] = (0..<count).map { index in
            ["_id": "beacon-\(index)", "uuid": "test-uuid", "major": "1", "minor": "2"]
        }
        object["user"] = user
        let token = try #require(RadarVerifiedLocationToken(object: object))
        let response = VerifiedResponse(token)

        #expect(response.beaconCount == count)
        #expect(response.beaconSummary == "\(count) beacons")
    }

    @Test
    func legacyTokenWithoutIDCanStillBeRelayed() throws {
        var object = trackObject()
        object["_id"] = nil
        let token = try #require(RadarVerifiedLocationToken(object: object))
        let response = VerifiedResponse(token)

        #expect(response.summary == "jws, ID: unavailable")
        #expect(
            NSDictionary(dictionary: try relay(response)).isEqual(to: [
                "format": "jws", "token": "opaque-token",
            ])
        )
    }

    @Test(arguments: ["jws", "jwe", "id"])
    func revealUsesTheSameRelayEnvelope(format: String) throws {
        var object: [String: Any] = ["format": format, "_id": "risk-id"]
        if format != "id" {
            object["token"] = "risk-token"
            object["expiresAt"] = "2030-01-01T00:00:00.000Z"
            object["expiresIn"] = 90
        }
        if format == "jws" {
            object["risk"] = ["level": "low", "reasons": []]
            object["network"] = [:] as [String: Any]
            object["device"] = [:] as [String: Any]
        }
        let data = try JSONSerialization.data(withJSONObject: object)
        let token = try #require(RadarRevealRiskToken.fromData(data))
        let response = VerifiedResponse(token)
        var expected: [String: Any] = ["format": format, "_id": "risk-id"]
        if format != "id" { expected["token"] = "risk-token" }

        #expect(NSDictionary(dictionary: try relay(response)).isEqual(to: expected))
        #expect(response.passed == nil)
        #expect(response.beaconCount == nil)
        #expect(!response.detail.contains("Passed (unverified)"))
        #expect(response.expiresIn == (format == "id" ? nil : 90))
    }

    @Test
    func relayJSONEscapesValuesAndContainsNoClientDecisionFields() throws {
        var object = trackObject(format: "jwe")
        object["token"] = "token\n\"quoted\""
        object["_id"] = "evaluation/雪"
        let token = try #require(RadarVerifiedLocationToken(object: object))
        let payload = try relay(VerifiedResponse(token))

        #expect(Set(payload.keys) == ["format", "_id", "token"])
        #expect(payload["token"] as? String == "token\n\"quoted\"")
        #expect(payload["_id"] as? String == "evaluation/雪")
    }

    @Test
    func emptyTokenHasNoRelayPayload() {
        let response = VerifiedResponse(RadarVerifiedLocationToken())

        #expect(response.relayJSON == nil)
        #expect(!response.detail.contains("Backend relay JSON"))
    }

    @Test
    func invalidRawJSONDoesNotPreventRelayingTheToken() throws {
        var object = trackObject()
        object["extra"] = Double.nan
        let token = try #require(RadarVerifiedLocationToken(object: object))
        let response = VerifiedResponse(token)

        #expect(response.detail.hasSuffix("SDK response:\nunavailable"))
        #expect(try relay(response)["token"] as? String == "opaque-token")
    }
}
