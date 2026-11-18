//
//  RadarRevealRiskTests.swift
//  RadarSDKTests
//
//  Created by ShiCheng Lu on 7/14/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

// swiftlint:disable file_length
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarRevealRiskTests {  // swiftlint:disable:this type_body_length

        private static let revealRiskURL = "\(RadarSettings.verifiedHost)/v1/reveal/risk"

        /// A fully-populated reveal/risk response mirroring the server's `RevealRiskResponse` shape.
        static var revealRiskResponse: [String: Any] {
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

        private func makeManager(
            sealResult: [String: Any]?,
            session: MockURLSession,
            hasCompatibilityMarker: Bool = true
        ) -> RadarRevealRiskManager {
            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

            let preparedInstance = MockPreparedFraudPayloadInstance(
                result: sealResult
            )
            let instance = MockCollectingFraudInstance(
                result: ["preparedPayload": preparedInstance],
                missingSelectors: hasCompatibilityMarker ? [] : ["coreCompatibilityVersion"]
            )
            let fraudSDK = RadarSDKFraud(instance: instance)
            let apiClient = RadarAPIClient(
                apiHelper: RadarAPIHelper(session: session)
            )

            return RadarRevealRiskManager(
                apiClient: apiClient,
                fraudSDK: fraudSDK
            )
        }

        @Test("revealRisk sends an encrypted body with or without a compatibility marker", arguments: [false, true])
        func revealRiskCallsFraudSDKThenAPI(hasCompatibilityMarker: Bool) async throws {
            let responseData = try #require(try? JSONSerialization.data(withJSONObject: RadarRevealRiskTests.revealRiskResponse))
            let session = MockURLSession()

            // Return a response only when the complete envelope is sent as the request body.
            session.on(
                { request in
                    guard request.url?.absoluteString == RadarRevealRiskTests.revealRiskURL,
                        request.httpMethod == "POST",
                        let body = request.httpBody,
                        let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                    else {
                        return false
                    }
                    return body == Data(MockFraudEnvelope.payload.utf8)
                        && Set(json.keys) == MockFraudEnvelope.fieldNames
                }, responseData)

            let manager = makeManager(sealResult: ["payload": MockFraudEnvelope.payload], session: session, hasCompatibilityMarker: hasCompatibilityMarker)
            let token = try await manager.revealRisk(useSecondaryVerifiedHost: false)

            // The API response was parsed into a fully-populated token.
            #expect(token.id == "risk-token-123")
            #expect(token.token == "signed-jwt-token")
            #expect(token.expiresIn == 3600)
            #expect(token.risk?.level == .medium)
            #expect(token.risk?.reasons == ["proxy_detected", "vpn_detected"])
            #expect(token.network?.ipAddress?.countryCode == "US")
            #expect(token.network?.ipAddress?.city == "New York")
            #expect(token.network?.privacy?.proxy == true)
            #expect(token.network?.privacy?.vpn == true)
            #expect(token.network?.asn?.name == "CLOUDFLARENET")
            #expect(token.device?.deviceType == "iOS")
            #expect(token.device?.installId == "install-xyz")
        }

        @Test("revealRisk surfaces the token through the completion-handler API")
        func revealRiskCompletionHandlerSucceeds() async throws {
            let session = MockURLSession()
            session.on(RadarRevealRiskTests.revealRiskURL, RadarRevealRiskTests.revealRiskResponse)

            let manager = makeManager(sealResult: ["payload": MockFraudEnvelope.payload], session: session)

            let (status, token) = await withCheckedContinuation { continuation in
                manager.revealRisk(useSecondaryVerifiedHost: false) { status, token in
                    continuation.resume(returning: (status, token))
                }
            }

            #expect(status == .success)
            #expect(token?.id == "risk-token-123")
            #expect(token?.risk?.level == .medium)
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

            let manager = makeManager(sealResult: ["payload": MockFraudEnvelope.payload], session: session)
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

            let manager = makeManager(sealResult: ["payload": MockFraudEnvelope.payload], session: session)
            let token = try await manager.revealRisk(useSecondaryVerifiedHost: false)

            #expect(token.id == "risk-token-123")
        }

        @Test("revealRisk does not call the API when sealing fails", arguments: [false, true])
        func revealRiskSkipsAPIWhenFraudFails(hasCompatibilityMarker: Bool) async throws {
            let session = MockURLSession()
            // If the manager reaches the API despite the fraud SDK failing, the handler records an issue.
            session.on(
                { _ in
                    Issue.record("reveal/risk API should not be called when the fraud SDK fails to produce a payload")
                    return false
                }, Data())

            let manager = makeManager(sealResult: ["error": "Encryption failed"], session: session, hasCompatibilityMarker: hasCompatibilityMarker)

            await #expect {
                _ = try await manager.revealRisk(useSecondaryVerifiedHost: false)
            } throws: { error in
                let radarError = error as? RadarError
                return radarError?.status == .errorBadRequest
                    && radarError?.message == "Failed to encrypt request body"
            }
        }

        @Test("revealRisk rejects missing or legacy fraud SDKs", arguments: [false, true])
        func revealRiskThrowsPluginErrorWhenFraudSDKIsUnavailable(legacy: Bool) async throws {
            let session = MockURLSession()
            // Missing encryption support must short-circuit before reaching the API.
            session.on(
                { _ in
                    Issue.record("reveal/risk API should not be called without encryption support")
                    return false
                }, Data())

            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")
            let apiClient = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))
            let fraudSDK = legacy ? RadarSDKFraud(instance: MockLegacyFraudInstance()) : nil
            #expect(fraudSDK == nil)
            let manager = RadarRevealRiskManager(apiClient: apiClient, fraudSDK: fraudSDK)

            await #expect {
                _ = try await manager.revealRisk(useSecondaryVerifiedHost: false)
            } throws: { error in
                let radarError = error as? RadarError
                return radarError?.status == .errorPlugin
                    && radarError?.message == "A compatible Radar Fraud SDK is required for verified requests."
            }
        }

        @Test(
            "revealRisk rejects unsupported Fraud compatibility versions before collection",
            arguments: [0, 2]
        )
        func revealRiskRejectsIncompatibleFraudSDK(version: Int) async throws {
            let session = RetryTestSession(failures: [])
            let instance = MockCollectingFraudInstance(
                result: nil,
                compatibilityVersion: NSNumber(value: version)
            )
            let fraudSDK = RadarSDKFraud(instance: instance)
            #expect(fraudSDK == nil)
            let manager = RadarRevealRiskManager(
                apiClient: RadarAPIClient(apiHelper: RadarAPIHelper(session: session)),
                fraudSDK: fraudSDK
            )

            await #expect {
                try await manager.revealRisk(useSecondaryVerifiedHost: false)
            } throws: { error in
                let radarError = error as? RadarError
                return radarError?.status == .errorPlugin
                    && radarError?.message == "A compatible Radar Fraud SDK is required for verified requests."
            }

            #expect(instance.recordedOptions().isEmpty)
            let requests = await session.recordedRequests()
            #expect(requests.isEmpty)
        }

        @Test("revealRisk does not call the API when collection fails")
        func revealRiskSkipsAPIWhenCollectionFails() async throws {
            Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

            let session = MockURLSession()
            session.on(
                { _ in
                    Issue.record("Collection failure must not dispatch a request")
                    return false
                },
                Data()
            )

            let instance = MockCollectingFraudInstance(
                result: ["error": "Collection failed"]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let manager = RadarRevealRiskManager(
                apiClient: RadarAPIClient(
                    apiHelper: RadarAPIHelper(session: session)
                ),
                fraudSDK: fraudSDK
            )

            await #expect {
                try await manager.revealRisk(useSecondaryVerifiedHost: false)
            } throws: { error in
                let radarError = error as? RadarError
                return radarError?.status == .errorBadRequest
                    && radarError?.message == "Failed to prepare fraud payload"
            }

            #expect(instance.recordedOptions().count == 1)
        }

        @Test(
            "Reveal preserves legacy and explicit JWS responses",
            arguments: [false, true]
        )
        func parsesJWSResponse(explicitFormat: Bool) throws {
            var response = Self.revealRiskResponse
            if explicitFormat {
                response["format"] = "jws"
            }

            let data = try JSONSerialization.data(withJSONObject: response)
            let token = try #require(RadarRevealRiskToken.fromData(data))

            #expect(token.format == .jws)
            #expect(token.risk?.level == .medium)
            #expect(token.network?.ipAddress?.countryCode == "US")
            #expect(token.device?.deviceType == "iOS")
        }

        @Test("Reveal JWE retains only its clear envelope")
        func parsesJWEResponse() throws {
            // Include plaintext fields to verify they are ignored and filtered.
            var response = Self.revealRiskResponse
            response["format"] = "jwe"
            response["token"] = "opaque-token"
            response["meta"] = ["code": 200]

            let data = try JSONSerialization.data(withJSONObject: response)
            let token = try #require(RadarRevealRiskToken.fromData(data))

            #expect(token.format == .jwe)
            #expect(token._id == "risk-token-123")
            #expect(token.token == "opaque-token")
            #expect(token.expiresAt != nil)
            #expect(token.expiresIn == 3600)
            #expect(token.risk == nil)
            #expect(token.network == nil)
            #expect(token.device == nil)
            #expect(
                Set(token.dictionaryValue().keys)
                    == Set<AnyHashable>([
                        "format", "_id", "token", "expiresAt", "expiresIn",
                    ])
            )
        }

        @Test("Reveal ID responses retain only the format and ID")
        func parsesIDResponse() throws {
            var response = Self.revealRiskResponse
            response["format"] = "id"

            let data = try JSONSerialization.data(withJSONObject: response)
            let token = try #require(RadarRevealRiskToken.fromData(data))

            #expect(token.format == .id)
            #expect(token._id == "risk-token-123")
            #expect(token.token == nil)
            #expect(token.expiresAt == nil)
            #expect(token.expiresIn == nil)
            #expect(token.risk == nil)
            #expect(token.network == nil)
            #expect(token.device == nil)
            #expect(
                Set(token.dictionaryValue().keys)
                    == Set<AnyHashable>(["format", "_id"])
            )
        }

        @Test(
            "Reveal JWE requires its clear envelope fields",
            arguments: ["_id", "token", "expiresAt", "expiresIn"]
        )
        func rejectsIncompleteJWE(missingKey: String) throws {
            var response: [String: Any] = [
                "format": "jwe",
                "_id": "risk-id",
                "token": "opaque-token",
                "expiresAt": "2030-01-01T00:00:00.000Z",
                "expiresIn": 90,
            ]
            response.removeValue(forKey: missingKey)

            let data = try JSONSerialization.data(withJSONObject: response)
            #expect(RadarRevealRiskToken.fromData(data) == nil)
        }

        @Test("Reveal rejects malformed response envelopes")
        func rejectsMalformedResponses() throws {
            let responses: [[String: Any]] = [
                ["format": "unknown", "_id": "risk-id"],
                ["format": NSNull(), "_id": "risk-id"],
                ["format": "id"],
                ["format": "id", "_id": ""],
                ["format": "id", "_id": 123],
                [
                    "format": "jwe",
                    "_id": "risk-id",
                    "token": "",
                    "expiresAt": "2030-01-01T00:00:00.000Z",
                    "expiresIn": 90,
                ],
                [
                    "format": "jwe",
                    "_id": "risk-id",
                    "token": "opaque-token",
                    "expiresAt": "invalid-date",
                    "expiresIn": 90,
                ],
            ]

            for response in responses {
                let data = try JSONSerialization.data(withJSONObject: response)
                #expect(RadarRevealRiskToken.fromData(data) == nil)
            }
        }

        @Test(
            "Reveal JWS still requires plaintext signals",
            arguments: ["risk", "network", "device"]
        )
        func rejectsIncompleteJWS(missingKey: String) throws {
            var response = Self.revealRiskResponse
            response.removeValue(forKey: missingKey)

            let data = try JSONSerialization.data(withJSONObject: response)
            #expect(RadarRevealRiskToken.fromData(data) == nil)
        }

        @Test(
            "Reveal delivers reduced responses and updates the shared Reveal ID",
            arguments: ["jwe", "id"]
        )
        func revealRiskDeliversReducedResponse(format: String) async throws {
            let responseID = "risk-\(format)-id"
            var response: [String: Any] = [
                "meta": ["code": 200],
                "format": format,
                "_id": responseID,
            ]

            if format == "jwe" {
                response["token"] = "opaque-token"
                response["expiresAt"] = "2030-01-01T00:00:00.000Z"
                response["expiresIn"] = 90
            }

            let session = MockURLSession()
            session.on(Self.revealRiskURL, response)

            let manager = makeManager(
                sealResult: ["payload": MockFraudEnvelope.payload],
                session: session
            )
            manager.revealRiskId = "previous-risk-id"

            let (status, result) = await withCheckedContinuation { continuation in
                manager.revealRisk(useSecondaryVerifiedHost: false) { status, token in
                    continuation.resume(returning: (status, token))
                }
            }

            #expect(status == .success)
            let token = try #require(result)
            #expect(token.format == (format == "jwe" ? .jwe : .id))
            #expect(token._id == responseID)
            #expect(manager.revealRiskId == responseID)
            #expect(token.risk == nil)
            #expect(token.network == nil)
            #expect(token.device == nil)

            if format == "jwe" {
                #expect(token.token == "opaque-token")
                #expect(token.expiresAt != nil)
                #expect(token.expiresIn == 90)
                #expect(
                    Set(token.dictionaryValue().keys)
                        == Set<AnyHashable>([
                            "format", "_id", "token", "expiresAt", "expiresIn",
                        ])
                )
            } else {
                #expect(token.token == nil)
                #expect(token.expiresAt == nil)
                #expect(token.expiresIn == nil)
                #expect(
                    Set(token.dictionaryValue().keys)
                        == Set<AnyHashable>(["format", "_id"])
                )
            }
        }

        @Test("Reveal reports malformed responses through the completion handler")
        func revealRiskRejectsMalformedResponses() async {
            let responses: [[String: Any]] = [
                // JWE is missing its token and expiration fields.
                ["format": "jwe", "_id": "risk-id"],
                // ID response is missing its ID.
                ["format": "id"],
                // Unknown formats must not fall back to legacy parsing.
                ["format": "unknown", "_id": "risk-id"],
            ]

            for response in responses {
                let session = MockURLSession()
                session.on(Self.revealRiskURL, response)

                let manager = makeManager(
                    sealResult: ["payload": MockFraudEnvelope.payload],
                    session: session
                )
                manager.revealRiskId = "previous-risk-id"

                let (status, token) = await withCheckedContinuation { continuation in
                    manager.revealRisk(useSecondaryVerifiedHost: false) { status, token in
                        continuation.resume(returning: (status, token))
                    }
                }

                #expect(status == .errorServer)
                #expect(token == nil)
                #expect(manager.revealRiskId == "previous-risk-id")
            }
        }
    }
}
