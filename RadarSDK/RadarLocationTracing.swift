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
    /// Root attributes that change how long getting a location takes. `radar.location.get` copies them, so its
    /// latency can be grouped by them without joining it to its root.
    private static let locationGetRootContext: Set<String> = [
        "radar.location.desired_accuracy",
        "radar.app.foreground",
        "radar.location.accuracy_authorization",
    ]

    /// Traces getting a location as a `radar.location.get` child of this span, with this span's desired accuracy and
    /// app state. The child starts now and ends with the result's status before `handler` runs.
    @objc(tracingLocationHandler:)
    func tracingLocationHandler(
        _ handler: @escaping (RadarStatus, CLLocation?, Bool) -> Void
    ) -> (RadarStatus, CLLocation?, Bool) -> Void {
        guard isRecording else { return handler }
        let span = child("radar.location.get")
        span.copyAttributes(from: self, keys: Self.locationGetRootContext)
        return { status, location, stopped in
            if let location {
                span.recordLocationQuality(location)
            }
            span.end(status: status)
            handler(status, location, stopped)
        }
    }

    /// The location's age and accuracy. Age measures staleness, not source: a large age means an old cached fix, and a
    /// small age can be a new fix or one Core Location cached moments ago.
    @objc(recordLocationQuality:)
    func recordLocationQuality(_ location: CLLocation) {
        recording { span in
            let ageMs = max(0, -location.timestamp.timeIntervalSinceNow * 1000)
            span.setInteger(Int64(ageMs), forKey: "radar.location.age_ms")
            span.setDouble(location.horizontalAccuracy, forKey: "radar.location.accuracy_m")
        }
    }
}
