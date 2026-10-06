import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarFraudBridgeTests {
        @Test("Core rejects an older fraud SDK during initialization")
        func initializationRejectsLegacyFraudSDK() {
            let instance = MockLegacyFraudInstance()

            #expect(RadarSDKFraud(instance: instance) == nil)
            #expect(instance.recordedPlaintextCalls() == 0)
        }

        @Test("Swift verification safely handles a rejected fraud SDK")
        func verificationHandlesRejectedFraudSDK() {
            let instance = MockLegacyFraudInstance()
            let fraudSDK = RadarSDKFraud(instance: instance)
            #expect(fraudSDK == nil)

            let manager = RadarSDK.RadarVerificationManager(
                apiClient: RadarAPIClient.shared,
                fraudSDK: fraudSDK,
                locationManagerHost: nil,
                verificationmanagerHost: nil
            )

            #expect(manager.isSharing() == false)
            manager.clearSharing()

            // The rejected library wasn't called to clear its sharing state.
            #expect(instance.isSharing())
        }

        @Test(
            "Core rejects a fraud SDK missing any required selector",
            arguments: [
                "initializeWithOptions:",
                "prepareFraudPayloadWithOptions:completionHandler:",
                "isSharing",
                "clearSharing",
            ]
        )
        func initializationRejectsMissingSelector(missingSelector: String) {
            let instance = MockCollectingFraudInstance(
                result: ["payload": "encrypted-payload"],
                missingSelectors: [missingSelector]
            )

            #expect(RadarSDKFraud(instance: instance) == nil)
            #expect(instance.recordedOptions().isEmpty)
        }

        @Test("Encryption attempt IDs are random 128-bit Base64URL values")
        func encryptionAttemptIdHasExpectedFormat() throws {
            let first = try RadarPreparedFraudPayload.makeFraudEncryptionAttemptId()
            let second = try RadarPreparedFraudPayload.makeFraudEncryptionAttemptId()

            #expect(first != second)
            #expect(!first.isEmpty)
            #expect(!second.isEmpty)

            let allowedCharacters = CharacterSet(
                charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
            )

            #expect(
                first.unicodeScalars.allSatisfy {
                    allowedCharacters.contains($0)
                }
            )

            #expect(
                second.unicodeScalars.allSatisfy {
                    allowedCharacters.contains($0)
                }
            )

            func decodeBase64URL(_ value: String) -> Data? {
                var base64 =
                    value
                    .replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")

                while base64.count % 4 != 0 {
                    base64.append("=")
                }

                return Data(base64Encoded: base64)
            }

            #expect(decodeBase64URL(first)?.count == 16)
            #expect(decodeBase64URL(second)?.count == 16)
        }

        @Test("Core rejects an instance without the fraud SDK selectors")
        func rejectsUnsupportedFraudInstance() {
            #expect(RadarSDKFraud(instance: NSObject()) == nil)
        }

        @Test("Prepared payload forwards each seal through Objective-C")
        func preparedPayloadForwardsEachSeal() throws {
            let instance = MockPreparedFraudPayloadInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let prepared = try #require(
                RadarPreparedFraudPayload(instance: instance)
            )

            for attemptId in ["first", "second"] {
                let payload = try prepared.seal(
                    options: ["encryptionAttemptId": attemptId]
                )
                #expect(payload == "encrypted-envelope")
            }

            #expect(
                instance.capturedOptions.map {
                    $0["encryptionAttemptId"] as? String
                } == ["first", "second"]
            )
        }

        @Test("Prepared payload rejects an object without sealing support")
        func preparedPayloadRejectsMissingSelector() {
            #expect(RadarPreparedFraudPayload(instance: NSObject()) == nil)
        }

        @Test("Prepared payload rejects failed or malformed sealing results")
        func preparedPayloadRejectsInvalidResults() throws {
            let results: [[String: Any]?] = [
                nil,
                [:],
                ["error": "Encryption failed"],
                ["payload": ""],
                ["payload": 123],
                ["error": "Encryption failed", "payload": "old-envelope"],
            ]

            for result in results {
                let prepared = try #require(
                    RadarPreparedFraudPayload(
                        instance: MockPreparedFraudPayloadInstance(result: result)
                    )
                )

                #expect(throws: RadarError.self) {
                    try prepared.seal(options: [:])
                }
            }
        }

        @Test("Core collects once and seals the returned object twice")
        func collectionReturnsReusablePreparedPayload() async throws {
            let preparedInstance = MockPreparedFraudPayloadInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let instance = MockCollectingFraudInstance(
                result: ["preparedPayload": preparedInstance]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))

            let prepared = try await fraudSDK.prepareFraudPayload(
                options: ["nonce": "test-nonce"]
            )

            #expect(fraudSDK.isSharing() == false)
            fraudSDK.clearSharing()

            // Collection must not seal anything.
            #expect(preparedInstance.capturedOptions.isEmpty)

            for attemptId in ["first", "second"] {
                let payload = try prepared.seal(
                    options: ["encryptionAttemptId": attemptId]
                )
                #expect(payload == "encrypted-envelope")
            }

            let collectionOptions = instance.recordedOptions()
            #expect(collectionOptions.count == 1)
            #expect(collectionOptions.first?["nonce"] as? String == "test-nonce")
            #expect(
                preparedInstance.capturedOptions.map {
                    $0["encryptionAttemptId"] as? String
                } == ["first", "second"]
            )
        }

        @Test("Core rejects failed or malformed collection results")
        func collectionRejectsInvalidResults() async throws {
            let preparedInstance = MockPreparedFraudPayloadInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let results: [[String: Any]?] = [
                nil,
                [:],
                ["error": "Collection failed"],
                ["preparedPayload": "not-an-object"],
                ["preparedPayload": NSObject()],
                ["error": "Collection failed", "preparedPayload": preparedInstance],
            ]

            for result in results {
                let instance = MockCollectingFraudInstance(result: result)
                let fraudSDK = try #require(RadarSDKFraud(instance: instance))

                await #expect(throws: RadarError.self) {
                    try await fraudSDK.prepareFraudPayload(options: [:])
                }

                #expect(instance.recordedOptions().count == 1)
            }

            #expect(preparedInstance.capturedOptions.isEmpty)
        }

        @Test(
            "Prepared payload generates fresh attempt context for each seal",
            arguments: ["/v1/track", "/v1/reveal/risk"]
        )
        func preparedPayloadGeneratesFreshContext(route: String) throws {
            let instance = MockPreparedFraudPayloadInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let prepared = try #require(
                RadarPreparedFraudPayload(instance: instance)
            )

            let coreBody = Data(#"{"installId":"test-install","metadata":{"enabled":true}}"#.utf8)
            for _ in 0..<2 {
                let before = Int(Date().timeIntervalSince1970)
                let payload = try prepared.getEncryptedPayload(
                    coreBody: coreBody,
                    canonicalRoute: route,
                    origin: "https://example.test",
                    product: "test-product",
                    sdkVersion: "test-version",
                    authorization: "test-key"
                )
                let after = Int(Date().timeIntervalSince1970)

                #expect(payload == "encrypted-envelope")

                let options = try #require(instance.capturedOptions.last)
                let issuedAt = try #require(options["issuedAt"] as? Int)
                #expect(issuedAt >= before)
                #expect(issuedAt <= after)
                #expect(options["method"] as? String == "POST")
                #expect(options["canonicalRoute"] as? String == route)
                #expect(options["body"] as? Data == coreBody)
                #expect(options["installId"] == nil)
                #expect(options["origin"] as? String == "https://example.test")
                #expect(options["product"] as? String == "test-product")
                #expect(options["sdkVersion"] as? String == "test-version")
                #expect(options["authorization"] as? String == "test-key")
            }

            #expect(instance.capturedOptions.count == 2)

            let firstId = try #require(
                instance.capturedOptions[0]["encryptionAttemptId"] as? String
            )
            let secondId = try #require(
                instance.capturedOptions[1]["encryptionAttemptId"] as? String
            )
            #expect(firstId.count == 22)
            #expect(secondId.count == 22)
            #expect(firstId != secondId)
        }
    }
}

