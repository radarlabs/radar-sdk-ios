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
    /// Attributes of a `radar.track_once` root. The app state is only readable on the main thread, so it's omitted
    /// when this is called from another thread.
    @objc(recordTrackWithDesiredAccuracy:beacons:)
    func recordTrack(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy, beacons: Bool) {
        recording { span in
            span.recordTrackAttributes(
                desiredAccuracy: desiredAccuracy, beacons: beacons, foreground: RadarUtils.foregroundIfOnMainThread)
        }
    }

    /// Attributes of a `radar.track_verified` root, with the app state the caller already read on the main thread.
    @objc(recordTrackWithDesiredAccuracy:beacons:foreground:)
    func recordTrack(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy, beacons: Bool, foreground: Bool) {
        recordTrackAttributes(desiredAccuracy: desiredAccuracy, beacons: beacons, foreground: foreground)
    }

    private func recordTrackAttributes(desiredAccuracy: RadarTrackingOptionsDesiredAccuracy, beacons: Bool, foreground: Bool?) {
        recording { span in
            span.setString(RadarTrackingOptions.string(for: desiredAccuracy), forKey: "radar.location.desired_accuracy")
            span.setBool(beacons, forKey: "radar.beacons")
            span.recordAppContext(foreground: foreground)
        }
    }

    /// App state that changes how long a track takes, for a root that doesn't call `recordTrack`. The app state is only
    /// readable on the main thread, so it's omitted when this is called from another thread.
    @objc func recordAppContext() {
        recording { span in
            span.recordAppContext(foreground: RadarUtils.foregroundIfOnMainThread)
        }
    }

    /// Whether the app is in the foreground (omitted when nil), and whether location access is precise.
    func recordAppContext(foreground: Bool?) {
        recording { span in
            if let foreground {
                span.setBool(foreground, forKey: "radar.app.foreground")
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
