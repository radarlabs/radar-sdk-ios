//
//  RadarLifecycleMarker.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarLifecycleMarker)
final class RadarLifecycleMarker: NSObject, @unchecked Sendable {
    private static let markerKey = "radar-appLifecycleMarker"

    // The server uses this prefix to turn uploaded logs into app_killed issues. Be very careful changing it.
    @objc(appTerminatingMessage)
    static let appTerminatingMessage = "App terminating"

    @objc(sharedMarker)
    static let shared = RadarLifecycleMarker()

    private let userDefaults: UserDefaults
    private let lock = NSLock()

    init(userDefaults: UserDefaults = RadarUserDefaults.sharedUserDefaults) {
        self.userDefaults = userDefaults
        super.init()
    }

    @objc func beginProcess() -> Bool {
        withSynchronizedDefaults { defaults in
            let previousValue = defaults.bool(forKey: Self.markerKey)
            defaults.set(true, forKey: Self.markerKey)
            return previousValue
        }
    }

    @objc func markCleanTermination() {
        withSynchronizedDefaults { defaults in
            defaults.removeObject(forKey: Self.markerKey)
        }
    }

    private func withSynchronizedDefaults<T>(
        _ operation: (UserDefaults) -> T
    ) -> T {
        lock.lock()
        defer { lock.unlock() }
        defer { userDefaults.synchronize() }

        return operation(userDefaults)
    }
}
