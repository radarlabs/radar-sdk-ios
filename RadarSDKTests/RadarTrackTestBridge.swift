//
//  RadarTrackTestBridge.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation

@testable import RadarSDK

/// Hands the caller's completion handler to the API client, which calls it once.
private final class TrackCompletion: @unchecked Sendable {
    let invoke: RadarTrackAPICompletionHandler
    init(_ invoke: @escaping RadarTrackAPICompletionHandler) { self.invoke = invoke }
}

/// Sends a track request straight to `RadarAPIClient`, skipping location and fraud collection.
enum RadarTrackTestBridge {
    static func track(
        withPreparedPayload payload: NSObject?,
        verified: Bool,
        secondary: Bool,
        completion: @escaping RadarTrackAPICompletionHandler
    ) {
        let callback = TrackCompletion(completion)
        RadarAPIClient.sharedInstance().track(
            with: CLLocation(latitude: 40.0, longitude: -73.0),
            stopped: false,
            foreground: true,
            source: .foregroundLocation,
            replayed: false,
            beacons: nil,
            indoorLocation: nil,
            verified: verified,
            preparedFraudPayload: payload as? RadarPreparedFraudPayloadWrapper,
            expectedCountryCode: nil,
            expectedStateCode: nil,
            expectedAddress: nil,
            reason: nil,
            transactionId: nil,
            revealRiskId: nil,
            useSecondaryVerifiedHost: secondary,
            completionHandler: { callback.invoke($0, $1, $2, $3, $4, $5, $6) }
        )
    }
}
