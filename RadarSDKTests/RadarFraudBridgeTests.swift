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
        }

        @Test("Core rejects an older fraud SDK without encryption support")
        func initializerRejectsLegacyFraudSDK() {
            let fraudSDK = RadarSDKFraud(
                instance: MockLegacyFraudInstance()
            )

            #expect(fraudSDK == nil)
        }

        @Test(
            "Body preparation supports both canonical routes without an environment",
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

            let body = try await preparer.prepareBody(
                ["installId": "test-install"],
                method: "POST",
                canonicalRoute: route,
                headers: [:]
            )

            let contexts = instance.recordedOptions()
            #expect(contexts.count == 1)
            let context = try #require(contexts.first)
            #expect(context["environment"] == nil)
            #expect(context["canonicalRoute"] as? String == route)
            #expect(context["method"] as? String == "POST")
            #expect(body["installId"] as? String == "test-install")
            #expect(body["fraudPayload"] as? String == "encrypted-envelope")
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

        @Test("Fraud body preparation preserves fields and forwards request context")
        func encryptedBodyPreservesFieldsAndContext() async throws {
            let instance = MockEncryptedFraudInstance(
                result: ["payload": "encrypted-envelope"]
            )
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            let preparer = RadarFraudPayloadPreparer(
                fraudSDK: fraudSDK,
                options: ["collectionOption": true]
            )
            let body: [String: Any] = [
                "installId": "test-install",
                "verified": true,
            ]

            let result = try await preparer.prepareBody(
                body,
                method: "POST",
                canonicalRoute: "/v1/track",
                headers: [
                    "authorization": "test-publishable-key",
                    "X-Radar-SDK-Version": "test-version",
                ]
            )

            #expect(result["fraudPayload"] as? String == "encrypted-envelope")
            #expect(result["installId"] as? String == "test-install")
            #expect(result["verified"] as? Bool == true)
            #expect(body["fraudPayload"] == nil)

            let calls = instance.recordedOptions()
            #expect(calls.count == 1)
            let context = try #require(calls.first)
            #expect(context["method"] as? String == "POST")
            #expect(context["canonicalRoute"] as? String == "/v1/track")
            #expect(context["authorization"] as? String == "test-publishable-key")
            #expect(context["sdkVersion"] as? String == "test-version")
            #expect(context["collectionOption"] as? Bool == true)
            #expect(context["encryptionAttemptId"] is String)
            #expect(context["issuedAt"] is Int)
        }
    }
}
