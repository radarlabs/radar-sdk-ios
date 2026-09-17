import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarTrackRequestPreparationTests {
        @Test(
            "Tracking payload collection preserves success and failure statuses",
            arguments: [
                "success",
                "missing-module",
                "legacy-module",
                "payload-error",
                "empty-payload",
                "missing-result",
                "empty-result",
                "numeric-payload",
                "null-payload",
                "payload-and-error",
            ]
        )
        func trackingPayloadBridge(scenario: String) async throws {
            let (fraudSDK, expectedStatus) = try makeFraudSDK(scenario: scenario)
            let preparer = RadarTrackVerifiedRequestPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            #expect(
                preparer.responds(
                    to: NSSelectorFromString(
                        "getEncryptedPayloadWithInstallId:origin:product:sdkVersion:authorization:completionHandler:"
                    )
                )
            )

            let (status, payload, error) = await preparer.getEncryptedPayload(
                installId: "test-install",
                origin: nil,
                product: nil,
                sdkVersion: "test-version",
                authorization: "test-key"
            )

            #expect(status == expectedStatus)

            if scenario == "success" {
                #expect(error == nil)
                #expect(payload == "encrypted-envelope")
            } else {
                #expect(payload == nil)
                if scenario == "missing-module" || scenario == "legacy-module" {
                    #expect(error == nil)
                } else {
                    #expect(error != nil)
                }
            }
        }

        private func makeFraudSDK(scenario: String) throws -> (RadarSDKFraud?, RadarStatus) {
            let fraudSDK: RadarSDKFraud?
            let expectedStatus: RadarStatus

            switch scenario {
            case "missing-module":
                fraudSDK = nil
                expectedStatus = .errorPlugin

            case "legacy-module":
                fraudSDK = RadarSDKFraud(
                    instance: MockLegacyFraudInstance()
                )
                #expect(fraudSDK == nil)
                expectedStatus = .errorPlugin
            default:
                let result = fraudResult(scenario: scenario)
                let candidate: RadarSDKFraud? = RadarSDKFraud(
                    instance: MockEncryptedFraudInstance(result: result)
                )
                let validatedSDK: RadarSDKFraud = try #require(candidate)
                fraudSDK = validatedSDK
                expectedStatus = scenario == "success" ? .success : .errorUnknown
            }

            return (fraudSDK, expectedStatus)
        }

        private func fraudResult(scenario: String) -> [String: Any]? {
            switch scenario {
            case "success": return ["payload": "encrypted-envelope"]
            case "payload-error": return ["error": "encryption failed"]
            case "empty-payload": return ["payload": ""]
            case "missing-result": return nil
            case "empty-result": return [:]
            case "numeric-payload": return ["payload": 123]
            case "null-payload": return ["payload": NSNull()]
            case "payload-and-error":
                return ["error": "encryption failed", "payload": "must-not-send"]
            default:
                Issue.record("Unknown preparation scenario: \(scenario)")
                return nil
            }
        }
    }
}
