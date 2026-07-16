//
//  RadarRevealRiskManager.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Bridges the Objective-C `Radar` interface to the pure-Swift `RadarAPIClient`.
///
/// `RadarAPIClient` is a pure-Swift, `async` type that Objective-C cannot call directly.
/// This manager wraps the async reveal risk request in a completion-handler API that can be
/// invoked from Objective-C, hopping back to the main thread to deliver the result.
@objc(RadarRevealRiskManager)
final class RadarRevealRiskManager: NSObject, Sendable {

    @objc
    static let shared = RadarRevealRiskManager(
        apiClient: RadarAPIClient.shared,
        fraudSDK: RadarSDKFraud.shared,
    )

    let apiClient: RadarAPIClient
    let fraudSDK: RadarSDKFraud?

    init(apiClient: RadarAPIClient, fraudSDK: RadarSDKFraud?) {
        self.apiClient = apiClient
        self.fraudSDK = fraudSDK
    }

    func revealRisk(useSecondaryVerifiedHost: Bool) async throws -> RadarRevealRiskToken {
        guard let fraudSDK else {
            throw RadarError(status: .errorPlugin)
        }

        let (status, payload) = await fraudSDK.getFraudPayload(sdkConfiguration: RadarSettings.sdkConfiguration)
        guard let payload, status == .success else {
            throw RadarError(status: status)
        }

        let revealRisk = try await apiClient.revealRisk(
            fraudPayload: payload,
            useSecondaryVerifiedHost: useSecondaryVerifiedHost
        )
        return revealRisk
    }

    @objc
    func revealRisk(
        useSecondaryVerifiedHost: Bool,
        completionHandler: @escaping @Sendable (RadarStatus, RadarRevealRiskToken?) -> Void
    ) {
        Task {
            do {
                let token = try await self.revealRisk(useSecondaryVerifiedHost: useSecondaryVerifiedHost)
                RadarLogger.shared.debug("RadarRevealRiskManager: revealRisk() succeeded \(RadarUtils.dictionaryToJson(token.dictionaryValue))")
                completionHandler(.success, token)
            } catch {
                if let radarError = error as? RadarError {
                    RadarLogger.shared.error("RadarRevealRiskManager: revealRisk() failed \(Radar.stringForStatus(radarError.status))")
                    completionHandler(radarError.status, nil)
                } else if let apiError = error as? RadarAPIClient.APIError {
                    RadarLogger.shared.error("RadarRevealRiskManager: revealRisk() failed due to API error: \(apiError.message)")
                    completionHandler(.errorServer, nil)
                } else {
                    RadarLogger.shared.error("RadarRevealRiskManager: revealRisk() failed unknown error")
                    completionHandler(.errorServer, nil)
                }
            }
        }
    }
}
