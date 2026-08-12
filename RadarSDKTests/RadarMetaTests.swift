//
//  RadarMetaTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

@Suite("RadarMetaTests")
struct RadarMetaTests {

    @Test("nil dict returns non-nil RadarMeta with nil properties")
    func nilDict() {
        let meta = RadarMeta.from(dictionary: nil)

        #expect(meta != nil)
        #expect(meta?.trackingOptions == nil)
        #expect(meta?.sdkConfiguration == nil)
    }

    @Test("dict missing both keys returns non-nil RadarMeta with nil properties")
    func dictMissingBothKeys() {
        let meta = RadarMeta.from(dictionary: [:])

        #expect(meta != nil)
        #expect(meta?.trackingOptions == nil)
        #expect(meta?.sdkConfiguration == nil)
    }

    @Test("valid trackingOptions sub-dict is parsed")
    func validTrackingOptions() {
        let meta = RadarMeta.from(dictionary: ["trackingOptions": ["beacons": true]])

        #expect(meta?.trackingOptions?.beacons == true)
    }

    @Test("trackingOptions value of wrong type leaves property nil")
    func trackingOptionsWrongType() {
        let meta = RadarMeta.from(dictionary: ["trackingOptions": "not a dictionary"])

        #expect(meta?.trackingOptions == nil)
    }

    @Test("valid sdkConfiguration sub-dict is parsed")
    func validSdkConfiguration() {
        let meta = RadarMeta.from(dictionary: ["sdkConfiguration": ["logLevel": "info"]])

        #expect(meta?.sdkConfiguration?.logLevel == .info)
    }

    @Test("sdkConfiguration value of wrong type leaves property nil")
    func sdkConfigurationWrongType() {
        let meta = RadarMeta.from(dictionary: ["sdkConfiguration": 42])

        #expect(meta?.sdkConfiguration == nil)
    }
}
