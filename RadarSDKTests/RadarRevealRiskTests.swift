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

extension RadarSerializedTests {
    @Suite(.serialized)
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
            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")
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
            #expect(token.risk.level == .medium)
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
            #expect(token?.risk.level == .medium)
        }

        @Test("revealRisk passes the product up in the X-Radar-Product header when it is set")
        func revealRiskSendsProductHeader() async throws {
            let originalProduct = RadarSettings.product
            RadarSettings.product = "trip-tracking"
            defer { RadarSettings.product = originalProduct }

            let responseData = try #require(try? JSONSerialization.data(withJSONObject: RadarRevealRiskTests.revealRiskResponse))
            let session = MockURLSession()

            // Only return the response (letting the call succeed and produce a token) when the request
            // carries the product in the X-Radar-Product header; otherwise the call fails.
            session.on(
                { request in
                    request.url?.absoluteString == RadarRevealRiskTests.revealRiskURL
                        && request.value(forHTTPHeaderField: "X-Radar-Product") == "trip-tracking"
                }, responseData)

            let manager = makeManager(fraudResult: ["payload": "mock-fraud-payload"], session: session)
            let token = try await manager.revealRisk(useSecondaryVerifiedHost: false)

            #expect(token.id == "risk-token-123")
        }

        @Test("revealRisk does not send the X-Radar-Product header when the product is not set")
        func revealRiskOmitsProductHeaderWhenUnset() async throws {
            let originalProduct = RadarSettings.product
            RadarSettings.product = nil
            defer { RadarSettings.product = originalProduct }

            let responseData = try #require(try? JSONSerialization.data(withJSONObject: RadarRevealRiskTests.revealRiskResponse))
            let session = MockURLSession()

            session.on(
                { request in
                    request.url?.absoluteString == RadarRevealRiskTests.revealRiskURL
                        && request.value(forHTTPHeaderField: "X-Radar-Product") == nil
                }, responseData)

            let manager = makeManager(fraudResult: ["payload": "mock-fraud-payload"], session: session)
            let token = try await manager.revealRisk(useSecondaryVerifiedHost: false)

            #expect(token.id == "risk-token-123")
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

        @Test("revealRisk throws .errorPlugin when the fraud SDK is not available")
        func revealRiskThrowsPluginErrorWhenFraudSDKIsNil() async throws {
            let session = MockURLSession()
            // Without a fraud SDK the manager should short-circuit before ever reaching the API.
            session.on(
                { _ in
                    Issue.record("reveal/risk API should not be called when the fraud SDK is nil")
                    return false
                }, Data())

            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")
            let apiClient = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))
            let manager = RadarRevealRiskManager(apiClient: apiClient, fraudSDK: nil)

            await #expect {
                _ = try await manager.revealRisk(useSecondaryVerifiedHost: false)
            } throws: { error in
                (error as? RadarError)?.status == .errorPlugin
            }
        }

        @Test("Reveal retry requests fresh encryption with outgoing request context")
        func revealRetryRefreshesEncryptionContext() async throws {
            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

            let responseData = try JSONSerialization.data(
                withJSONObject: Self.revealRiskResponse
            )
            let session = RetryTestSession(
                failures: [.networkConnectionLost],
                responseData: responseData
            )
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "mock-encrypted-envelope"]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let manager = RadarRevealRiskManager(
                apiClient: RadarAPIClient(
                    apiHelper: RadarAPIHelper(session: session)
                ),
                fraudSDK: fraudSDK
            )

            let startedAt = Int(Date().timeIntervalSince1970)
            let token = try await manager.revealRisk(
                useSecondaryVerifiedHost: true
            )
            let finishedAt = Int(Date().timeIntervalSince1970)

            #expect(token.id == "risk-token-123")

            let options = instance.recordedOptions()
            let requests = await session.recordedRequests()
            #expect(options.count == 2)
            #expect(requests.count == 2)
            guard options.count == 2, requests.count == 2 else { return }

            let firstId = try #require(options[0]["encryptionAttemptId"] as? String)
            let retryId = try #require(options[1]["encryptionAttemptId"] as? String)
            #expect(!firstId.isEmpty)
            #expect(firstId != retryId)

            try assertRetryContexts(options: options, requests: requests, issuedBetween: startedAt...finishedAt)

        }

        private func assertRetryContexts(
            options: [[String: Any]], requests: [URLRequest], issuedBetween: ClosedRange<Int>
        ) throws {
            for index in requests.indices {
                let request = requests[index]
                let context = options[index]
                let bodyData = try #require(request.httpBody)
                let body = try #require(
                    try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
                )

                #expect(
                    request.url?.absoluteString == "\(RadarSettings.defaultVerifiedHostSecondary)/v1/reveal/risk"
                )
                #expect(request.httpMethod == "POST")
                #expect(context["method"] as? String == request.httpMethod)
                #expect(context["canonicalRoute"] as? String == "/v1/reveal/risk")
                #expect(context["environment"] as? String == "production")
                #expect(context["installId"] as? String == body["installId"] as? String)
                #expect(body["fraudPayload"] as? String == "mock-encrypted-envelope")

                let fields = [
                    ("origin", "Origin"),
                    ("product", "X-Radar-Product"),
                    ("sdkVersion", "X-Radar-SDK-Version"),
                    ("authorization", "Authorization"),
                ]

                for (optionName, headerName) in fields {
                    #expect(
                        context[optionName] as? String == request.value(forHTTPHeaderField: headerName)
                    )
                }

                let issuedAt = try #require(context["issuedAt"] as? Int)
                #expect(issuedAt >= issuedBetween.lowerBound)
                #expect(issuedAt <= issuedBetween.upperBound)
            }
        }

    }
}
