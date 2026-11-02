//
//  RadarBeaconTracing.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// Beacon instrumentation: `radar.beacon*` attributes and the `radar.beacon.range` span.
extension RadarTraceSpan {
    /// Where a root's beacons came from: `continuous` (continuous ranging supplied them) or `search` (a nearby beacon
    /// search, then one-shot ranging).
    @objc(setBeaconSource:)
    func setBeaconSource(_ source: String) {
        setString(source, forKey: "radar.beacon.source")
    }

    /// Traces one-shot ranging as a `radar.beacon.range` child of this span. `mode` is `uuids` (ranging by UUID) or
    /// `beacons` (ranging specific beacons). The child starts now and ends with the result's status before `handler`
    /// runs.
    @objc(tracingBeaconHandler:mode:)
    func tracingBeaconHandler(
        _ handler: @escaping (RadarStatus, [RadarBeacon]?) -> Void,
        mode: String
    ) -> (RadarStatus, [RadarBeacon]?) -> Void {
        guard isRecording else { return handler }
        let span = child("radar.beacon.range")
        span.setString(mode, forKey: "radar.beacon.mode")
        return { status, beacons in
            if let beacons {
                span.setInteger(Int64(beacons.count), forKey: "radar.beacon.ranged_count")
            }
            span.end(status: status)
            handler(status, beacons)
        }
    }
}
