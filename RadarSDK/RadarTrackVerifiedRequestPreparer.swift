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

    @objc(getEncryptedPayloadWithInstallId:origin:product:sdkVersion:authorization:completionHandler:)
    func getEncryptedPayload(
        installId: String,
        origin: String?,
        product: String?,
        sdkVersion: String?,
        authorization: String?
        // Preserve status, payload, and error in the Objective-C completion.
        // swiftlint:disable:next large_tuple
    ) async -> (RadarStatus, String?, NSError?) {
        guard let fraudSDK else {
            return (.errorPlugin, nil, nil)
        }

        let preparer = RadarFraudPayloadPreparer(
            fraudSDK: fraudSDK,
            options: options
        )

        do {
            let payload = try await preparer.getEncryptedPayload(
                installId: installId,
                canonicalRoute: "/v1/track",
                origin: origin,
                product: product,
                sdkVersion: sdkVersion,
                authorization: authorization
            )
            return (.success, payload, nil)
        } catch {
            let status = (error as? RadarError)?.status ?? .errorUnknown
            return (status, nil, error as NSError)
        }
    }
}
