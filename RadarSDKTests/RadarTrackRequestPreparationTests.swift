import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarTrackRequestPreparationTests {
        @Test("Core accepts the current Fraud compatibility version")
        func initializationAcceptsMatchingCompatibilityVersion() {
            let instance = MockCollectingFraudInstance(result: nil)

            #expect(RadarSDKFraud(instance: instance) != nil)
            #expect(instance.recordedOptions().isEmpty)
        }

        @Test("Core warns and accepts an encryption-capable Fraud SDK without a compatibility marker")
        @MainActor
        func initializationAcceptsMissingCompatibilityMarker() async throws {
            let logger = RadarLogger.shared
            let originalDelegate = logger.delegate
            let originalLogLevel = logger.logLevelOverride
            defer {
                logger.setDelegate(originalDelegate)
                logger.logLevelOverride = originalLogLevel
            }
            let delegate = MockRadarDelegate()
            logger.setDelegate(delegate)
            logger.logLevelOverride = .warning
            let instance = MockCollectingFraudInstance(
                result: nil,
                missingSelectors: ["coreCompatibilityVersion"]
            )

            let fraudSDK = try #require(RadarSDKFraud(instance: instance))
            fraudSDK.initialize(options: [:])
            #expect(!fraudSDK.isSharing())
            fraudSDK.clearSharing()
            #expect(instance.recordedOptions().isEmpty)
            await logger.awaitPendingLogs()
            #expect(
                delegate.messages.contains {
                    $0.contains("Installed Radar Fraud SDK does not report compatibility with this Radar SDK.")
                })
        }

        @Test("Core rejects unsupported or malformed Fraud compatibility versions")
        func initializationRejectsInvalidCompatibilityVersions() {
            let versions: [NSObject?] = [
                nil,
                NSNumber(value: -1),
                NSNumber(value: 0),
                NSNumber(value: 2),
                NSNumber(value: 1.5),
                NSString(string: "1"),
            ]

            for version in versions {
                let instance = MockCollectingFraudInstance(
                    result: nil,
                    compatibilityVersion: version
                )

                #expect(RadarSDKFraud(instance: instance) == nil)
                #expect(instance.recordedOptions().isEmpty)
            }
        }

        @Test(
            "Tracking payload collection preserves success and failure statuses",
            arguments: [
                "success",
                "missing-module",
                "legacy-module",
                "missing-compatibility",
                "missing-compatibility-payload-error",
                "older-compatibility",
                "newer-compatibility",
                "payload-error",
                "empty-payload",
                "missing-result",
                "empty-result",
                "numeric-payload",
                "null-payload",
                "payload-and-error",
            ]
        )
        @MainActor
        func trackingPayloadBridge(scenario: String) async throws {
            let logger = RadarLogger.shared
            let originalDelegate = logger.delegate
            let originalLogLevel = logger.logLevelOverride
            defer {
                logger.setDelegate(originalDelegate)
                logger.logLevelOverride = originalLogLevel
            }
            let delegate = MockRadarDelegate()
            logger.setDelegate(delegate)
            logger.logLevelOverride = .error

            let (fraudSDK, expectedStatus) = try makeFraudSDK(scenario: scenario)
            let preparer = RadarTrackVerifiedRequestPreparer(
                fraudSDK: fraudSDK,
                options: [:]
            )

            #expect(
                preparer.responds(
                    to: NSSelectorFromString(
                        "preparePayloadWithCompletionHandler:"
                    )
                )
            )

            let (status, payload, error) = await preparer.preparePayload()

            #expect(status == expectedStatus)
            await logger.awaitPendingLogs()
            let pluginMessages = delegate.messages.filter {
                $0.contains("A compatible Radar Fraud SDK is required for verified requests.")
            }
            #expect(pluginMessages.count == (expectedStatus == .errorPlugin ? 1 : 0))

            if expectedStatus == .success {
                #expect(error == nil)
                #expect(payload != nil)
            } else {
                #expect(payload == nil)
                if expectedStatus == .errorPlugin {
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
            case "missing-compatibility", "missing-compatibility-payload-error":
                let result = fraudResult(scenario: scenario == "missing-compatibility" ? "success" : "payload-error")
                fraudSDK = RadarSDKFraud(
                    instance: MockCollectingFraudInstance(
                        result: result,
                        missingSelectors: ["coreCompatibilityVersion"]
                    )
                )
                #expect(fraudSDK != nil)
                expectedStatus = scenario == "missing-compatibility" ? .success : .errorBadRequest
            case "older-compatibility", "newer-compatibility":
                let instance = MockCollectingFraudInstance(
                    result: nil,
                    compatibilityVersion: NSNumber(value: scenario == "older-compatibility" ? 0 : 2)
                )
                fraudSDK = RadarSDKFraud(instance: instance)
                #expect(fraudSDK == nil)
                #expect(instance.recordedOptions().isEmpty)
                expectedStatus = .errorPlugin
            default:
                let result = fraudResult(scenario: scenario)
                let candidate: RadarSDKFraud? = RadarSDKFraud(
                    instance: MockCollectingFraudInstance(result: result)
                )
                let validatedSDK: RadarSDKFraud = try #require(candidate)
                fraudSDK = validatedSDK
                expectedStatus = scenario == "success" ? .success : .errorBadRequest
            }

            return (fraudSDK, expectedStatus)
        }

        private func fraudResult(scenario: String) -> [String: Any]? {
            switch scenario {
            case "success":
                return ["preparedPayload": MockPreparedFraudPayloadInstance(result: ["payload": "encrypted-envelope"])]
            case "payload-error": return ["error": "collection failed"]
            case "empty-payload": return ["preparedPayload": ""]
            case "missing-result": return nil
            case "empty-result": return [:]
            case "numeric-payload": return ["preparedPayload": 123]
            case "null-payload": return ["preparedPayload": NSNull()]
            case "payload-and-error":
                return ["error": "collection failed", "preparedPayload": "must-not-send"]
            default:
                Issue.record("Unknown preparation scenario: \(scenario)")
                return nil
            }
        }
    }
}
