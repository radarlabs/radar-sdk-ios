import Foundation
import Testing

@testable import RadarSDK

private struct PreparationResult: Sendable {
    let status: RadarStatus
    let request: URLRequest?
    let error: NSError?
}

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarTrackRequestPreparationTests {
        @Test(
            "Tracking preparation bridges success and fraud SDK failures",
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
        func trackingPreparationBridge(scenario: String) async throws {
            let (fraudSDK, expectedStatus) = try makeFraudSDK(scenario: scenario)

            let preparer = RadarTrackVerifiedRequestPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            #expect(
                preparer.responds(
                    to: NSSelectorFromString("prepareRequest:completionHandler:")
                )
            )

            var request = URLRequest(
                url: try #require(
                    URL(string: "https://api-verified.radar.io/v1/track")
                )
            )
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(
                withJSONObject: [
                    "installId": "test-install",
                    "latitude": 47.0,
                ]
            )

            let result: PreparationResult = await withCheckedContinuation { continuation in
                preparer.prepareRequest(request) { status, request, error in
                    continuation.resume(returning: PreparationResult(status: status, request: request, error: error))
                }
            }
            let status = result.status
            let preparedRequest = result.request
            let error = result.error

            #expect(status == expectedStatus)

            if scenario == "success" {
                #expect(error == nil)

                let preparedRequest = try #require(preparedRequest)
                #expect(preparedRequest.url == request.url)
                #expect(preparedRequest.httpMethod == "POST")

                let bodyData = try #require(preparedRequest.httpBody)
                let bodyObject = try JSONSerialization.jsonObject(with: bodyData)
                let body = try #require(bodyObject as? [String: Any])

                #expect(body["fraudPayload"] as? String == "encrypted-envelope")
                #expect(body["installId"] as? String == "test-install")
                #expect(body["latitude"] as? Double == 47.0)
            } else {
                #expect(preparedRequest == nil)

                if scenario != "missing-module" {
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
                fraudSDK = try #require(
                    RadarSDKFraud(instance: MockLegacyFraudInstance())
                )
                expectedStatus = .errorPlugin

            default:
                let result = fraudResult(scenario: scenario)
                fraudSDK = try #require(
                    RadarSDKFraud(instance: MockEncryptedFraudInstance(result: result))
                )
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
