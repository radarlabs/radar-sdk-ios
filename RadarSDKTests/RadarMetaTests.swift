//
//  RadarMetaTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing

@testable import RadarSDK

@Suite("RadarMeta")
struct RadarMetaTests {

    @Test("nil dictionary yields an empty meta")
    func nilDictionary() {
        let meta = RadarMeta.fromDictionary(nil)

        #expect(meta.trackingOptions == nil)
        #expect(meta.sdkConfiguration == nil)
    }

    @Test("empty dictionary yields an empty meta")
    func emptyDictionary() {
        let dict: [AnyHashable: Any] = [:]
        let meta = RadarMeta.fromDictionary(dict)

        #expect(meta.trackingOptions == nil)
        #expect(meta.sdkConfiguration == nil)
    }

    @Test("parses trackingOptions")
    func parsesTrackingOptions() {
        let trackingOptions: [AnyHashable: Any] = [
            "desiredStoppedUpdateInterval": 123,
            "stopDuration": 45,
            "beacons": true,
        ]
        let dict: [AnyHashable: Any] = ["trackingOptions": trackingOptions]

        let meta = RadarMeta.fromDictionary(dict)

        #expect(meta.trackingOptions?.desiredStoppedUpdateInterval == 123)
        #expect(meta.trackingOptions?.stopDuration == 45)
        #expect(meta.trackingOptions?.beacons == true)
        #expect(meta.sdkConfiguration == nil)
    }

    @Test("parses sdkConfiguration")
    func parsesSdkConfiguration() {
        let sdkConfiguration: [AnyHashable: Any] = [
            "usePersistence": true,
            "defaultGeofenceDwellThreshold": 30,
        ]
        let dict: [AnyHashable: Any] = ["sdkConfiguration": sdkConfiguration]

        let meta = RadarMeta.fromDictionary(dict)

        #expect(meta.sdkConfiguration?.usePersistence == true)
        #expect(meta.sdkConfiguration?.defaultGeofenceDwellThreshold == 30)
        #expect(meta.trackingOptions == nil)
    }

    @Test("parses both keys together")
    func parsesBothKeys() {
        let dict: [AnyHashable: Any] = [
            "trackingOptions": ["desiredMovingUpdateInterval": 60],
            "sdkConfiguration": ["useSyncRegion": true],
        ]

        let meta = RadarMeta.fromDictionary(dict)

        #expect(meta.trackingOptions?.desiredMovingUpdateInterval == 60)
        #expect(meta.sdkConfiguration?.useSyncRegion == true)
    }

    @Test("ignores values of the wrong type")
    func ignoresWrongTypes() {
        let dict: [AnyHashable: Any] = [
            "trackingOptions": "not a dictionary",
            "sdkConfiguration": 7,
        ]

        let meta = RadarMeta.fromDictionary(dict)

        #expect(meta.trackingOptions == nil)
        #expect(meta.sdkConfiguration == nil)
    }
}
