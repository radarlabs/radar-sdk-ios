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

    @objc(preparePayloadWithCompletionHandler:)
    // swiftlint:disable:next large_tuple
    func preparePayload() async -> (RadarStatus, RadarPreparedFraudPayload?, NSError?) {
        guard let fraudSDK else { return (.errorPlugin, nil, nil) }
        do {
            return (.success, try await fraudSDK.prepareFraudPayload(options: options), nil)
        } catch {
            return ((error as? RadarError)?.status ?? .errorUnknown, nil, error as NSError)
        }
    }
}
