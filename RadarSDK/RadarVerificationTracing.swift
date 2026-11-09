//
//  RadarVerificationTracing.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

// Verification instrumentation: `radar.verified.*` attributes, the trackVerified() completion handler wrapper, and the
// `radar.fraud.prepare` span.
extension RadarTraceSpan {
    /// Whether trackVerified() retried its config request on the secondary verified host.
    @objc(setVerifiedFailover:)
    func setVerifiedFailover(_ failover: Bool) {
        setBool(failover, forKey: "radar.verified.failover")
    }

    /// Ends this span with the result's status, then calls `handler`. Returns `handler` unchanged when this span
    /// doesn't record, so a nil handler stays nil and untraced calls behave as before.
    @objc(endingTrackVerifiedHandler:)
    func endingTrackVerifiedHandler(
        _ handler: ((RadarStatus, RadarVerifiedLocationToken?) -> Void)?
    ) -> ((RadarStatus, RadarVerifiedLocationToken?) -> Void)? {
        guard isRecording else { return handler }
        return { status, token in
            self.end(status: status)
            handler?(status, token)
        }
    }

    /// Traces the fraud SDK's payload preparation as a `radar.fraud.prepare` child of this span. The span covers the
    /// whole call as seen from the SDK, including attestation when it runs. It ends with the status trackVerified()
    /// reports: a success without a payload, or with an error, is `ERROR_UNKNOWN`.
    @objc(tracingFraudPrepareHandler:)
    func tracingFraudPrepareHandler(
        _ handler: @escaping (RadarStatus, RadarPreparedFraudPayload?, NSError?) -> Void
    ) -> (RadarStatus, RadarPreparedFraudPayload?, NSError?) -> Void {
        guard isRecording else { return handler }
        let span = child("radar.fraud.prepare")
        return { status, payload, error in
            let incomplete = payload == nil || error != nil
            span.end(status: status == .success && incomplete ? .errorUnknown : status)
            handler(status, payload, error)
        }
    }
}
