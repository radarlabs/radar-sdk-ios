//
//  MockFraudSDK.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// A stand-in for the `RadarSDKFraud` submodule's shared instance.
///
/// `RadarSDKFraud` (the Swift wrapper) reaches into its wrapped `NSObject` via
/// `perform(...)`, so a mock only needs to be an `NSObject` that responds to the
/// `initializeWithOptions:`
/// `getFraudPayloadWithOptions:completionHandler:`
/// `isSharing`
/// `clearSharing`
/// It replays a canned result dictionary so tests control what payload the manager forwards to the API.
final class MockFraudSDK: NSObject, @unchecked Sendable {
    let result: [String: Any]?
    let sharing: Bool

    init(result: [String: Any]?, sharing: Bool) {
        self.result = result
        self.sharing = sharing
    }

    @objc(initializeWithOptions:)
    func initialize(options: [String: Any]) {}

    @objc(getFraudPayloadWithOptions:completionHandler:)
    func getFraudPayload(options: [String: Any], completionHandler: @escaping ([String: Any]?) -> Void) {
        completionHandler(result)
    }

    @objc(isSharing)
    func isSharing() -> Bool {
        return false
    }

    @objc(clearSharing)
    func clearSharing() {}
}
