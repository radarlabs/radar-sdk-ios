//
//  Radar+BeaconRanging.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

extension Radar {

    /// Starts continuously ranging nearby beacons while the app is in the foreground, so
    /// `trackVerified(beacons: true)` can attach nearby beacons without waiting on a new ranging
    /// window.
    ///
    /// Call this after `initialize` and after location permissions are granted, ideally when the
    /// user enters a flow that calls `trackVerified(beacons: true)`, and call
    /// `stopRangingBeacons()` when beacons are no longer needed. Ranging pauses automatically when
    /// the app enters the background and resumes when it returns to the foreground. Requires
    /// foreground location permissions and Bluetooth. Until ranging results are available,
    /// `trackVerified(beacons: true)` ranges beacons as usual.
    ///
    /// - SeeAlso: https://radar.com/documentation/beacons
    @objc public static func startRangingBeacons() {
        RadarLogger.shared.info("startRangingBeacons()", type: .sdkCall)
        Task { @MainActor in
            RadarBeaconRangingCache.shared.start()
        }
    }

    /// Stops ranging beacons started with `startRangingBeacons()`.
    ///
    /// - SeeAlso: https://radar.com/documentation/beacons
    @objc public static func stopRangingBeacons() {
        RadarLogger.shared.info("stopRangingBeacons()", type: .sdkCall)
        Task { @MainActor in
            RadarBeaconRangingCache.shared.stop()
        }
    }
}
