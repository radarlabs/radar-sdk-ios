import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarFraudBridgeTests {
        @Test("Core forwards the encrypted fraud selector")
        func encryptedFraudPayloadForwardsToFraudSDK() async throws {
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "encrypted-payload"]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))

            let (status, payload) = await fraudSDK.getEncryptedFraudPayload(
                options: [:]
            )

            #expect(status == .success)
            #expect(payload == "encrypted-payload")
            #expect(fraudSDK.isSharing() == false)
            fraudSDK.clearSharing()
        }

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
                "getEncryptedFraudPayloadWithOptions:completionHandler:",
                "isSharing",
                "clearSharing",
            ]
        )
        func initializationRejectsMissingSelector(missingSelector: String) {
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "encrypted-payload"],
                missingSelectors: [missingSelector]
            )

            #expect(RadarSDKFraud(instance: instance) == nil)
            #expect(instance.recordedOptions().isEmpty)
        }

        @Test(
            "Encrypted payload collection supports both canonical routes without an environment",
            arguments: ["/v1/track", "/v1/reveal/risk"]
        )
        func preparationDoesNotSelectEnvironment(route: String) async throws {
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let fraudSDK: RadarSDKFraud = try #require(
                RadarSDKFraud(instance: instance)
            )
            let preparer = RadarFraudPayloadPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            let payload = try await preparer.getEncryptedPayload(
                installId: "test-install",
                canonicalRoute: route,
                sdkVersion: "test-version",
                authorization: "test-key"
            )

            let contexts = instance.recordedOptions()
            #expect(contexts.count == 1)
            let context = try #require(contexts.first)
            #expect(context["environment"] == nil)
            #expect(context["canonicalRoute"] as? String == route)
            #expect(context["method"] as? String == "POST")
            #expect(context["installId"] as? String == "test-install")
            #expect(payload == "encrypted-envelope")
        }

        @Test("Encryption attempt IDs are random 128-bit Base64URL values")
        func encryptionAttemptIdHasExpectedFormat() throws {
            let first = try RadarUtils.makeFraudEncryptionAttemptId()
            let second = try RadarUtils.makeFraudEncryptionAttemptId()

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

        @Test("Encrypted payload collection forwards explicit request context")
        func encryptedPayloadForwardsContext() async throws {
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let preparer = RadarFraudPayloadPreparer(
                fraudSDK: fraudSDK,
                options: ["collectionOption": true]
            )

            let payload = try await preparer.getEncryptedPayload(
                installId: "test-install",
                canonicalRoute: "/v1/track",
                origin: "https://example.test",
                product: "test-product",
                sdkVersion: "test-version",
                authorization: "test-publishable-key"
            )

            #expect(payload == "encrypted-envelope")

            let calls = instance.recordedOptions()
            #expect(calls.count == 1)
            let context = try #require(calls.first)
            #expect(context["method"] as? String == "POST")
            #expect(context["canonicalRoute"] as? String == "/v1/track")
            #expect(context["installId"] as? String == "test-install")
            #expect(context["origin"] as? String == "https://example.test")
            #expect(context["product"] as? String == "test-product")
            #expect(context["authorization"] as? String == "test-publishable-key")
            #expect(context["sdkVersion"] as? String == "test-version")
            #expect(context["collectionOption"] as? Bool == true)
            #expect(context["encryptionAttemptId"] is String)
            #expect(context["issuedAt"] is Int)
        }
    }
}
