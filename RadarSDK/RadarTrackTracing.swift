//
//  RadarTrackTracing.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

// Track instrumentation: `radar.track.*` and other attributes of trackOnce() and trackVerified() root spans, and the
// completion handler wrapper that ends them.
extension RadarTraceSpan {
    /// Attributes of a `radar.track_once` or `radar.track_verified` root. `foreground` is nil when the caller can't
    /// read the app state, which is only available on the main thread. The attribute is then omitted.
    @objc(recordTrackWithDesiredAccuracy:beacons:foreground:)
    func recordTrack(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy, beacons: Bool, foreground: NSNumber?) {
        recording { span in
            span.setString(RadarTrackingOptions.string(for: desiredAccuracy), forKey: "radar.location.desired_accuracy")
            span.setBool(beacons, forKey: "radar.beacons")
            span.recordAppContext(foreground: foreground)
        }
    }

    /// App state that changes how long a track takes: whether the app is in the foreground (omitted when
    /// `foreground` is nil), and whether location access is precise.
    @objc(recordAppContextWithForeground:)
    func recordAppContext(foreground: NSNumber?) {
        recording { span in
            if let foreground {
                span.setBool(foreground.boolValue, forKey: "radar.app.foreground")
            }
            span.setString(RadarUtils.locationAccuracyAuthorization, forKey: "radar.location.accuracy_authorization")
        }
    }

    /// Set on the root when its track is sent as a replay flush instead.
    @objc func markReplayed() {
        setBool(true, forKey: "radar.track.replayed")
    }

    /// Ends this span with the track's status, then calls `handler`. Returns `handler` unchanged when this span
    /// doesn't record, so a nil handler stays nil and untraced calls behave as before.
    @objc(endingTrackHandler:)
    func endingTrackHandler(
        _ handler: ((RadarStatus, CLLocation?, [RadarEvent]?, RadarUser?) -> Void)?
    ) -> ((RadarStatus, CLLocation?, [RadarEvent]?, RadarUser?) -> Void)? {
        guard isRecording else { return handler }
        return { status, location, events, user in
            self.end(status: status)
            handler?(status, location, events, user)
        }
    }
}