extension RadarSerializedTests.RadarFraudBridgeTests {
    @Test(
        "Request preparation sends only the envelope and preserves the original request",
        arguments: ["/v1/track", "/v1/reveal/risk"]
    )
    func requestPreparationReplacesEntireBody(route: String) throws {
        let instance = MockPreparedFraudPayloadInstance(result: nil) {
            MockFraudEnvelope.result(for: $0)
        }
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
        let coreBody = Data(
            #"{ "installId": "test-install", "latitude": 47.6, "metadata": {"enabled":false,"optional":null}, "tags":["one","two"] }"#.utf8
        )
        var request = URLRequest(url: try #require(URL(string: "https://example.test\(route)")))
        request.httpMethod = "POST"
        request.httpBody = coreBody
        request.timeoutInterval = 17
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.allHTTPHeaderFields = [
            "Authorization": "test-key", "X-Radar-Mobile-Origin": "test-origin",
            "X-Radar-Product": "test-product", "X-Radar-SDK-Version": "test-version",
            "X-Radar-Device-Type": "iOS", "Content-Type": "application/json",
        ]

        for _ in 0..<2 {
            let sent = try prepared.prepareRequest(request)
            let options = try #require(instance.capturedOptions.last)
            let payload = try #require(MockFraudEnvelope.result(for: options)["payload"] as? String)
            var expected = request
            expected.httpBody = Data(payload.utf8)
            #expect(sent == expected)
            #expect(request.httpBody == coreBody)
            #expect(options["body"] as? Data == coreBody)
            #expect(options["canonicalRoute"] as? String == route)
            #expect(options["installId"] == nil)
            for (field, header) in [
                ("authorization", "Authorization"), ("origin", "X-Radar-Mobile-Origin"),
                ("product", "X-Radar-Product"), ("sdkVersion", "X-Radar-SDK-Version"),
            ] {
                #expect(options[field] as? String == request.value(forHTTPHeaderField: header))
            }
            let bodyData = try #require(sent.httpBody)
            let body = try #require(
                try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            )
            #expect(Set(body.keys) == MockFraudEnvelope.fieldNames)
        }
        #expect(instance.capturedOptions.count == 2)
        #expect(
            instance.capturedOptions[0]["encryptionAttemptId"] as? String
                != instance.capturedOptions[1]["encryptionAttemptId"] as? String
        )
    }

    @Test("Request preparation rejects a missing URL, missing body, or non-POST method before sealing")
    func requestPreparationRejectsMissingInputs() throws {
        let instance = MockPreparedFraudPayloadInstance(result: ["payload": MockFraudEnvelope.payload])
        let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
        var request = URLRequest(url: try #require(URL(string: "https://example.test/v1/track")))
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        var noURL = request
        noURL.url = nil
        var noBody = request
        noBody.httpBody = nil
        var get = request
        get.httpMethod = "GET"

        for invalid in [noURL, noBody, get] {
            #expect(throws: RadarError.self) {
                try prepared.prepareRequest(invalid)
            }
        }
        #expect(instance.capturedOptions.isEmpty)
    }

    @Test("Request preparation propagates sealing failures without returning a plaintext request")
    func requestPreparationPropagatesFailure() throws {
        let results: [[String: Any]?] = [nil, [:], ["error": "Seal failed"], ["payload": ""]]
        var request = URLRequest(url: try #require(URL(string: "https://example.test/v1/track")))
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"installId":"test-install"}"#.utf8)
        for result in results {
            let instance = MockPreparedFraudPayloadInstance(result: result)
            let prepared = try #require(RadarPreparedFraudPayload(instance: instance))
            #expect(throws: RadarError.self) {
                try prepared.prepareRequest(request)
            }
            #expect(instance.capturedOptions.count == 1)
            #expect(instance.capturedOptions.first?["body"] as? Data == request.httpBody)
        }
    }
}
