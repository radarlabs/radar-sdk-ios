import Foundation
import Testing

@testable import RadarSDK

final class MockLegacyFraudInstance: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var sharing = true
    private var plaintextCalls = 0

    @objc(isSharing)
    func isSharing() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return sharing
    }

    @objc(clearSharing)
    func clearSharing() {
        lock.lock()
        defer { lock.unlock() }
        sharing = false
    }

    func recordedPlaintextCalls() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return plaintextCalls
    }

    @objc(initializeWithOptions:)
    func initialize(options: [String: Any]) {}

    @objc(getFraudPayloadWithOptions:completionHandler:)
    func getFraudPayload(
        options: [String: Any],
        completionHandler: @escaping ([String: Any]?) -> Void
    ) {
        lock.lock()
        plaintextCalls += 1
        lock.unlock()
        completionHandler(nil)
    }
}

final class MockCollectingFraudInstance: NSObject, @unchecked Sendable {
    private let optionsLock = NSLock()
    private var capturedOptions: [[String: Any]] = []

    let result: [String: Any]?
    private let missingSelectors: Set<String>

    init(
        result: [String: Any]?,
        missingSelectors: Set<String> = []
    ) {
        self.result = result
        self.missingSelectors = missingSelectors
    }

    override func responds(to selector: Selector!) -> Bool {
        !missingSelectors.contains(NSStringFromSelector(selector))
            && super.responds(to: selector)
    }

    @objc(initializeWithOptions:)
    func initialize(options: [String: Any]) {}

    @objc(prepareFraudPayloadWithOptions:completionHandler:)
    func prepareFraudPayload(
        options: [String: Any],
        completionHandler: @escaping ([String: Any]?) -> Void
    ) {
        optionsLock.lock()
        capturedOptions.append(options)
        optionsLock.unlock()

        completionHandler(result)
    }

    func recordedOptions() -> [[String: Any]] {
        optionsLock.lock()
        defer { optionsLock.unlock() }
        return capturedOptions
    }

    @objc(isSharing)
    func isSharing() -> Bool {
        return false
    }

    @objc(clearSharing)
    func clearSharing() {}
}

final class MockPreparedFraudPayloadInstance: NSObject {
    let result: [String: Any]?
    private let resultForOptions: (([String: Any]) -> [String: Any]?)?

    private(set) var capturedOptions: [[String: Any]] = []

    init(
        result: [String: Any]?,
        resultForOptions: (([String: Any]) -> [String: Any]?)? = nil
        ) {
        self.result = result
        self.resultForOptions = resultForOptions
        super.init()
    }

    @objc(sealWithOptions:)
    func seal(options: [String: Any]) -> [String: Any]? {
        capturedOptions.append(options)
        if let resultForOptions {
            return resultForOptions(options)
        }
        return result
    }
}
