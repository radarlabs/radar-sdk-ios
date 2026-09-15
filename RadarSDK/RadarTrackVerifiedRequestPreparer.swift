//
//  RadarTrackVerifiedRequestPreparer.swift
//  RadarSDK
//
//  Created by Alan Charles on 9/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarTrackVerifiedRequestPreparer)
final class RadarTrackVerifiedRequestPreparer: NSObject, @unchecked Sendable {
    private let fraudSDK: RadarSDKFraud?
    private let options: [String: Any]

    init(fraudSDK: RadarSDKFraud?, options: [String: Any]) {
        self.fraudSDK = fraudSDK
        self.options = options
        super.init()
    }

    @objc(initWithOptions:)
    convenience init(options: [String: Any]) {
        self.init(
            fraudSDK: RadarSDKFraud.shared,
            options: options
        )
    }

    @objc(prepareBody:headers:completionHandler:)
    func prepareBody(
        _ body: [String: Any],
        headers: [String: String]
    // Preserve the Objective-C completion's status, body, and error parameters.
    // swiftlint:disable:next large_tuple
    ) async -> (RadarStatus, [String: Any]?, NSError?) {
        guard let fraudSDK else {
            return (.errorPlugin, nil, nil)
        }

        let preparer = RadarFraudPayloadPreparer(
            fraudSDK: fraudSDK,
            options: options
        )

        do {
            let encryptedBody = try await preparer.prepareBody(
                body,
                method: "POST",
                canonicalRoute: "/v1/track",
                headers: headers
            )
            return (.success, encryptedBody, nil)
        } catch {
            let status = (error as? RadarError)?.status ?? .errorUnknown
            return (status, nil, error as NSError)
        }
    }
}
