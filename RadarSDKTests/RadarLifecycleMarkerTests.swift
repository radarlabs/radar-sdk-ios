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

    @Test("The app terminating message matches the server contract")
    func appTerminatingMessageMatchesServerContract() {
        #expect(RadarLifecycleMarker.appTerminatingMessage == "App terminating")
    }
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

    @Test("Repeated initialization in one process is idempotent")
    func repeatedBeginProcessIsIdempotent() {
        let userDefaults = makeUserDefaults()
        let marker = RadarLifecycleMarker(userDefaults: userDefaults)

        #expect(marker.beginProcess() == false)
        #expect(marker.beginProcess() == false)
        #expect(userDefaults.bool(forKey: "radar-appLifecycleMarker") == true)
    }
}
