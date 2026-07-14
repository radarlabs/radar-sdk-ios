//
//  RadarRevealRiskTests.swift
//  RadarSDKTests
//
//  Created by ShiCheng Lu on 7/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

/// A stand-in for the `RadarSDKFraud` submodule's shared instance.
///
/// `RadarSDKFraud` (the Swift wrapper) reaches into its wrapped `NSObject` via
/// `perform(...)`, so a mock only needs to be an `NSObject` that responds to the
/// `initializeWithOptions:` and `getFraudPayloadWithOptions:completionHandler:` selectors. It
/// replays a canned result dictionary so tests control what payload the manager forwards to the API.
final class MockFraudInstance: NSObject, @unchecked Sendable {
    let result: [String: Any]?

    init(result: [String: Any]?) {
        self.result = result
    }

    @objc(initializeWithOptions:)
    func initialize(options: [String: Any]) {}

    @objc(getFraudPayloadWithOptions:completionHandler:)
    func getFraudPayload(options: [String: Any], completionHandler: @escaping ([String: Any]?) -> Void) {
        completionHandler(result)
    }
}

struct RadarRevealRiskTests {

    private static let revealRiskURL = "\(RadarSettings.verifiedHost)/v1/reveal/risk"

    /// A fully-populated reveal/risk response mirroring the server's `RevealRiskResponse` shape.
    private static var revealRiskResponse: [String: Any] {
        [
            "_id": "risk-token-123",
            "token": "signed-jwt-token",
            "expiresAt": "2026-07-14T12:00:00.000Z",
            "expiresIn": 3600,
            "risk": [
                "level": "medium",
                "reasons": ["proxy_detected", "vpn_detected"],
            ],
            "network": [
                "ipAddress": [
                    "countryCode": "US",
                    "country": "United States",
                    "city": "New York",
                    "stateCode": "NY",
                    "postalCode": "10001",
                    "connectionType": "wifi",
                    "countryAllowed": true,
                    "stateAllowed": true,
                ],
                "privacy": [
                    "hosting": false,
                    "proxy": true,
                    "relay": false,
                    "service": "SomeVPN",
                    "tor": false,
                    "vpn": true,
                    "residentialProxy": false,
                ],
                "asn": [
                    "asn": "AS13335",
                    "country": "US",
                    "domain": "cloudflare.com",
                    "name": "CLOUDFLARENET",
                    "network": "104.16.0.0/12",
                    "type": "hosting",
                ],
            ],
            "device": [
                "deviceId": "device-abc",
                "deviceType": "iOS",
                "deviceMake": "Apple",
                "deviceModel": "iPhone17,1",
                "deviceOSName": "iOS",
                "deviceOSVersion": "26.2",
                "sdkVersion": "3.0.0",
                "installId": "install-xyz",
                "appId": "com.radar.example",
                "appName": "Example",
                "appVersion": "1.2.3",
                "appBuild": "42",
            ],
        ]
    }

    private func makeManager(fraudResult: [String: Any]?, session: MockURLSession) -> RadarRevealRiskManager {
        RadarSettings.publishableKey = "test-key"
        let apiClient = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))
        let fraudSDK = RadarSDKFraud(instance: MockFraudInstance(result: fraudResult))
        return RadarRevealRiskManager(apiClient: apiClient, fraudSDK: fraudSDK)
    }

    @Test("revealRisk gets a payload from the fraud SDK then reveals risk through the API")
    func revealRiskCallsFraudSDKThenAPI() async throws {
        let responseData = try #require(try? JSONSerialization.data(withJSONObject: RadarRevealRiskTests.revealRiskResponse))
        let session = MockURLSession()

        // The handler both matches the reveal/risk endpoint and verifies the params the manager sent,
        // proving the fraud SDK's payload was forwarded to the API. It only returns the response
        // (letting the call succeed) when the request looks right; otherwise the call fails and the
        // token is never produced.
        session.on(
            { request in
                guard request.url?.absoluteString == RadarRevealRiskTests.revealRiskURL,
                    request.httpMethod == "POST",
                    let body = request.httpBody,
                    let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                else {
                    return false
                }
                return json["fraudPayload"] as? String == "mock-fraud-payload"
            }, responseData)

        let manager = makeManager(fraudResult: ["payload": "mock-fraud-payload"], session: session)
        let token = try await manager.revealRisk(useSecondaryVerifiedHost: false)

        // The API response was parsed into a fully-populated token.
        #expect(token.id == "risk-token-123")
        #expect(token.token == "signed-jwt-token")
        #expect(token.expiresIn == 3600)
        #expect(token.risk.level == "medium")
        #expect(token.risk.reasons == ["proxy_detected", "vpn_detected"])
        #expect(token.network.ipAddress?.countryCode == "US")
        #expect(token.network.ipAddress?.city == "New York")
        #expect(token.network.privacy?.proxy == true)
        #expect(token.network.privacy?.vpn == true)
        #expect(token.network.asn?.name == "CLOUDFLARENET")
        #expect(token.device.deviceType == "iOS")
        #expect(token.device.installId == "install-xyz")
    }

    @Test("revealRisk surfaces the token through the completion-handler API")
    func revealRiskCompletionHandlerSucceeds() async throws {
        let session = MockURLSession()
        session.on(RadarRevealRiskTests.revealRiskURL, RadarRevealRiskTests.revealRiskResponse)

        let manager = makeManager(fraudResult: ["payload": "mock-fraud-payload"], session: session)

        let (status, token) = await withCheckedContinuation { continuation in
            manager.revealRisk(useSecondaryVerifiedHost: false) { status, token in
                continuation.resume(returning: (status, token))
            }
        }

        #expect(status == .success)
        #expect(token?.id == "risk-token-123")
        #expect(token?.risk.level == "medium")
    }

    @Test("revealRisk does not call the API when the fraud SDK returns an error")
    func revealRiskSkipsAPIWhenFraudFails() async throws {
        let session = MockURLSession()
        // If the manager reaches the API despite the fraud SDK failing, the handler records an issue.
        session.on(
            { _ in
                Issue.record("reveal/risk API should not be called when the fraud SDK fails to produce a payload")
                return false
            }, Data())

        let manager = makeManager(fraudResult: ["error": "no-payload"], session: session)

        await #expect(throws: RadarError.self) {
            _ = try await manager.revealRisk(useSecondaryVerifiedHost: false)
        }
    }
}
