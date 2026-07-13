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
@objc(RadarRevealRiskManager) @objcMembers
final class RadarRevealRiskManager: NSObject, Sendable {
    
    public static let shared = RadarRevealRiskManager(apiClient: RadarAPIClient.shared)
    
    let apiClient: RadarAPIClient
    
    init(apiClient: RadarAPIClient) {
        self.apiClient = apiClient
    }

    @objc
    func revealRisk(
        fraudPayload: String,
        useSecondaryVerifiedHost: Bool
    ) async -> RadarRevealRiskToken? {
        do {
            let revealRisk = try await apiClient.revealRisk(
                fraudPayload: fraudPayload,
                useSecondaryVerifiedHost: useSecondaryVerifiedHost
            )
            return revealRisk
        } catch {
            return nil
        }
    }
}
