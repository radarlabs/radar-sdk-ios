//
//  RadarLocationTracing.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Location instrumentation: `radar.location.*` attributes and the `radar.location.get` span.
extension RadarTraceSpan {
    /// Traces getting a location as a `radar.location.get` child of this span. The child starts now and ends with
    /// the result's status before `handler` runs.
    @objc(tracingLocationHandler:)
    func tracingLocationHandler(
        _ handler: @escaping (RadarStatus, CLLocation?, Bool) -> Void
    ) -> (RadarStatus, CLLocation?, Bool) -> Void {
        guard isRecording else { return handler }
        let span = child("radar.location.get")
        return { status, location, stopped in
            if let location {
                span.recordLocationQuality(location)
            }
            span.end(status: status)
            handler(status, location, stopped)
        }
    }

    /// The location's age and accuracy. A small age means a cached or fresh fix.
    @objc(recordLocationQuality:)
    func recordLocationQuality(_ location: CLLocation) {
        recording { span in
            let ageMs = max(0, -location.timestamp.timeIntervalSinceNow * 1000)
            span.setInteger(Int64(ageMs), forKey: "radar.location.age_ms")
            span.setDouble(location.horizontalAccuracy, forKey: "radar.location.accuracy_m")
        }
    }
}
