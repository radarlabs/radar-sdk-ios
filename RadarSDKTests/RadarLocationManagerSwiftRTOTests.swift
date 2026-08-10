//
//  RadarLocationManagerSwiftRTOTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//
//  Covers `applyRemoteTrackingOptions` — the Swift twin of the remote-tracking-options
//  half of `RadarLocationManager.updateTrackingFromMeta:`. "RTO" matches the repo's
//  existing shorthand (`useOfflineRTOUpdates`, `RadarRemoteTrackingOptions`) and keeps
//  the type name inside SwiftLint's 40-character limit.
//

import Foundation
import Testing

@testable import RadarSDK

extension RadarSerializedTests {
    @Suite(.serialized)
    actor RadarLocationManagerSwiftRTOTests {

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
