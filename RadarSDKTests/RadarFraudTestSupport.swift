import Foundation
import Testing

@testable import RadarSDK

/// A stand-in for the `RadarSDKFraud` submodule's shared instance.
///
/// `RadarSDKFraud` (the Swift wrapper) reaches into its wrapped `NSObject` via
/// `perform(...)`, so a mock only needs to be an `NSObject` that responds to the
/// `initializeWithOptions:` and `getFraudPayloadWithOptions:completionHandler:` selectors. It
/// replays a canned result dictionary so tests control what payload the manager forwards to the API.
final class MockFraudInstance: NSObject, @unchecked Sendable {
    let result: [String: Any]?

    init(result: [String: Any]?) {
        self.result = result
    }

    @objc(initializeWithOptions:)
    func initialize(options: [String: Any]) {}

    @objc(getFraudPayloadWithOptions:completionHandler:)
    func getFraudPayload(options: [String: Any], completionHandler: @escaping ([String: Any]?) -> Void) {
        completionHandler(result)
    }

    @objc(getEncryptedFraudPayloadWithOptions:completionHandler:)
    func getEncryptedFraudPayload(
        options: [String: Any],
        completionHandler: @escaping ([String: Any]?) -> Void
    ) {
        completionHandler(result)
    }
}

final class MockLegacyFraudInstance: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var sharing = true
    private var plaintextCalls = 0
    let missingSelectors: Set<String>

    init(missingSelectors: Set<String> = []) {
        self.missingSelectors = missingSelectors
    }

    override func responds(to selector: Selector!) -> Bool {
        !missingSelectors.contains(NSStringFromSelector(selector)) && super.responds(to: selector)
    }

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

final class MockEncryptedFraudInstance: NSObject, @unchecked Sendable {
    private let optionsLock = NSLock()
    private var capturedOptions: [[String: Any]] = []

    let result: [String: Any]?

    init(result: [String: Any]?) {
        self.result = result
    }

    @objc(initializeWithOptions:)
    func initialize(options: [String: Any]) {}

    @objc(getFraudPayloadWithOptions:completionHandler:)
    func getFraudPayload(
        options: [String: Any],
        completionHandler: @escaping ([String: Any]?) -> Void
    ) {
        completionHandler(nil)
    }

    @objc(getEncryptedFraudPayloadWithOptions:completionHandler:)
    func getEncryptedFraudPayload(
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
}
