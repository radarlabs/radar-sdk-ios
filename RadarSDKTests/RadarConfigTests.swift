//
//  RadarConfigTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarConfigTests")
struct RadarConfigTests {

    @Test("nil dict returns non-nil RadarConfig with nil properties")
    func nilDict() {
        let config = RadarConfig.from(dictionary: nil)

        #expect(config != nil)
        #expect(config?.meta == nil)
        #expect(config?.nonce == nil)
    }

    @Test("dict missing both keys returns non-nil RadarConfig with nil properties")
    func dictMissingBothKeys() {
        let config = RadarConfig.from(dictionary: [:])

        #expect(config != nil)
        #expect(config?.meta == nil)
        #expect(config?.nonce == nil)
    }

    @Test("valid meta sub-dict is parsed")
    func validMeta() {
        let config = RadarConfig.from(dictionary: ["meta": ["trackingOptions": ["beacons": true]]])

        #expect(config?.meta != nil)
        #expect(config?.meta?.trackingOptions?.beacons == true)
    }

    @Test("meta value of wrong type leaves property nil")
    func metaWrongType() {
        let config = RadarConfig.from(dictionary: ["meta": "not a dictionary"])

        #expect(config?.meta == nil)
    }

    @Test("valid nonce is parsed")
    func validNonce() {
        let config = RadarConfig.from(dictionary: ["nonce": "test-nonce"])

        #expect(config?.nonce == "test-nonce")
    }

    @Test("nonce value of wrong type leaves property nil")
    func nonceWrongType() {
        let config = RadarConfig.from(dictionary: ["nonce": 42])

        #expect(config?.nonce == nil)
    }

    @Test("both keys are parsed together")
    func metaAndNonce() {
        let config = RadarConfig.from(
            dictionary: [
                "meta": ["sdkConfiguration": ["logLevel": "info"]],
                "nonce": "test-nonce",
            ])

        #expect(config?.meta?.sdkConfiguration?.logLevel == .info)
        #expect(config?.nonce == "test-nonce")
    }
}
