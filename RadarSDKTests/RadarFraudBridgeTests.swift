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

            for _ in 0..<2 {
                let before = Int(Date().timeIntervalSince1970)
                let payload = try prepared.getEncryptedPayload(
                    installId: "test-install",
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
                #expect(options["installId"] as? String == "test-install")
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
