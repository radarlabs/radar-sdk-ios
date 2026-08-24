//
//  RadarLifecycleMarker.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarLifecycleMarker) final class RadarLifecycleMarker: NSObject {
    private static let markerKey = "radar-appLifecycleMarker"
    // The server uses this prefix to turn uploaded logs into app_killed issues.
    @objc(appTerminatingMessage) static let appTerminatingMessage = "App terminating"

    @objc(sharedMarker) nonisolated(unsafe) static let shared = RadarLifecycleMarker()

    private let userDefaults: UserDefaults
    private let lock = NSLock()

    init(userDefaults: UserDefaults = RadarUserDefaults.sharedUserDefaults) {
        self.userDefaults = userDefaults
    }

    @objc func beginProcess() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let previousValue = userDefaults.bool(forKey: Self.markerKey)
        userDefaults.set(true, forKey: Self.markerKey)
        userDefaults.synchronize()
        return previousValue
    }

    @objc func markBackground() {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.set(true, forKey: Self.markerKey)
        userDefaults.synchronize()
    }

    @objc func markCleanTermination() {
        lock.lock()
        defer { lock.unlock() }

        userDefaults.removeObject(forKey: Self.markerKey)
        userDefaults.synchronize()
    }
}
