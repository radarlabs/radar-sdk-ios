//
//  RadarLifecycleMarkerTests.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

struct RadarLifecycleMarkerTests {
    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "RadarLifecycleMarkerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    @Test("A fresh process records its lifecycle marker")
    func freshProcessRecordsMarker() {
        let userDefaults = makeUserDefaults()
        let marker = RadarLifecycleMarker(userDefaults: userDefaults)

        #expect(marker.beginProcess() == false)
        #expect(userDefaults.bool(forKey: "radar-appLifecycleMarker") == true)
    }

    @Test("A subsequent process finds the lifecycle marker")
    func subsequentProcessFindsMarker() {
        let userDefaults = makeUserDefaults()
        let firstMarker = RadarLifecycleMarker(userDefaults: userDefaults)
        let secondMarker = RadarLifecycleMarker(userDefaults: userDefaults)

        #expect(firstMarker.beginProcess() == false)
        #expect(secondMarker.beginProcess() == true)
    }

    @Test("Backgrounding restores the lifecycle marker")
    func backgroundingRestoresMarker() {
        let userDefaults = makeUserDefaults()
        let marker = RadarLifecycleMarker(userDefaults: userDefaults)

        marker.markBackground()

        #expect(RadarLifecycleMarker(userDefaults: userDefaults).beginProcess() == true)
    }

    @Test("Clean termination removes the lifecycle marker")
    func cleanTerminationRemovesMarker() {
        let userDefaults = makeUserDefaults()
        let marker = RadarLifecycleMarker(userDefaults: userDefaults)

        _ = marker.beginProcess()
        marker.markCleanTermination()

        #expect(RadarLifecycleMarker(userDefaults: userDefaults).beginProcess() == false)
    }
}
