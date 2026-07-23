//
//  RadarLocationManagerSwiftHeadingTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftHeadingTests {

        // MARK: - didUpdateHeading

        @Test("didUpdateHeading stores every CLHeading field under the heading key")
        func didUpdateHeadingStoresAllFields() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                RadarUserDefaults.set(nil, forKey: .lastHeadingData)
            }

            let stub = StubCLHeading(
                magneticHeading: 12.5,
                trueHeading: 34.5,
                headingAccuracy: 5,
                x: 0.1,
                y: 0.2,
                z: 0.3,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000)
            )

            RadarLocationManagerSwift.didUpdateHeading(stub)

            let stored = RadarState().lastHeadingData
            #expect(stored?["magneticHeading"] == 12.5)
            #expect(stored?["trueHeading"] == 34.5)
            #expect(stored?["headingAccuracy"] == 5)
            #expect(stored?["x"] == 0.1)
            #expect(stored?["y"] == 0.2)
            #expect(stored?["z"] == 0.3)
            #expect(stored?["timestamp"] == 1_700_000_000)
        }

        @Test("didUpdateHeading overwrites previously stored heading data")
        func didUpdateHeadingOverwritesPrevious() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer {
                RadarLocationManagerSwiftTestHelpers.clearState()
                RadarUserDefaults.set(nil, forKey: .lastHeadingData)
            }

            RadarLocationManagerSwift.didUpdateHeading(
                StubCLHeading(
                    magneticHeading: 1,
                    trueHeading: 1,
                    headingAccuracy: 1,
                    x: 1,
                    y: 1,
                    z: 1,
                    timestamp: Date(timeIntervalSince1970: 1)
                )
            )
            RadarLocationManagerSwift.didUpdateHeading(
                StubCLHeading(
                    magneticHeading: 99,
                    trueHeading: 88,
                    headingAccuracy: 7,
                    x: 0.5,
                    y: 0.6,
                    z: 0.7,
                    timestamp: Date(timeIntervalSince1970: 2)
                )
            )

            let stored = RadarState().lastHeadingData
            #expect(stored?["magneticHeading"] == 99)
            #expect(stored?["trueHeading"] == 88)
            #expect(stored?["headingAccuracy"] == 7)
            #expect(stored?["timestamp"] == 2)
        }
    }
}
