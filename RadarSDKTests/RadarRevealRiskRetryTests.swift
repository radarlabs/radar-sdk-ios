import Foundation
import Testing

@testable import RadarSDK

// Keep retry tests in the same serialized suite as the other revealRisk tests.
extension RadarSerializedTests.RadarRevealRiskTests {
    @Test("Reveal retry reseals the collected payload and authenticated context")
    func revealRetryResealsCollectedPayload() async throws {
        Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

        let responseData = try JSONSerialization.data(
            withJSONObject: Self.revealRiskResponse
        )
        let session = RetryTestSession(
            failures: [.networkConnectionLost],
            responseData: responseData
        )
        let preparedInstance = MockPreparedFraudPayloadInstance(
            result: nil,
            resultForOptions: { options in
                MockFraudEnvelope.result(for: options)
            }
        )
        let instance = MockCollectingFraudInstance(
            result: ["preparedPayload": preparedInstance]
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

        let options = preparedInstance.capturedOptions
        let requests = await session.recordedRequests()

        #expect(instance.recordedOptions().count == 1)
        try assertRetryRequests(
            contexts: options,
            requests: requests,
            issuedBetween: startedAt...finishedAt
        )
    }

    private func assertRetryRequests(
        contexts options: [[String: Any]],
        requests: [URLRequest],
        issuedBetween: ClosedRange<Int>
    ) throws {
        #expect(options.count == 2)
        #expect(requests.count == 2)
        guard options.count == 2, requests.count == 2 else { return }

        let firstId = try #require(options[0]["encryptionAttemptId"] as? String)
        let secondId = try #require(options[1]["encryptionAttemptId"] as? String)
        #expect(firstId != secondId)
        #expect(requests[0].httpBody != requests[1].httpBody)
        #expect(requests[0].url == requests[1].url)
        #expect(requests[0].allHTTPHeaderFields == requests[1].allHTTPHeaderFields)
        let coreBody = try #require(options[0]["body"] as? Data)
        #expect(options[1]["body"] as? Data == coreBody)

        for index in options.indices {
            try assertRetryContexts(
                context: options[index],
                requests: [requests[index]],
                issuedBetween: issuedBetween
            )
        }
    }

    private func assertRetryContexts(
        context: [String: Any],
        requests: [URLRequest],
        issuedBetween: ClosedRange<Int>
    ) throws {
        for request in requests {
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
            #expect(context["environment"] == nil)
            #expect(context["installId"] == nil)
            let coreData = try #require(context["body"] as? Data)
            let coreBody = try #require(
                try JSONSerialization.jsonObject(with: coreData) as? [String: Any]
            )
            #expect(coreBody["installId"] is String)
            #expect(coreBody["fraudPayload"] == nil)
            let attemptId = try #require(context["encryptionAttemptId"] as? String)
            #expect(Set(body.keys) == MockFraudEnvelope.fieldNames)
            #expect(body["encryptionAttemptId"] as? String == attemptId)
            #expect(body["issuedAt"] as? Int == context["issuedAt"] as? Int)
            #expect(body["ct"] as? String == "encrypted-\(attemptId)")

            let fields = [
                ("origin", "X-Radar-Mobile-Origin"),
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

    @Test(
        "Reveal retry stops before dispatch when resealing fails",
        arguments: [false, true]
    )
    func revealRetryStopsWhenResealingFails(secondary: Bool) async throws {
        Radar.initialize(publishableKey: "prj_test_pk_radar_sdk_ios")

        let responseData = try JSONSerialization.data(
            withJSONObject: Self.revealRiskResponse
        )
        let session = RetryTestSession(
            failures: [.networkConnectionLost],
            responseData: responseData
        )

        var sealCalls = 0
        let preparedInstance = MockPreparedFraudPayloadInstance(
            result: nil,
            resultForOptions: { _ in
                sealCalls += 1
                if sealCalls == 1 {
                    return ["payload": MockFraudEnvelope.payload]
                }
                return ["error": "Resealing failed"]
            }
        )
        let instance = MockCollectingFraudInstance(
            result: ["preparedPayload": preparedInstance]
        )
        let fraudSDK = try #require(RadarSDKFraud(instance: instance))
        let manager = RadarRevealRiskManager(
            apiClient: RadarAPIClient(
                apiHelper: RadarAPIHelper(session: session)
            ),
            fraudSDK: fraudSDK
        )

        await #expect {
            try await manager.revealRisk(
                useSecondaryVerifiedHost: secondary
            )
        } throws: { error in
            (error as? RadarError)?.status == .errorUnknown
        }

        #expect(instance.recordedOptions().count == 1)
        #expect(preparedInstance.capturedOptions.count == 2)

        let requests = await session.recordedRequests()
        #expect(requests.count == 1)

        let request = try #require(requests.first)
        try assertFirstAttemptRequest(request, secondary: secondary)
    }

    private func assertFirstAttemptRequest(_ request: URLRequest, secondary: Bool) throws {
        let host =
            secondary
            ? RadarSettings.defaultVerifiedHostSecondary
            : RadarSettings.verifiedHost
        #expect(request.url?.absoluteString == "\(host)/v1/reveal/risk")

        let bodyData = try #require(request.httpBody)
        let body = try #require(
            try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        )
        #expect(bodyData == Data(MockFraudEnvelope.payload.utf8))
        #expect(Set(body.keys) == MockFraudEnvelope.fieldNames)
    }
}
