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

        @Test("Core tolerates an older fraud SDK without encryption support")
        func encryptedFraudPayloadHandlesMissingSelector() async throws {
            let instance = MockLegacyFraudInstance()
            let fraudSDK = try #require(RadarSDKFraud(instance: instance))

            let (status, payload) = await fraudSDK.getEncryptedFraudPayload(
                options: [:]
            )

            #expect(status == .errorPlugin)
            #expect(payload == nil)
        }

        @Test("Fraud encryption environment matches the configured host")
        func encryptionEnvironmentMatchesHost() {
            let productionHosts = [
                "https://api.radar.io",
                "https://api-verified.radar.io",
                "https://api-verified.radar.com",
            ]

            let stagingHosts = [
                "https://api.radar-staging.com",
                "https://api-verified.radar-staging.io",
            ]

            for host in productionHosts {
                #expect(
                    RadarSDKFraud.encryptionEnvironment(forHost: host)
                        == "production"
                )
            }

            for host in stagingHosts {
                #expect(
                    RadarSDKFraud.encryptionEnvironment(forHost: host)
                        == "staging"
                )
            }

            #expect(
                RadarSDKFraud.encryptionEnvironment(
                    forHost: "https://custom.example.com"
                ) == nil
            )
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
    }
}
