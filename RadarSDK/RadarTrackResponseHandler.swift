//
//  RadarTrackResponseHandler.swift
//  RadarSDK
//
//  Created by Alan Charles on 11/12/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarTrackResponseHandler)
final class RadarTrackResponseHandler: NSObject {
    /// Returns false when the existing Track response path should continue.
    @objc(handleResponse:verified:requestedVerificationLevel:completionHandler:)
    static func handleResponse(
        _ response: [AnyHashable: Any],
        verified: Bool,
        requestedVerificationLevel: RadarVerificationLevel,
        completionHandler: (
            RadarStatus,
            [AnyHashable: Any]?,
            RadarVerifiedLocationToken?
        ) -> Void
    ) -> Bool {
        handleResponse(
            response,
            verified: verified,
            isTrackingVerified: { Radar.isTrackingVerified() },
            stopTrackingVerified: { Radar.stopTrackingVerified() },
            completionHandler: completionHandler
        )
    }

    static func handleResponse(
        _ response: [AnyHashable: Any],
        verified: Bool,
        isTrackingVerified: () -> Bool,
        stopTrackingVerified: () -> Void,
        completionHandler: (
            RadarStatus,
            [AnyHashable: Any]?,
            RadarVerifiedLocationToken?
        ) -> Void
    ) -> Bool {
        guard verified else {
            return false
        }

        guard
            let format = RadarResponseFormat(
                responseValue: response["format"]
            )
        else {
            completionHandler(.errorServer, nil, nil)
            return true
        }

        if format == .id && isTrackingVerified() {
            stopTrackingVerified()
            RadarLogger.shared.error(
                "ID responses do not support startTrackingVerified().",
                type: .sdkError
            )
            completionHandler(.errorBadRequest, nil, nil)
            return true
        }

        guard format != .jws else {
            return false
        }

        guard
            let token = RadarVerifiedLocationToken(
                object: response,
                requestedVerificationLevel: requestedVerificationLevel
            )
        else {
            completionHandler(.errorServer, nil, nil)
            return true
        }

        completionHandler(.success, token.dictionaryValue(), token)
        return true
    }
}
