//
//  RadarLocationManagerSwiftRTOTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftRTOTests {

        // MARK: - updateTrackingFromMeta

        @Test("updateTrackingFromMeta stores remote options and updates initialization tracking")
        func updateTrackingFromMetaStoresOptionsAndUpdatesInitializationTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            let options = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)
            let meta = RadarMeta.from(dictionary: ["trackingOptions": options.dictionaryValue()])

            RadarLocationManagerSwift.updateTrackingFromMeta(meta)

            #expect(RadarSettings.remoteTrackingOptions == options)
            #expect(bridge.updateTrackingFromInitializeCallCount == 1)
            #expect(bridge.callOrder == ["updateTrackingFromInitialize"])
        }

        @Test("updateTrackingFromMeta clears remote options when metadata has none")
        func updateTrackingFromMetaClearsOptionsAndUpdatesInitializationTracking() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            RadarSettings.remoteTrackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            RadarLocationManagerSwift.updateTrackingFromMeta(RadarMeta.from(dictionary: [:]))

            #expect(RadarSettings.remoteTrackingOptions == nil)
            #expect(bridge.updateTrackingFromInitializeCallCount == 1)
            #expect(bridge.callOrder == ["updateTrackingFromInitialize"])
        }

        @Test("updateTrackingFromMeta leaves remote options unchanged for nil metadata")
        func updateTrackingFromMetaLeavesOptionsUnchangedForNilMetadata() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            let bridge = MockRadarSwiftBridge()
            let originalBridge = RadarSwift.bridge
            RadarSwift.bridge = bridge
            defer {
                RadarSwift.bridge = originalBridge
                RadarLocationManagerSwiftTestHelpers.clearState()
            }

            let options = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)
            RadarSettings.remoteTrackingOptions = options

            RadarLocationManagerSwift.updateTrackingFromMeta(nil)

            #expect(RadarSettings.remoteTrackingOptions == options)
            #expect(bridge.updateTrackingFromInitializeCallCount == 1)
            #expect(bridge.callOrder == ["updateTrackingFromInitialize"])
        }

        // MARK: - applyRemoteTrackingOptions

        @Test("Stores the remote tracking options carried by a meta with trackingOptions set")
        func storesGivenOptions() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let options = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)
            let meta = RadarMeta.from(dictionary: ["trackingOptions": options.dictionaryValue()])

            RadarLocationManagerSwift.applyRemoteTrackingOptions(meta)

            #expect(RadarSettings.remoteTrackingOptions == options)
        }

        @Test("Clears previously stored remote tracking options when meta has none")
        func clearsStoredOptionsWhenMetaHasNone() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarSettings.remoteTrackingOptions = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)

            RadarLocationManagerSwift.applyRemoteTrackingOptions(RadarMeta.from(dictionary: [:]))

            #expect(RadarSettings.remoteTrackingOptions == nil)
        }

        @Test("Given nil with nothing stored, leaves remote tracking options unset")
        func nilWithNothingStoredIsANoOp() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            RadarLocationManagerSwift.applyRemoteTrackingOptions(nil)

            #expect(RadarSettings.remoteTrackingOptions == nil)
        }

        @Test("Given nil with something stored, leaves the stored options untouched")
        func nilWithSomethingStoredIsANoOp() {
            RadarLocationManagerSwiftTestHelpers.clearState()
            defer { RadarLocationManagerSwiftTestHelpers.clearState() }

            let options = RadarLocationManagerSwiftTestHelpers.trackingOptions(beacons: true)
            RadarSettings.remoteTrackingOptions = options

            RadarLocationManagerSwift.applyRemoteTrackingOptions(nil)

            #expect(RadarSettings.remoteTrackingOptions == options)
        }
    }
}
