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
final class RadarRevealRiskManager: NSObject, @unchecked Sendable {

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

    private let sharingLock = NSLock()
    private var _revealRiskId: String?

    @objc
    var revealRiskId: String? {
        get {
            sharingLock.lock()
            defer { sharingLock.unlock() }
            return _revealRiskId
        }
        set {
            sharingLock.lock()
            _revealRiskId = newValue
            sharingLock.unlock()
        }
    }

    func revealRisk(
        useSecondaryVerifiedHost: Bool
    ) async throws -> RadarRevealRiskToken {
        guard let fraudSDK else {
            throw RadarError(status: .errorPlugin)
        }
        guard let authorization = RadarSettings.publishableKey else {
            throw RadarError(status: .errorPublishableKey)
        }

        let installId = RadarSettings.installId
        let preparer = RadarFraudPayloadPreparer(
            fraudSDK: fraudSDK,
            options: RadarSettings.sdkConfiguration?.dictionaryValue() ?? [:]
        )

        let payload = try await preparer.getEncryptedPayload(
            installId: installId,
            canonicalRoute: "/v1/reveal/risk",
            // Server AAD uses HTTP Origin, not X-Radar-Mobile-Origin.
            origin: nil,
            product: RadarSettings.product,
            sdkVersion: RadarUtils.sdkVersion,
            authorization: authorization
        )

        return try await apiClient.revealRisk(
            fraudPayload: payload,
            installId: installId,
            useSecondaryVerifiedHost: useSecondaryVerifiedHost
        )
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

                revealRiskId = token.id
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
