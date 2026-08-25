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
    private var didBeginProcess = false

    init(userDefaults: UserDefaults = RadarUserDefaults.sharedUserDefaults) {
        self.userDefaults = userDefaults
        super.init()
    }

    // iOS may kill a background app without a callback, so this marker stays set.
    @objc func beginProcess() -> Bool {
        withSynchronizedDefaults { defaults in
            guard !didBeginProcess else { return false }

            let previousValue = defaults.bool(forKey: Self.markerKey)
            defaults.set(true, forKey: Self.markerKey)
            didBeginProcess = true
            return previousValue
        }
    }

    @objc func logUncleanPreviousProcessIfNeeded() {
        // App extensions share the app group's defaults but run in separate processes.
        // Only the main app owns this marker; otherwise an extension launch looks like a killed app.
        guard Bundle.main.object(forInfoDictionaryKey: "NSExtension") == nil else {
            return
        }

        let uncleanPreviousProcess = beginProcess()
        guard uncleanPreviousProcess, RadarSettings.tripOptions != nil else {
            return
        }

        RadarLogger.shared.debug(
            Self.appTerminatingMessage,
            includeDate: true,
            append: true
        )
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
