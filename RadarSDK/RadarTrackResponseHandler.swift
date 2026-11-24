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
    /// Handles a verified JWE or ID response, and a bad or unsupported format. Returns false for a
    /// non-verified response or a JWS response, which the caller handles because it can change SDK state.
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
            requestedVerificationLevel: requestedVerificationLevel,
            isTrackingVerified: { Radar.isTrackingVerified() },
            stopTrackingVerified: { Radar.stopTrackingVerified() },
            completionHandler: completionHandler
        )
    }

    static func handleResponse(
        _ response: [AnyHashable: Any],
        verified: Bool,
        requestedVerificationLevel: RadarVerificationLevel = .precise,
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

        switch format {
        case .jws:
            return false
        case .jwe:
            return handleTokenOnlyResponse(
                response,
                requestedVerificationLevel: requestedVerificationLevel,
                completionHandler: completionHandler
            )
        case .id:
            if isTrackingVerified() {
                stopTrackingVerified()
                RadarLogger.shared.error(
                    "ID responses do not support startTrackingVerified().",
                    type: .sdkError
                )
                completionHandler(.errorBadRequest, nil, nil)
                return true
            }
            return handleTokenOnlyResponse(
                response,
                requestedVerificationLevel: requestedVerificationLevel,
                completionHandler: completionHandler
            )
        }
    }

    /// JWE and ID responses have only a token: no user, events, or state to process.
    private static func handleTokenOnlyResponse(
        _ response: [AnyHashable: Any],
        requestedVerificationLevel: RadarVerificationLevel,
        completionHandler: (
            RadarStatus,
            [AnyHashable: Any]?,
            RadarVerifiedLocationToken?
        ) -> Void
    ) -> Bool {
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
