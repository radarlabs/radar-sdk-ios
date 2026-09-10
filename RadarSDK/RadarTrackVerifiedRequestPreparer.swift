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

    init(fraudSDK: RadarSDKFraud?, options: [String : Any]) {
        self.fraudSDK = fraudSDK
        self.options = options
        super.init()
    }

    @objc(initWithOptions:)
    convenience init(options: [String : Any]) {
        self.init(
            fraudSDK: RadarSDKFraud.shared,
            options: options
        )
    }

    @objc(prepareRequest:completionHandler:)
    func prepareRequest(
        _ request: URLRequest,
        completionHandler: @escaping @Sendable (
            RadarStatus,
            URLRequest?,
            NSError?
        ) -> Void
    ) {
        guard let fraudSDK else {
            completionHandler(.errorPlugin, nil, nil)
            return
        }

        Task {
            do {
                let preparedRequest = try await fraudSDK.prepareEncryptedRequest(
                    request,
                    canonicalRoute: "/v1/track",
                    options: self.options
                )

                completionHandler(.success, preparedRequest, nil)
            } catch {
                let status = (error as? RadarError)?.status ?? .errorUnknown
                completionHandler(status, nil, error as NSError)
            }
        }
    }
    
    
}
